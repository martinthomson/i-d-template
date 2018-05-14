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
p '<title>'"$user/$repo"' preview</title>'
p '<meta name="viewport" content="initial-scale=1.0">'
pi '<style type="text/css">/*<![CDATA[*/'
p 'body { font-family: "Helvetica Neue","Open Sans",Helvetica,Calibri,sans-serif; }'
p 'h1, h2, td { font-family: "Helvetica Neue","Roboto Condensed","Open Sans",Helvetica,Calibri,sans-serif; }'
p 'h1 { font-size: 20px; } h2 { font-size: 16px; }'
p 'table { margin: 5px 10px; border-collapse: collapse; }'
p 'th, td { font-weight: normal; text-align: left; padding: 2px 5px; }'
p 'a:link { color: #000; } a:visited { color: #00a; }'
po '/*]]>*/</style>'
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
    pi '<table id="branch-'"$2"'">'
    for file in "$1"/*.txt; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)

        pi '<tr>'
        p "<th>${file}</th>"
        p '<td><a href="'"$(reldot "$dir")/${file}"'.html"'
        p '   class="html '"$file"'">html</a></td>'
        p '<td><a href="'"$(reldot "$dir")/${file}"'.txt"'
        p '   class="txt '"$file"'">plain text</a></td>'
        if [ "$dir" != "$root" ]; then
            parent=$(dirname "$dir")
            diff=$(rfcdiff $(githubio "$parent" "$file") $(githubio "$dir" "$file"))
            p '<td><a href="'"$diff"'">'
            [ "$parent" = "$root" ] && pbranch=master || pbranch=$(rel "$parent")
            p "  diff with ${pbranch}</a></td>"
        fi
        diff=$(rfcdiff "https://tools.ietf.org/id/${file}.txt" $(githubio "$dir" "$file"))
        p '<td><a href="'"$diff"'" class="diff '"$file"'">'
        p '  diff with last submission</a></td>'
        po '</tr>'
    done
    po '</table>'
}

gh="https://github.com/${user}/${repo}"
p "<h1>Editor's drafts for <a href=\"${gh}\">${user}/${repo}</a></h1>"
p "<p>View <a href=\"issues.html\">saved issues</a>,"
p "  or the latest GitHub issues <a href=\"${gh}/issues\">issues</a>"
p "  and <a href=\"${gh}/pulls\">pull requests</a>.</p>"

list_dir "${root}" master

for dir in "${root}"/*; do
    if [ -d "${dir}" ]; then
        p '<h2>Preview for branch <a href="'$(basename "$dir")'">'$(basename "$dir")'</a></h2>'
        list_dir "$dir" "$(basename "$dir")"
    fi
done

pi '<script>'
cat <<EOJS
// @licstart
//  Any copyright is dedicated to the Public Domain.
//  http://creativecommons.org/publicdomain/zero/1.0/
// @licend
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
