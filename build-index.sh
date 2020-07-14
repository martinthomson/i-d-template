#!/usr/bin/env bash

# Usage: $0 [dir] [gh-user] [gh-repo] > index.html

hash realpath 2>/dev/null || function realpath() { cd "$1"; pwd -P; }

root=$(realpath "${1:-.}")
user="${3:-<user>}"
repo="${4:-<repo>}"
default_branch="${DEFAULT_BRANCH:-$($(dirname "$0")/default-branch.py)}"
branch="${2:-$default_branch}"

gh="https://github.com/${user}/${repo}"

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
p '<title>'"$user/$repo $branch"' preview</title>'
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

function reldot() {
    [ "$1" = "$root" ] && echo '.' || echo "${1/$root\//}"
}

function githubio() {
    d="${1%/}/"
    echo "https://${user}.github.io/${repo}/${d#$default_branch/}${2}.txt"
}

function list_dir() {
    pi '<table id="branch-'"$2"'">'
    for file in "$1"/*.txt; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)

        pi '<tr>'
        p '<th>'"${file}"'</th>'
        p '<td><a href="'"$(reldot "$dir")/${file}"'.html"'
        p '   class="html '"$file"'">html</a></td>'
        p '<td><a href="'"$(reldot "$dir")/${file}"'.txt"'
        p '   class="txt '"$file"'">plain text</a></td>'
	this_githubio=$(githubio "$branch${dir#$root}" "$file")
        if [ "$2" != "$default_branch" ]; then
	    diff=$(rfcdiff $(githubio "$default_branch/" "$file") "$this_githubio")
            p '<td><a href='"$diff"'>diff with '"$default_branch"'</a></td>'
        fi
	diff=$(rfcdiff "https://tools.ietf.org/id/${file}.txt" "$this_githubio")
        p '<td><a href="'"$diff"'" class="diff '"$file"'">'
        p '  diff with last submission</a></td>'
        po '</tr>'
    done
    po '</table>'
}

branchlink="$gh"
[ "$branch" = "$default_branch" ] || branchlink="${branchlink}/tree/${branch}"
p "<h1>Editor's drafts for ${branch} branch of <a href=\"${branchlink}\">${user}/${repo}</a></h1>"
p "<p>View <a href=\"issues.html\">saved issues</a>,"
p "  or the latest GitHub <a href=\"${gh}/issues\">issues</a>"
p "  and <a href=\"${gh}/pulls\">pull requests</a>.</p>"

list_dir "${root}" $branch

for dir in $(find "${root}" -mindepth 1 -type d \( -name '.*' -prune -o -print \)); do
    dirbranch="${dir#$root/}"
    p '<h2>Preview for branch <a href="'"$dirbranch"'">'"$dirbranch"'</a></h2>'
    list_dir "$dir" "$dirbranch"
done

pi '<script>'
cat <<EOJS
// @licstart
//  Any copyright is dedicated to the Public Domain.
//  http://creativecommons.org/publicdomain/zero/1.0/
// @licend
window.onload = function() {
  var referrer_branch = '$default_branch';
  // e.g., "https://github.com/user/repo/tree/$default_branch"
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
