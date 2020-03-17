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
  const response = await fetch("archive.json");
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
    f: issue => issue.state === "CLOSED",
  },

  open: {
    args: [],
    h: 'is open',
    f: issue => issue.state === "OPEN",
  },

  merged: {
    args: [],
    h: 'a merged pull request',
    f: issue => issue.state == "MERGED",
  },

  discarded: {
    args: [],
    h: 'a discarded pull request',
    f: issue => issue.pr && issue.state === "CLOSED"
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
  md: x => `* [#${x.number}](${x.html_url}): ${x.title}`,
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
    if (e.key === "Enter") {
      r(true);
    } else {
      debounces[f.name] = window.setTimeout(_ => {
        delete debounces[f.name];
        r(false)
      }, 10 + debounceSlowdown);
    }
  }
}

function makeRow(issue) {
  function cellID() {
    let td = document.createElement('td');
    td.className = 'id';
    let a = document.createElement('a');
    a.href = issue.url;
    a.innerText = issue.number;
    td.appendChild(a);
    return td;
  }

  function cellTitle() {
    let td = document.createElement('td');
    let div = document.createElement('div');
    div.innerText = issue.title;
    div.onclick = e => e.target.parentNode.classList.toggle('active');
    div.style.cursor = 'pointer';
    td.appendChild(div);
    div = document.createElement('div');
    div.innerText = issue.body;
    div.className = 'extra';
    td.appendChild(div);
    return td;
  }

  function addUser(td, user, short) {
    let image = document.createElement('img');
    image.src = `https://github.com/${user}.png?size=16`;
    image.width = 16;
    image.height = 16;
    td.appendChild(image);
    let a = document.createElement('a');
    a.href = `https://github.com/${user}`;
    a.innerText = user;
    if (short) {
      a.classList.add('short');
    }
    td.appendChild(a);
  }

  function cellUser() {
    let td = document.createElement('td');
    td.className = 'user';
    addUser(td, issue.author);
    return td;
  }

  function cellAssignees() {
    let td = document.createElement('td');
    td.className = 'user';
    if (issue.assignees) {
      issue.assignees.forEach(user => addUser(td, user, issue.assignees.length > 1));
    }
    return td;
  }

  function cellState() {
    let td = document.createElement('td');
    if (issue.pr) {
      if (issue.state === "MERGED") {
        td.innerText = 'merged';
      } else if (issue.state === "CLOSED") {
        td.innerText = 'discarded';
      } else {
        td.innerText = 'pr';
      }
    } else {
      td.innerText = issue.state.toLowerCase();
    }
    return td;
  }

  function cellLabels() {
    let td = document.createElement('td');
    issue.labels.forEach(label => {
      let sp = document.createElement('span');
      sp.style.backgroundColor = '#' + db.labels[label].color;
      sp.className = "swatch";
      td.appendChild(sp);
      let spl = document.createElement('span');
      spl.innerText = label;
      if (db.labels[label].description) {
        spl.title = db.labels[label].description;
      }
      td.appendChild(spl);
    });
    return td;
  }

  let tr = document.createElement('tr');
  tr.appendChild(cellID());
  tr.appendChild(cellTitle());
  tr.appendChild(cellState());
  tr.appendChild(cellUser());
  tr.appendChild(cellAssignees());
  tr.appendChild(cellLabels());
  return tr;
}

function show(issues) {
  if (!issues) {
    return;
  }

  let tbody = document.getElementById('tbody');
  tbody.innerHTML = '';
  issues.forEach(issue => {
    tbody.appendChild(makeRow(issue));
  });
}

var currentFilter = '';
function filter(str, now) {
  try {
    filterIssues(str);
    setStatus(`${db.all.length} records selected`);
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

function slashCmd(cmd) {
  if (cmd[0] === 'help') {
    setStatus('help shown');
    document.getElementById('help').classList.remove('hidden');
  } else if (cmd[0] === 'local') {
    setStatus('retrieving local JSON files');
    get().then(redraw);
  } else if (cmd[0]  === 'sort') {
    sort(cmd[1]);
    show(subset);
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
      document.getElementById('display').classList.add('hidden');
    }
    return;
  }

  if (!db) {
    if (now) {
      showStatus('Still loading...');
    }
    return;
  }

  document.getElementById('help').classList.add('hidden');
  document.getElementById('display').classList.remove('hidden');
  filter(cmd.value, now);
  show(subset);
}

function generateHelp() {
  let functionhelp = document.getElementById('functions');
  Object.keys(issueFilters).forEach(k => {
    let li = document.createElement('li');
    let arglist = '';
    if (issueFilters[k].args.length > 0) {
      arglist = '(' + issueFilters[k].args.map(x => '<' + x + '>').join(', ') + ')';
    }
    let help = '';
    if (issueFilters[k].h) {
      help = ' - ' + issueFilters[k].h;
    }
    li.innerText = `${k}${arglist}${help}`;
    functionhelp.appendChild(li);
  });
}

function addFileHelp() {
  setStatus('error loading file');
  if (window.location.protocol !== 'file:') {
    return;
  }
  let h = document.getElementById('help');
  let p = document.createElement('p');
  p.className = 'warning';
  p.innerHTML = 'Important: Browsers display files inconsistently.' +
    ' You can work around this by running an HTTP server,' +
    ' such as <code>python3 -m http.server</code>,' +
    ' then view this file using that server.';
  h.insertBefore(p, h.firstChild);
}

window.onload = () => {
  let cmd = document.getElementById('cmd');
  cmd.onkeypress = debounce(redraw);
  if (window.location.hash) {
    cmd.value = decodeURIComponent(window.location.hash.substring(1));
  }
  generateHelp();
  get().then(redraw).catch(addFileHelp);
}
