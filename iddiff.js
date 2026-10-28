// iddiff.js: the IETF iddiff tool (https://github.com/ietf-tools/iddiff,
// version 0.5.1) in JavaScript, for use in the browser.
//
// The output is the side-by-side HTML that `iddiff FILE1 FILE2` prints,
// byte for byte. To get there, the parts of CPython's difflib that iddiff
// uses (SequenceMatcher, Differ and _mdiff, as of CPython 3.13 and later)
// are ported line by line below, including the autojunk heuristic and the
// tie-breaking rules that decide which lines pair up. Strings are handled
// as arrays of code points where Python indexes by code point.
//
// The wdiff, hwdiff, chbars and abdiff modes of iddiff run external
// programs (GNU wdiff, diff) and are not ported.
//
// Exports one function, iddiff(), and has no dependencies. This file is
// generated from a TypeScript source, iddiff.ts, published next to the
// draft at https://jaime.win/ietf-draft-ard-initial-contact/iddiff.ts
// together with the script that generates this file. The license notices
// are in LICENSE.iddiff.

// ---------------------------------------------------------------------------
// Python string helpers

// Code points for which Python's str.isspace() is true (Unicode 16).
const PY_SPACE = new Set([
  0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x85, 0xa0,
  0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007,
  0x2008, 0x2009, 0x200a, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000,
]);

function isSpace(cp) {
  return PY_SPACE.has(cp);
}

// str.strip(chars) on a code point array; `chars` is null for the default.
function stripCps(cps, chars) {
  const inSet = (cp) => (chars ? chars.has(cp) : isSpace(cp));
  let start = 0;
  let end = cps.length;
  while (start < end && inSet(cps[start])) start++;
  while (end > start && inSet(cps[end - 1])) end--;
  return cps.slice(start, end);
}

function stripStr(s, chars = null) {
  return String.fromCodePoint(...stripCps(toCps(s), chars));
}

// str.rstrip() with the default whitespace set.
function rstripCps(cps) {
  let end = cps.length;
  while (end > 0 && isSpace(cps[end - 1])) end--;
  return cps.slice(0, end);
}

function toCps(s) {
  const out = [];
  for (const ch of s) out.push(ch.codePointAt(0));
  return out;
}

function fromCps(cps) {
  let out = '';
  for (let i = 0; i < cps.length; i += 4096) {
    out += String.fromCodePoint(...cps.slice(i, i + 4096));
  }
  return out;
}

function cpSet(s) {
  return new Set(toCps(s));
}

// str.format() for the templates below: one pass, so inserted text that
// happens to contain a placeholder is left alone.
function format(template, values) {
  return template.replace(/\{(\w+)\}/g, (_, key) => values[key]);
}

// html.escape(s, quote=True)
function escape(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// open(name, 'r').readlines(): universal newlines, lines keep their '\n'.
function readlines(text) {
  const parts = text.replace(/\r\n|\r/g, '\n').split('\n');
  const last = parts.pop();
  const lines = parts.map((p) => p + '\n');
  if (last !== '') lines.push(last);
  return lines;
}

// ---------------------------------------------------------------------------
// difflib.SequenceMatcher

function calculateRatio(matches, length) {
  if (length) return (2.0 * matches) / length;
  return 1.0;
}

class SequenceMatcher {
  isjunk;
  autojunk;
  a = [];
  b = [];
  b2j = new Map();
  fullbcount = null;
  matchingBlocks = null;
  opcodes = null;
  bjunk = new Set();
  bpopular = new Set();

  constructor(isjunk = null, a = [], b = [], autojunk = true) {
    this.isjunk = isjunk;
    this.autojunk = autojunk;
    this.setSeqs(a, b);
  }

  setSeqs(a, b) {
    this.setSeq1(a);
    this.setSeq2(b);
  }

  setSeq1(a) {
    if (a === this.a) return;
    this.a = a;
    this.matchingBlocks = this.opcodes = null;
  }

  setSeq2(b) {
    if (b === this.b) return;
    this.b = b;
    this.matchingBlocks = this.opcodes = null;
    this.fullbcount = null;
    this.chainB();
  }

  chainB() {
    const b = this.b;
    const b2j = new Map();
    this.b2j = b2j;
    for (let i = 0; i < b.length; i++) {
      const elt = b[i];
      const indices = b2j.get(elt);
      if (indices) indices.push(i);
      else b2j.set(elt, [i]);
    }

    const junk = new Set();
    this.bjunk = junk;
    const isjunk = this.isjunk;
    if (isjunk) {
      for (const elt of b2j.keys()) {
        if (isjunk(elt)) junk.add(elt);
      }
      for (const elt of junk) b2j.delete(elt);
    }

    const popular = new Set();
    this.bpopular = popular;
    const n = b.length;
    if (this.autojunk && n >= 200) {
      const ntest = Math.floor(n / 100) + 1;
      for (const [elt, idxs] of b2j) {
        if (idxs.length > ntest) popular.add(elt);
      }
      for (const elt of popular) b2j.delete(elt);
    }
  }

  findLongestMatch(alo, ahi, blo, bhi) {
    const a = this.a;
    const b = this.b;
    const b2j = this.b2j;
    const bjunk = this.bjunk;
    let besti = alo;
    let bestj = blo;
    let bestsize = 0;

    // j2len is a dict keyed by j in Python; here two arrays of (length,
    // row) pairs stand in for the dict of the previous row and the one being
    // built, so lookups stay O(1) without allocating per row.
    const lb = b.length;
    let prevLen = new Int32Array(lb);
    let prevRow = new Int32Array(lb).fill(-2);
    let curLen = new Int32Array(lb);
    let curRow = new Int32Array(lb).fill(-2);
    for (let i = alo; i < ahi; i++) {
      const js = b2j.get(a[i]);
      if (js) {
        for (const j of js) {
          if (j < blo) continue;
          if (j >= bhi) break;
          const k = (j > 0 && prevRow[j - 1] === i - 1 ? prevLen[j - 1] : 0) + 1;
          curLen[j] = k;
          curRow[j] = i;
          if (k > bestsize) {
            besti = i - k + 1;
            bestj = j - k + 1;
            bestsize = k;
          }
        }
      }
      [prevLen, curLen] = [curLen, prevLen];
      [prevRow, curRow] = [curRow, prevRow];
    }

    while (besti > alo && bestj > blo && !bjunk.has(b[bestj - 1]) && a[besti - 1] === b[bestj - 1]) {
      besti--;
      bestj--;
      bestsize++;
    }
    while (
      besti + bestsize < ahi &&
      bestj + bestsize < bhi &&
      !bjunk.has(b[bestj + bestsize]) &&
      a[besti + bestsize] === b[bestj + bestsize]
    ) {
      bestsize++;
    }
    while (besti > alo && bestj > blo && bjunk.has(b[bestj - 1]) && a[besti - 1] === b[bestj - 1]) {
      besti--;
      bestj--;
      bestsize++;
    }
    while (
      besti + bestsize < ahi &&
      bestj + bestsize < bhi &&
      bjunk.has(b[bestj + bestsize]) &&
      a[besti + bestsize] === b[bestj + bestsize]
    ) {
      bestsize++;
    }
    return [besti, bestj, bestsize];
  }

  getMatchingBlocks() {
    if (this.matchingBlocks !== null) return this.matchingBlocks;
    const la = this.a.length;
    const lb = this.b.length;
    const queue = [[0, la, 0, lb]];
    const matchingBlocks = [];
    while (queue.length) {
      const [alo, ahi, blo, bhi] = queue.pop();
      const x = this.findLongestMatch(alo, ahi, blo, bhi);
      const [i, j, k] = x;
      if (k) {
        matchingBlocks.push(x);
        if (alo < i && blo < j) queue.push([alo, i, blo, j]);
        if (i + k < ahi && j + k < bhi) queue.push([i + k, ahi, j + k, bhi]);
      }
    }
    matchingBlocks.sort((x, y) => x[0] - y[0] || x[1] - y[1] || x[2] - y[2]);

    let i1 = 0;
    let j1 = 0;
    let k1 = 0;
    const nonAdjacent = [];
    for (const [i2, j2, k2] of matchingBlocks) {
      if (i1 + k1 === i2 && j1 + k1 === j2) {
        k1 += k2;
      } else {
        if (k1) nonAdjacent.push([i1, j1, k1]);
        i1 = i2;
        j1 = j2;
        k1 = k2;
      }
    }
    if (k1) nonAdjacent.push([i1, j1, k1]);
    nonAdjacent.push([la, lb, 0]);
    this.matchingBlocks = nonAdjacent;
    return nonAdjacent;
  }

  getOpcodes() {
    if (this.opcodes !== null) return this.opcodes;
    let i = 0;
    let j = 0;
    const answer = [];
    this.opcodes = answer;
    for (const [ai, bj, size] of this.getMatchingBlocks()) {
      let tag = '';
      if (i < ai && j < bj) tag = 'replace';
      else if (i < ai) tag = 'delete';
      else if (j < bj) tag = 'insert';
      if (tag) answer.push([tag, i, ai, j, bj]);
      i = ai + size;
      j = bj + size;
      if (size) answer.push(['equal', ai, i, bj, j]);
    }
    return answer;
  }

  ratio() {
    let matches = 0;
    for (const triple of this.getMatchingBlocks()) matches += triple[2];
    return calculateRatio(matches, this.a.length + this.b.length);
  }

  quickRatio() {
    if (this.fullbcount === null) {
      const fullbcount = new Map();
      this.fullbcount = fullbcount;
      for (const elt of this.b) fullbcount.set(elt, (fullbcount.get(elt) ?? 0) + 1);
    }
    const fullbcount = this.fullbcount;
    const avail = new Map();
    let matches = 0;
    for (const elt of this.a) {
      let numb;
      if (avail.has(elt)) numb = avail.get(elt);
      else numb = fullbcount.get(elt) ?? 0;
      avail.set(elt, numb - 1);
      if (numb > 0) matches++;
    }
    return calculateRatio(matches, this.a.length + this.b.length);
  }

  realQuickRatio() {
    const la = this.a.length;
    const lb = this.b.length;
    return calculateRatio(Math.min(la, lb), la + lb);
  }
}

// ---------------------------------------------------------------------------
// difflib.Differ, with lines as code point arrays

const CP_SPACE = 0x20;
const CP_TAB = 0x09;
const CP_NEWLINE = 0x0a;
const CP_MINUS = 0x2d;
const CP_PLUS = 0x2b;
const CP_CARET = 0x5e;
const CP_QUESTION = 0x3f;

function isCharacterJunk(cp) {
  return cp === CP_SPACE || cp === CP_TAB;
}

function sameLine(x, y) {
  if (x === y) return true;
  if (x.length !== y.length) return false;
  for (let i = 0; i < x.length; i++) if (x[i] !== y[i]) return false;
  return true;
}

// _keep_original_ws(s, tag_s)
function keepOriginalWs(s, tags) {
  const n = Math.min(s.length, tags.length);
  const out = new Array(n);
  for (let i = 0; i < n; i++) {
    out[i] = tags[i] === CP_SPACE && isSpace(s[i]) ? s[i] : tags[i];
  }
  return out;
}

// A delta line: the two-character tag ("- ", "+ ", "  ", "? ") and the rest.

function repeat(cp, n) {
  return new Array(n).fill(cp);
}

class Differ {
  out = [];

  // Lines are compared by content, so the line-level SequenceMatcher works
  // on the original strings while intraline work uses code point arrays.
  compare(a, b) {
    const cruncher = new SequenceMatcher(null, a, b);
    const acps = a.map(toCps);
    const bcps = b.map(toCps);
    this.out = [];
    for (const [tag, alo, ahi, blo, bhi] of cruncher.getOpcodes()) {
      if (tag === 'replace') this.fancyReplace(acps, alo, ahi, bcps, blo, bhi);
      else if (tag === 'delete') this.dump(CP_MINUS, acps, alo, ahi);
      else if (tag === 'insert') this.dump(CP_PLUS, bcps, blo, bhi);
      else this.dump(CP_SPACE, acps, alo, ahi);
    }
    return this.out;
  }

  dump(tag, x, lo, hi) {
    for (let i = lo; i < hi; i++) this.out.push({ tag, text: x[i] });
  }

  plainReplace(a, alo, ahi, b, blo, bhi) {
    if (bhi - blo < ahi - alo) {
      this.dump(CP_PLUS, b, blo, bhi);
      this.dump(CP_MINUS, a, alo, ahi);
    } else {
      this.dump(CP_MINUS, a, alo, ahi);
      this.dump(CP_PLUS, b, blo, bhi);
    }
  }

  fancyReplace(a, alo, ahi, b, blo, bhi) {
    const cutoff = 0.74999;
    const cruncher = new SequenceMatcher(isCharacterJunk);
    const WINDOW = 10;
    let bestI = null;
    let bestJ = null;
    let dumpI = alo;
    let dumpJ = blo;
    for (let j = blo; j < bhi; j++) {
      cruncher.setSeq2(b[j]);
      const aequiv = alo + (j - blo);
      const start = Math.max(aequiv - WINDOW, dumpI);
      const stop = Math.min(aequiv + WINDOW + 1, ahi);
      if (start >= stop) break;
      let bestRatio = cutoff;
      for (let i = start; i < stop; i++) {
        cruncher.setSeq1(a[i]);
        if (cruncher.realQuickRatio() > bestRatio && cruncher.quickRatio() > bestRatio && cruncher.ratio() > bestRatio) {
          bestI = i;
          bestJ = j;
          bestRatio = cruncher.ratio();
        }
      }
      if (bestI === null || bestJ === null) continue;
      this.fancyHelper(a, dumpI, bestI, b, dumpJ, bestJ);
      const aelt = a[bestI];
      const belt = b[bestJ];
      if (!sameLine(aelt, belt)) {
        let atags = [];
        let btags = [];
        cruncher.setSeqs(aelt, belt);
        for (const [tag, ai1, ai2, bj1, bj2] of cruncher.getOpcodes()) {
          const la = ai2 - ai1;
          const lb = bj2 - bj1;
          if (tag === 'replace') {
            atags = atags.concat(repeat(CP_CARET, la));
            btags = btags.concat(repeat(CP_CARET, lb));
          } else if (tag === 'delete') {
            atags = atags.concat(repeat(CP_MINUS, la));
          } else if (tag === 'insert') {
            btags = btags.concat(repeat(CP_PLUS, lb));
          } else {
            atags = atags.concat(repeat(CP_SPACE, la));
            btags = btags.concat(repeat(CP_SPACE, lb));
          }
        }
        this.qformat(aelt, belt, atags, btags);
      } else {
        this.out.push({ tag: CP_SPACE, text: aelt });
      }
      dumpI = bestI + 1;
      dumpJ = bestJ + 1;
      bestI = bestJ = null;
    }
    this.fancyHelper(a, dumpI, ahi, b, dumpJ, bhi);
  }

  fancyHelper(a, alo, ahi, b, blo, bhi) {
    if (alo < ahi) {
      if (blo < bhi) this.plainReplace(a, alo, ahi, b, blo, bhi);
      else this.dump(CP_MINUS, a, alo, ahi);
    } else if (blo < bhi) {
      this.dump(CP_PLUS, b, blo, bhi);
    }
  }

  qformat(aline, bline, atags, btags) {
    atags = rstripCps(keepOriginalWs(aline, atags));
    btags = rstripCps(keepOriginalWs(bline, btags));
    this.out.push({ tag: CP_MINUS, text: aline });
    if (atags.length) this.out.push({ tag: CP_QUESTION, text: atags.concat([CP_NEWLINE]) });
    this.out.push({ tag: CP_PLUS, text: bline });
    if (btags.length) this.out.push({ tag: CP_QUESTION, text: btags.concat([CP_NEWLINE]) });
  }
}

// ---------------------------------------------------------------------------
// difflib._mdiff

// (line number, text) as _mdiff yields it; text carries the \0+ \0- \0^ \1
// marks. null stands for the None side of a one-sided change.

const CP_NUL = 0x00;
const CP_SOH = 0x01;
const CP_X = 0x58;
const BLANK_LINE = [0, [CP_NEWLINE]];

function* mdiff(fromlines, tolines, context) {
  const delta = new Differ().compare(fromlines, tolines);
  let deltaPos = 0;
  const numLines = [0, 0];

  function nextDelta() {
    if (deltaPos < delta.length) return delta[deltaPos++];
    return { tag: CP_X, text: [] };
  }

  function makeLine(lines, formatKey, side) {
    numLines[side] += 1;
    if (formatKey === null) {
      return [numLines[side], lines.shift().text];
    }
    let text;
    if (formatKey === CP_QUESTION) {
      const line = lines.shift();
      const markers = lines.shift().text;
      // Runs of +, - or ^ in the markers, as (key, begin, end) relative to
      // the text after its two-character prefix.
      const subInfo = [];
      let pos = 0;
      while (pos < markers.length) {
        const key = markers[pos];
        if (key === CP_PLUS || key === CP_MINUS || key === CP_CARET) {
          let end = pos + 1;
          while (end < markers.length && markers[end] === key) end++;
          subInfo.push([key, pos, end]);
          pos = end;
        } else {
          pos++;
        }
      }
      text = line.text.slice();
      for (let n = subInfo.length - 1; n >= 0; n--) {
        const [key, begin, end] = subInfo[n];
        text = text.slice(0, begin).concat([CP_NUL, key], text.slice(begin, end), [CP_SOH], text.slice(end));
      }
    } else {
      text = lines.shift().text;
      if (!text.length) text = [CP_SPACE];
      text = [CP_NUL, formatKey].concat(text, [CP_SOH]);
    }
    return [numLines[side], text];
  }

  function* lineIterator() {
    const lines = [];
    let numBlanksPending = 0;
    let numBlanksToYield = 0;
    for (;;) {
      while (lines.length < 4) lines.push(nextDelta());
      const s = String.fromCharCode(lines[0].tag, lines[1].tag, lines[2].tag, lines[3].tag);
      let fromLine = null;
      let toLine = null;
      if (s.startsWith('X')) {
        numBlanksToYield = numBlanksPending;
      } else if (s.startsWith('-?+?')) {
        yield [makeLine(lines, CP_QUESTION, 0), makeLine(lines, CP_QUESTION, 1), true];
        continue;
      } else if (s.startsWith('--++')) {
        numBlanksPending -= 1;
        yield [makeLine(lines, CP_MINUS, 0), null, true];
        continue;
      } else if (s.startsWith('--?+') || s.startsWith('--+') || s.startsWith('- ')) {
        fromLine = makeLine(lines, CP_MINUS, 0);
        toLine = null;
        numBlanksToYield = numBlanksPending - 1;
        numBlanksPending = 0;
      } else if (s.startsWith('-+?')) {
        yield [makeLine(lines, null, 0), makeLine(lines, CP_QUESTION, 1), true];
        continue;
      } else if (s.startsWith('-?+')) {
        yield [makeLine(lines, CP_QUESTION, 0), makeLine(lines, null, 1), true];
        continue;
      } else if (s.startsWith('-')) {
        numBlanksPending -= 1;
        yield [makeLine(lines, CP_MINUS, 0), null, true];
        continue;
      } else if (s.startsWith('+--')) {
        numBlanksPending += 1;
        yield [null, makeLine(lines, CP_PLUS, 1), true];
        continue;
      } else if (s.startsWith('+ ') || s.startsWith('+-')) {
        fromLine = null;
        toLine = makeLine(lines, CP_PLUS, 1);
        numBlanksToYield = numBlanksPending + 1;
        numBlanksPending = 0;
      } else if (s.startsWith('+')) {
        numBlanksPending += 1;
        yield [null, makeLine(lines, CP_PLUS, 1), true];
        continue;
      } else if (s.startsWith(' ')) {
        const text = lines[0].text;
        numLines[0] += 1;
        const from = [numLines[0], text];
        yield [from, makeLine(lines, null, 1), false];
        continue;
      }
      while (numBlanksToYield < 0) {
        numBlanksToYield += 1;
        yield [null, BLANK_LINE, true];
      }
      while (numBlanksToYield > 0) {
        numBlanksToYield -= 1;
        yield [BLANK_LINE, null, true];
      }
      if (s.startsWith('X')) return;
      yield [fromLine, toLine, true];
    }
  }

  function* linePairIterator() {
    const it = lineIterator();
    const fromlines = [];
    const tolines = [];
    for (;;) {
      while (fromlines.length === 0 || tolines.length === 0) {
        const r = it.next();
        if (r.done) return;
        const [fromLine, toLine, foundDiff] = r.value;
        if (fromLine !== null) fromlines.push([fromLine, foundDiff]);
        if (toLine !== null) tolines.push([toLine, foundDiff]);
      }
      const [fromLine, fromDiff] = fromlines.shift();
      const [toLine, toDiff] = tolines.shift();
      yield [fromLine, toLine, fromDiff || toDiff];
    }
  }

  const pairs = linePairIterator();
  if (context === null) {
    yield* pairs;
    return;
  }

  context += 1;
  let linesToWrite = 0;
  for (;;) {
    let index = 0;
    const contextLines = new Array(context).fill(null);
    let foundDiff = false;
    while (foundDiff === false) {
      const r = pairs.next();
      if (r.done) return;
      foundDiff = r.value[2];
      contextLines[index % context] = r.value;
      index += 1;
    }
    if (index > context) {
      yield [null, null, null];
      linesToWrite = context;
    } else {
      linesToWrite = index;
      index = 0;
    }
    while (linesToWrite) {
      yield contextLines[index % context];
      index += 1;
      linesToWrite -= 1;
    }
    linesToWrite = context - 1;
    while (linesToWrite) {
      const r = pairs.next();
      if (r.done) return;
      if (r.value[2]) linesToWrite = context - 1;
      else linesToWrite -= 1;
      yield r.value;
    }
  }
}

// ---------------------------------------------------------------------------
// iddiff

// Page headers and footers to drop. Python's `$` also matches before a
// final newline; `(?=\n?$)` does the same here, and [^\n] stands for `.`.
const SKIPS = [
  /^[^\n]*\[?[Pp]age [0-9ivx]+\]?[ \t\f]*(?=\n?$)/,
  /^ *Internet[^\n]Draft[^\n]+[12][0-9][0-9][0-9] *(?=\n?$)/,
  /^ *INTERNET[^\n]DRAFT[^\n]+[12][0-9][0-9][0-9] *(?=\n?$)/,
  /^ *Draft[^\n]+(  +)[12][0-9][0-9][0-9] *(?=\n?$)/,
  /^RFC[ -]?[0-9]+[^\n]*(  +)[^\n]* [12][0-9][0-9][0-9](?=\n?$)/,
  /^draft-[-a-z0-9_.]+[^\n]*[0-9][0-9][0-9][0-9](?=\n?$)/,
];

const TABLE = `
    <table>
      <tbody>
        <tr>
          <td>&nbsp;</td>
          <th class="header" scope="col">{filename1}</th>
          <td>&nbsp;</td>
          <th class="header" scope="col">{filename2}</th>
        </tr>{rows}
      </tbody>
    </table>`;

const HTML = `
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>{title}</title>
    <style>
      body {font-family: monospace}
      table {
        border-spacing: 0;
      }
      td {
        padding: 0;
        white-space: pre;
        vertical-align: top;
        font-size: 0.86em;
      }
      th {
        padding: 0;
        text-align: center;
      }
      .left { background-color: #EEE; }
      .right { background-color: #FFF; }
      .lblock { background-color: #BFB; }
      .rblock { background-color: #FF8; }
      .delete { background-color: #ACF; }
      .insert { background-color: #8FF; }
      .change { background-color: gray; }
      .header { background-color: orange; }
      .w-delete {
        color: #F00;
        text-decoration: line-through;
      }
      .w-insert {
        color: #008000;
        font-weight: bold;
      }
    </style>
  </head>
  <body>{output}</body>
</html>`;

const UNCHANGED_ROW = `
      <tr>
        <td>&nbsp;</td>
        <td class="left">{lline}</td>
        <td>&nbsp;</td>
        <td class="right">{rline}</td>
      </tr>`;

const CHANGED_ROW = `
      <tr>
        <td>&nbsp;</td>
        <td class="lblock">{lline}</td>
        <td>&nbsp;</td>
        <td class="rblock">{rline}</td>
      </tr>`;

const CONTEXT_LINE = `
      <tr>
        <td>&nbsp;</td>
        <td class="left">&nbsp;</td>
        <td>&nbsp;</td>
        <td class="right">&nbsp;</td>
      </tr>
      <tr id="context-{context}">
        <td></td>
        <th class="change" scope="col">
          <a href="#context-{context}">
           <small>Skipping</small>
          </a>
        </th>
        <td></td>
        <th class="change" scope="col">
          <a href="#context-{context}">
           <small>Skipping</small>
          </a>
        </th>
      </tr>`;

// iddiff's WHITESPACE: string.whitespace plus the listed code points.
const WHITESPACE = cpSet(
  ' \t\n\r\u000b\u000c' +
    '\u0009\u000a\u000b\u000c\u000d\u0020\u0085\u00a0\u1680' +
    '\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a' +
    '\u2028\u2029\u202f\u205f\u3000\u180e\u200b\u200c\u200d\u2060\ufeff',
);
const MARKS = cpSet('\0+-^\u0001');

function getFilename(filename) {
  // Path(filename).name
  const trimmed = filename.replace(/\/+$/, '');
  return escape(trimmed.slice(trimmed.lastIndexOf('/') + 1));
}

function cleanup(lines, skipWhitespace) {
  const idLines = [];
  if (skipWhitespace) {
    let previousBlank = false;
    for (const line of lines) {
      if (stripStr(line, WHITESPACE).length > 0) {
        previousBlank = false;
        let keep = true;
        for (const skip of SKIPS) {
          if (skip.test(line)) {
            keep = false;
            break;
          }
        }
        if (keep) idLines.push(line);
      } else if (!previousBlank) {
        idLines.push(stripStr(line, WHITESPACE));
        previousBlank = true;
      }
    }
  } else {
    let keep = true;
    for (const line of lines) {
      if (!keep) {
        // ignore newlines after a page break
        if (stripStr(line).length === 0) continue;
        keep = true;
      }
      for (const skip of SKIPS) {
        if (skip.test(line)) {
          keep = false;
          break;
        }
      }
      if (keep) {
        idLines.push(line);
      } else {
        // ignore new lines before a page break
        const count = idLines.length;
        for (let n = 0; n < count; n++) {
          const last = idLines.pop();
          if (stripStr(last).length > 0) {
            idLines.push(last);
            break;
          }
        }
      }
    }
  }
  return idLines;
}

function addSpan(line, cssClass) {
  const stripped = stripCps(stripCps(line, MARKS), WHITESPACE);
  if (stripped.length === 0) return '';
  const open = `<span class="${cssClass}">`;
  return fromCps(line)
    .replace(/\0\+/g, open)
    .replace(/\0-/g, open)
    .replace(/\0\^/g, open)
    .replace(/\u0001/g, '</span>');
}

function getDiffRows(firstIdLines, secondIdLines, context) {
  const rows = [];
  let contexts = 0;
  for (const [lb, rb, different] of mdiff(firstIdLines, secondIdLines, context)) {
    if (!lb || !rb) {
      rows.push(format(CONTEXT_LINE, { context: String(contexts) }));
      contexts += 1;
    } else if (!different) {
      rows.push(format(UNCHANGED_ROW, { lline: fromCps(lb[1]), rline: fromCps(rb[1]) }));
    } else {
      rows.push(format(CHANGED_ROW, { lline: addSpan(lb[1], 'delete'), rline: addSpan(rb[1], 'insert') }));
    }
  }
  return rows.join('');
}

function getHtmlTable(filename1, filename2, rows) {
  return format(TABLE, { filename1: getFilename(filename1), filename2: getFilename(filename2), rows });
}

// The HTML that `iddiff FILE1 FILE2` prints for the given file contents.
// `name1` and `name2` are the file names shown in the table header.
export function iddiff(text1, text2, name1, name2, options = {}) {
  const contextLines = options.contextLines ?? null;
  const skipWhitespace = options.skipWhitespace ?? false;
  const title = `Diff: ${getFilename(name1)} - ${getFilename(name2)}`;
  // get_iddiff joins the cleaned lines, escapes the text, writes it to a
  // temporary file and reads it back with readlines(). The second
  // readlines() matters: with skipWhitespace, cleanup() produces empty
  // strings, and those vanish in the roundtrip.
  const idALines = readlines(escape(cleanup(readlines(text1), skipWhitespace).join('')));
  const idBLines = readlines(escape(cleanup(readlines(text2), skipWhitespace).join('')));
  const rows = getDiffRows(idALines, idBLines, contextLines);
  let output = getHtmlTable(name1, name2, rows);
  if (!options.tableOnly) {
    output = format(HTML, { output, title });
  }
  return output;
}
