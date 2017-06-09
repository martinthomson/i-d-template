#!/usr/bin/env bash

# Usage: $0 [dir] [gh-user] [gh-repo] > index.html

hash realpath 2>/dev/null || function realpath() { cd "$1"; pwd -P; }

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
pi '<style>'
p 'body { font-family: sans-serif; }'
p 'h2 { font-size: 130%; }'
p 'h3 { font-size: 120%; color: #222; }'
po '</style>'
po '</head>'
pi '<body>'

function rfcdiff() {
    echo "https://tools.ietf.org/rfcdiff?url1=${1}&amp;url2=${2}"
}

function rel() {
    [ "$1" = "$root" ] && return
    echo "${1/$root\//}/"
}

function reldot() {
    [ "$1" = "$root" ] && echo '.' || echo "${1/$root\//}"
}

function githubio() {
    echo "https://${user}.github.io/${repo}/$(rel "$1")${2}.txt"
}

function list_dir() {
    pi '<ul id="branch-'"$2"'">'
    for file in "$1"/*.txt; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)

        pi '<li>'
        p "${file}: "
        p '<a href="'"$(reldot "$dir")/${file}"'.html"'
        p '   class="html '"$file"'">html</a>, '
        p '<a href="'"$(reldot "$dir")/${file}"'.txt"'
        p '   class="txt '"$file"'">plain text</a>, '
        if [ "$dir" != "$root" ]; then
            parent=$(dirname "$dir")
            p '<a href="'"$(rfcdiff $(githubio "$parent" "$file") $(githubio "$dir" "$file"))"'">'
            [ "$parent" = "$root" ] && pbranch=master || pbranch=$(rel "$parent")
            p "  diff with ${pbranch}</a>, "
        fi
        p '<a href="'"$(rfcdiff "https://tools.ietf.org/id/${file}.txt" $(githubio "$dir" "$file"))"'"'
        p '   class="diff '"$file"'">'
        p "  diff with last submission</a>"
        po '</li>'
    done
    po '</ul>'
}

p "<h2>Editor's drafts for ${user}/${repo}</h2>"
list_dir "${root}" master

for dir in "${root}"/*; do
    if [ -d "${dir}" ]; then
        p "<h3>Preview for branch $(basename "$dir")</h3>"
        list_dir "$dir" "$(basename "$dir")"
    fi
done

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
  if (chunks[2] === 'github.com' && chunks[5] === 'tree') {
    referrer_branch = chunks[6];
  }
  let branch = document.querySelector('#branch-' + referrer_branch);
  let h = document.location.hash.substring(1);
  if (h === 'show') {
    document.location.hash = '#' + branch.id;
  } else if (branch && h.startsWith('go')) {
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
