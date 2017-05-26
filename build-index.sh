#!/usr/bin/env bash

# Usage: $0 [dir] [gh-user] [gh-repo] > index.html

root=$(realpath "${1:-.}")
user="${2:-<user>}"
repo="${3:-<repo>}"

indent=''
function p() {
    echo -n "$indent";echo "$@"
}
function pi() {
    p "$@"
    indent="$indent  "
}
function po() {
    indent="${indent#  }"
    p "$@"
}

p '<!DOCTYPE html>'
pi '<html>'
pi '<head>'
p '<title>'"$user/$repo"' branches</title>'
p '<style>li:target { background-color: lightgrey; }</style>'
po '</head>'
pi '<body>'

function rfcdiff() {
    echo "https://tools.ietf.org/rfcdiff?url1=${1}&amp;url2=${2}"
}

function rel() {
    d="${1/$root\//}"
    [ -n "$d" ] && d="$d/"
    echo "$d"
}

function reldot() {
    d="${1/$root\//}"
    echo "${d:-.}"
}

function githubio() {
    echo "https://${user}.github.io/${repo}/$(rel "$1")${2}.txt"
}

function list_dir() {
    pi '<ul id="branch-'"$(basename "$1")"'">'
    for file in "$1"/*.txt; do
        pi '<li>'
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)
        p "${file}: "
        p '<a href="'"$(reldot "$dir")/${file}"'.html"'
        p '   class="html '"$file"'">html</a>, '
        p '<a href="'"$(reldot "$dir")/${file}"'.txt"'
        p '   class="txt '"$file"'">plain text</a>, '
        parent="$dir"
        while [ "$parent" != "$root" ]; do
            parent=$(dirname "$parent")
            p '<a href="'"$(rfcdiff $(githubio "$parent" "$file") $(githubio "$dir" "$file"))"'">'
            [ "$parent" = "$root" ] && pbranch=master || pbranch=$(rel "$parent")
            p "  diff with ${pbranch}</a>, "
        done
        p '<a href="'"$(rfcdiff "https://tools.ietf.org/id/${file}.txt" $(githubio "$dir" "$file"))"'"'
        p '   class="diff '"$file"'">'
        p "  diff with last submission</a>"
        po '</li>'
    done
    po '</ul>'
}

list_dir "${root}"

pi '<ul>'
for dir in "${root}"/*; do
    if [ -d "${dir}" ]; then
        pi '<li>'"$(basename "$dir")"' branch:'
	list_dir "$dir"
        po '</li>'
    fi
done
po '</ul>'

pi '<script>'
cat <<EOJS
// @licstart
//  Any copyright is dedicated to the Public Domain.
//  http://creativecommons.org/publicdomain/zero/1.0/
// @licend */
window.onload = function() {
  var referrer_branch = 'master';
  // e.g., "https://github.com/user/repo/tree/master"
  var chunks = document.referrer.split("/");
  if (chunks[2] == 'github.com' && chunks[5] == 'tree') {
    referrer_branch = chunks[6];
  }
  let branch = document.querySelector('#branch-' + referrer_branch);
  let h = document.location.hash.substring(1);
  if (h === 'show') {
    document.location.hash = '#' + branch.id;
  } else if (h.startsWith('go')) {
    let e = branch.querySelector(h.substring(2));
    if (e && e.href) {
      document.location = e.href;
    }
  }
};
EOJS
po '</script>'

po '</body>'
po '</html>'
