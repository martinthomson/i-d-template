function setStatus(msg) {
  let status = document.getElementById('status');
  status.innerText = msg;
}

function date(s) {
  const d = Date.parse(s);
  if (isNaN(d)) {
    return 0;
  }
  return d;
}

var sortKey = 'id';
function sort(k) {
  k = k || sortKey;
  if (k === 'id') {
    db.all.sort((x, y) => x.number - y.number);
    setStatus('sorted by ID');
  } else if (k === 'recent') {
    db.all.sort((x, y) => date(y.updatedAt) - date(x.updatedAt));
    setStatus('sorted by last modified');
  } else if (k === 'closed') {
    db.all.sort((x, y) => date(y.closedAt) - date(x.closedAt));
    setStatus('sorted by time of closure');
  } else {
    setStatus('no idea how to sort like that');
    return;
  }
  sortKey = k;
}

var db;
async function get() {
  db = null;
  const response = await fetch('archive.json');
  if (Math.floor(response.status / 100) !== 2) {
    throw new Error(`Error loading <${url}>: ${response.status}`);
  }
  db = await response.json();
  db.pulls.forEach(pr => pr.pr = true);
  db.all = db.issues.concat(db.pulls);
  db.labels = db.labels.reduce((all, l) => {
    all[l.name] = l;
    return all;
  }, {});
  sort();
  document.title = `${db.repo} Issues`;
  console.log(`Loaded ${db.all.length} issues for ${db.repo}.`);
  console.log('Raw data for issues can be found in:');
  console.log('  db.all = all issues and pull requests');
  console.log('  subset = just the subset of issues that are shown');
  console.log('format(subset[, formatter]) to dump the current subset to the console');
}

var issueFilters = {
  assigned: {
    args: [],
    h: 'has an assignee',
    f: issue => issue.assignees.length > 0,
  },

  assigned_to: {
    args: ['string'],
    h: 'assigned to a specific user',
    f: login => issue => issue.assignees.some(assignee => assignee === login),
  },

  created_by: {
    args: ['string'],
    h: 'created by a specific user',
    f: login => issue => issue.author === login,
  },

  closed: {
    args: [],
    h: 'is closed',
    f: issue => issue.state === 'CLOSED',
  },

  open: {
    args: [],
    h: 'is open',
    f: issue => issue.state === 'OPEN',
  },

  merged: {
    args: [],
    h: 'a merged pull request',
    f: issue => issue.state == 'MERGED',
  },

  discarded: {
    args: [],
    h: 'a discarded pull request',
    f: issue => issue.pr && issue.state === 'CLOSED'
  },

  n: {
    args: ['integer'],
    h: 'issue by number',
    f: i => issue => issue.number === i,
  },

  label: {
    args: ['string'],
    h: 'has a specific label',
    f: name => issue => issue.labels.some(label => label === name),
  },

  labelled: {
    args: [],
    h: 'has any label',
    f: issue => issue.labels.length > 0,
  },

  title: {
    args: ['string'],
    h: 'search title with a regular expression',
    f: function(re) {
      re = new RegExp(re);
      return issue => issue.title.match(re);
    }
  },

  body: {
    args: ['string'],
    h: 'search body with a regular expression',
    f: function(re) {
      re = new RegExp(re);
      return issue => issue.body.match(re);
    }
  },

  text: {
    args: ['string'],
    h: 'search title and body with a regular expression',
    f: function(re) {
      re = new RegExp(re);
      return issue => issue.title.match(re) || issue.body.match(re);
    }
  },

  pr: {
    args: [],
    h: 'is a pull request',
    f: issue => issue.pr,
  },

  issue: {
    args: [],
    h: 'is a plain issue, i.e., not(pr)',
    f: function(issue) {
      return !issue.pr;
    }
  },

  or: {
    args: ['filter', '...filter'],
    h: 'union',
    f: (...filters) =>  x => filters.some(filter => filter(x)),
  },

  and: {
    args: ['filter', '...filter'],
    h: 'intersection',
    f: (...filters) => x => filters.every(filter => filter(x)),
  },


  xor: {
    args: ['filter', '...filter'],
    h: 'for the insane',
    f: (...filters) =>
      x => filters.slice(1).reduce((a, filter) => a ^ filter(x), filters[0](x)),
  },

  not: {
    args: ['filter'],
    h: 'exclusion',
    f: a => issue => !a(issue),
  },

  closed_since: {
    args: ['date'],
    h: 'issues closed since the date and time',
    f: since => issue => date(issue.closedAt) >= since,
  },

  updated_since: {
    args: ['date'],
    h: 'issues updated since the date and time',
    f: since => issue => date(issue.updatedAt) >= since,
  }
};

class Parser {
  constructor(s) {
    this.str = s;
    this.skipws();
  }

  skipws() {
    this.str = this.str.trimLeft();
  }

  jump(idx) {
    this.str = this.str.slice(idx);
    this.skipws();
  }

  get next() {
    return this.str.charAt(0);
  }

  parseName() {
    let m = this.str.match(/^[a-zA-Z](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?/);
    if (!m) {
      return;
    }

    this.jump(m[0].length);
    return m[0];
  }

  parseSeparator(separator) {
    if (this.next !== separator) {
      throw new Error(`Expecting separator ${separator}`);
    }
    this.jump(1);
  }

  parseString() {
    let end = -1;
    for (let i = 0; i < this.str.length; ++i) {
      let v = this.str.charAt(i);
      if (v === ')' || v === ',') {
        end = i;
        break;
      }
    }
    if (end < 0) {
      throw new Error(`Unterminated string`);
    }
    let s = this.str.slice(0, end).trim();
    this.jump(end);
    return s;
  }

  parseDate() {
    let str = this.parseString();
    let time = Date.parse(str);
    if (isNaN(time)) {
      throw new Error(`not a valid date: ${str}`);
    }
    return time;
  }

  parseNumber() {
    let m = this.str.match(/^\d+/);
    if (!m) {
      return;
    }
    this.jump(m[0].length);
    return parseInt(m[0], 10);
  }

  parseFilter() {
    if (this.next === '-') {
      this.parseSeparator('-');
      return issueFilters.not.f.call(null, this.parseFilter());
    }
    let name = this.parseName();
    if (!name) {
      let n = this.parseNumber();
      if (!isNaN(n)) {
        return issueFilters.n.f.call(null, n);
      }
      return;
    }
    let f = issueFilters[name];
    if (!f) {
      throw new Error(`Unknown filter: ${name}`);
    }
    if (f.args.length === 0) {
      return f.f;
    }
    let args = [];
    for (let i = 0; i < f.args.length; ++i) {
      let arg = f.args[i];
      let ellipsis = arg.slice(0, 3) === '...';
      if (ellipsis) {
        arg = arg.slice(3);
      }

      this.parseSeparator((i === 0) ? '(' : ',');
      if (arg === 'string') {
        args.push(this.parseString());
      } else if (arg === 'date') {
        args.push(this.parseDate());
      } else if (arg === 'integer') {
        args.push(this.parseNumber());
      } else if (arg === 'filter') {
        args.push(this.parseFilter());
      } else {
        throw new Error(`Error in filter ${name} definition`);
      }
      if (ellipsis && this.next === ',') {
        --i;
      }
    }
    this.parseSeparator(')');
    return f.f.apply(null, args);
  }
}

var subset = [];
function filterIssues(str) {
  subset = db.all;
  let parser = new Parser(str);
  let f = parser.parseFilter();
  while (f) {
    subset = subset.filter(f);
    f = parser.parseFilter();
  }
}

var formatter = {
  brief: x => `* ${x.title} (#${x.number})`,
  md: x => `* [#${x.number}](${x.url}): ${x.title}`,
};

function format(set, f) {
  return (set || subset).map(f || formatter.brief).join('\n');
}

var debounces = {};
var debounceSlowdown = 100;
function measureSlowdown() {
  let start = Date.now();
  window.setTimeout(_ => {
    let diff = Date.now() - start;
    if (diff > debounceSlowdown) {
      console.log(`slowed to ${diff} ms`);
      debounceSlowdown = Math.min(1000, diff + debounceSlowdown / 2);
    }
  }, 0);
}
function debounce(f) {
  let r = now => {
    measureSlowdown();
    f(now);
  };
  return e => {
    if (debounces[f.name]) {
      window.clearTimeout(debounces[f.name]);
      delete debounces[f.name];
    }
    if (e.key === 'Enter') {
      r(true);
    } else {
      debounces[f.name] = window.setTimeout(_ => {
        delete debounces[f.name];
        r(false)
      }, 10 + debounceSlowdown);
    }
  }
}

function cell(row, children, cellClass) {
  let td = document.createElement('td');
  if (cellClass) {
    td.className = cellClass;
  }
  if (Array.isArray(children)) {
    children.forEach(c => {
      td.appendChild(c);
      td.appendChild(document.createTextNode(' '));
    });
  } else {
    td.appendChild(children);
  }
  row.appendChild(td);
}

function author(x) {
  let user = x.author || x;
  let sp = document.createElement('span');
  sp.classList.add('item');
  sp.classList.add('user');
  let image = document.createElement('img');
  image.alt = '\uD83E\uDDD0';
  image.src = `https://github.com/${user}.png?size=16`;
  image.width = 16;
  image.height = 16;
  sp.appendChild(image);
  let a = document.createElement('a');
  a.href = `https://github.com/${user}`;
  a.innerText = user;
  sp.appendChild(a);
  return sp;
}

function issueState(issue) {
  let st = document.createElement('span');
  st.className = 'state';
  if (issue.pr) {
    switch (issue.state) {
      case 'MERGED':
        st.innerText = 'merged';
        break;
      case 'CLOSED':
        st.innerText = 'discarded';
        break;
      default:
        st.innerText = 'pr';
        break;
    }
  } else {
    st.innerText = issue.state.toLowerCase();
  }
  return st;
}

function showBody(item) {
  let div = document.createElement('div');
  div.className = 'body';
  let body = item.body.trim().replace(/\r\n?/g, '\n');
  body.split('\n\n').forEach(t => {
    let p = document.createElement('p');
    p.innerText = t;
    div.appendChild(p)
  });
  return div;
}

function showDate(d, reference) {
  let de = document.createElement('span');
  de.classList.add('item');
  de.classList.add('date');
  const full = d.toISOString();
  const parts = full.split(/[TZ\.]/);
  if (reference && parts[0] === reference.toISOString().split('T')[0]) {
    de.innerText = parts[1];
  } else {
    de.innerText = parts[0] + ' ' + parts[1];
  }
  de.title = full;
  return de;
}

// Make a fresh replacement element for the identified element.
function freshReplacement(id) {
  let e = document.getElementById(id);
  let r = document.createElement(e.tagName);
  r.id = id;
  e.replaceWith(r);
  return r;
}

var displayed = null;

function show(index) {
  if (index < 0 || index >= subset.length) {
    hideIssue();
    return;
  }
  displayed = index;
  const issue = subset[index];

  document.getElementById('overlay').classList.add('active');
  let frame = freshReplacement('issue');
  frame.classList.add('active');

  function showTitle() {
    let title = document.createElement('h2');
    title.className = 'title';
    let number = document.createElement('a');
    number.className = 'number';
    number.href = issue.url;
    number.innerText = `#${issue.number}`;
    title.appendChild(number);
    title.appendChild(document.createTextNode(': '));
    let name = document.createElement('a');
    name.href = issue.url;
    name.innerText = issue.title;
    title.appendChild(name);
    return title;
  }

  function showMeta() {
    let meta = document.createElement('div');
    meta.className = 'meta';
    let created = new Date(issue.createdAt);
    meta.appendChild(showDate(created));
    meta.appendChild(author(issue));
    meta.appendChild(issueState(issue));
    if (issue.closedAt) {
      meta.appendChild(showDate(new Date(issue.closedAt), created));
    }
    return meta;
  }

  let refdate = null;
  function showComment(c) {
    let row = document.createElement('tr');
    let cdate = new Date(c.createdAt);
    cell(row, showDate(cdate, refdate), 'date');
    refdate = cdate;
    cell(row, author(c), 'user');

    if (issue.pr) {
      let icon = document.createElement('span');
      switch (c.state) {
        case 'APPROVED':
          icon.innerText = '\u2714';
          icon.title = 'Approved';
          break;
        case 'CHANGES_REQUESTED':
          icon.innerText = '\u2718';
          icon.title = 'Changes Requested';
          break;
        default:
          icon.innerText = '\uD83D\uDCAC';
          icon.title = 'Comment';
          break;
      }
      cell(row, icon);
    }

    let body = showBody(c);
    if (c.comments && c.comments.length > 0) {
      let codeComments = document.createElement('div');
      codeComments.className = 'item';
      const s = (c.comments.length === 1) ? '' : 's';
      codeComments.innerText = `... ${c.comments.length} comment${s} on changes`;
      body.appendChild(codeComments);
    }
    cell(row, body);
    return row;
  }

  frame.appendChild(showTitle());
  frame.appendChild(showMeta());
  frame.appendChild(showBody(issue));

  let allcomments = (issue.comments || []).concat(issue.reviews || []);
  allcomments.sort((a, b) => date(a.createdAt) - date(b.createdAt));
  let comments = document.createElement('table');
  comments.className = 'comments';
  allcomments.map(showComment).forEach(row => comments.appendChild(row));
  frame.appendChild(comments);

  frame.scroll(0, 0);
}

function hideIssue() {
  document.getElementById('help').classList.remove('active');
  document.getElementById('issue').classList.remove('active');
  document.getElementById('overlay').classList.remove('active');
  displayed = null;
}

function step(n) {
  if (displayed === null) {
    if (n > 0) {
      show(n - 1);
    } else {
      show(subset.length + n);
    }
  } else {
    show(displayed + n);
  }
}

function makeRow(issue, index) {
  function cellID() {
    let a = document.createElement('a');
    a.href = issue.url;
    a.innerText = issue.number;
    return a;
  }

  function cellTitle() {
    let a = document.createElement('a');
    a.innerText = issue.title;
    a.href = issue.url;
    a.onclick = e => {
      e.preventDefault();
      show(index);
    };
    return a;
  }

  function cellAssignees() {
    return (issue.assignees || []).map(u => author(u));
  }

  function cellLabels() {
    return issue.labels.map(label => {
      let item = document.createElement('span');
      item.className = 'item';
      let sp = document.createElement('span');
      sp.style.backgroundColor = '#' + db.labels[label].color;
      sp.className = 'swatch';
      item.appendChild(sp);
      let spl = document.createElement('span');
      spl.innerText = label;
      if (db.labels[label].description) {
        item.title = db.labels[label].description;
      }
      item.appendChild(spl);
      return item;
    });
  }

  let tr = document.createElement('tr');
  cell(tr, cellID(), 'id');
  cell(tr, cellTitle(), 'title');
  cell(tr, issueState(issue), 'state');
  cell(tr, author(issue), 'user');
  cell(tr, cellAssignees(), 'assignees');
  cell(tr, cellLabels(), 'labels');
  return tr;
}

function list(issues) {
  if (!issues) {
    return;
  }

  let body = freshReplacement('issuelist');
  body.innerHTML = '';
  issues.forEach((issue, index) => {
    body.appendChild(makeRow(issue, index));
  });
}

var currentFilter = '';
function filter(str, now) {
  try {
    filterIssues(str);
    setStatus(`${subset.length} records selected`);
    if (now) {
      window.location.hash = str;
      currentFilter = str;
    }
  } catch (e) {
    if (now) { // Only show errors when someone hits enter.
      setStatus(`Error: ${e.message}`);
      console.log(e);
    }
  }
}

function showHelp() {
  setStatus('help shown');
  let h = document.getElementById('help');
  h.classList.add('active');
  h.scroll(0, 0);
  document.getElementById('overlay').classList.add('active');
}

function slashCmd(cmd) {
  if (cmd[0] === 'help') {
    showHelp();
  } else if (cmd[0] === 'local') {
    setStatus('retrieving local JSON files');
    get().then(redraw);
  } else if (cmd[0]  === 'sort') {
    sort(cmd[1]);
    list(subset);
  } else {
    setStatus('unknown command: /' + cmd.join(' '));
  }
}

function redraw(now) {
  let cmd = document.getElementById('cmd');
  if (cmd.value.charAt(0) == '/') {
    if (now) {
      slashCmd(cmd.value.slice(1).split(' ').map(x => x.trim()));
      cmd.value = currentFilter;
    }
    return;
  }

  if (!db) {
    if (now) {
      showStatus('Still loading...');
    }
    return;
  }

  document.getElementById('help').classList.remove('active');
  filter(cmd.value, now);
  list(subset);
}

function generateHelp() {
  let functionhelp = document.getElementById('functions');
  Object.keys(issueFilters).forEach(k => {
    let li = document.createElement('li');
    let arglist = '';
    if (issueFilters[k].args.length > 0) {
      arglist = '(' + issueFilters[k].args.map(x => '<' + x + '>').join(', ') + ')';
    }
    let fn = document.createElement('tt');
    fn.innerText = k + arglist;
    li.appendChild(fn);
    let help = '';
    if (issueFilters[k].h) {
      help = ' - ' + issueFilters[k].h;
    }
    li.appendChild(document.createTextNode(help));
    functionhelp.appendChild(li);
  });
}

function addFileHelp() {
  setStatus('error loading file');
  if (window.location.protocol !== 'file:') {
    return;
  }
  let p = document.createElement('p');
  p.className = 'warning';
  p.innerHTML = 'Important: Browsers display files inconsistently.' +
    ' You can work around this by running an HTTP server,' +
    ' such as <code>python3 -m http.server</code>,' +
    ' then view this file using that server.';
  document.getElementById('help').insertBefore(p, h.firstChild);
}

function issueOverlaySetup() {
  let overlay = document.getElementById('overlay');
  overlay.addEventListener('click', hideIssue);
  window.addEventListener('keyup', e => {
    if (e.target.id === 'cmd') {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.target.blur();
      }
      return;
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      hideIssue();
    }
  });
  window.addEventListener('keypress', e=> {
    if (e.target.closest('input')) {
      return;
    }
    if (e.key === 'p' || e.key === 'k') {
      e.preventDefault();
      step(-1);
    } else if (e.key === 'n' || e.key === 'j') {
      e.preventDefault();
      step(1);
    } else if (e.key === '?') {
      e.preventDefault();
      showHelp();
    } else if (e.key === '\'') {
      e.preventDefault();
      hideIssue();
      document.getElementById('cmd').focus();
    }
  })
}

window.onload = () => {
  let cmd = document.getElementById('cmd');
  let redrawHandler = debounce(redraw);
  cmd.addEventListener('input', redrawHandler);
  cmd.addEventListener('keypress', redrawHandler);
  if (window.location.hash) {
    cmd.value = decodeURIComponent(window.location.hash.substring(1));
  }
  generateHelp();
  issueOverlaySetup();
  get().then(redraw).catch(addFileHelp);
}
