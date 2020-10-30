#!/usr/bin/env bash

# Usage: $0 html [dir] [gh-user] [gh-repo] > index.html
# Usage: $0 md [dir] [gh-user] [gh-repo] > index.md

hash realpath 2>/dev/null || function realpath() { cd "$1"; pwd -P; }

format="$1"
root=$(realpath "${2:-.}")
user="${4:-<user>}"
repo="${5:-<repo>}"
default_branch="${DEFAULT_BRANCH:-$($(dirname "$0")/default-branch.py)}"
branch="${3:-$default_branch}"

gh="https://github.com/${user}/${repo}"

function rfcdiff() {
    echo "https://tools.ietf.org/rfcdiff?url1=${1}&amp;url2=${2}"
}

function reldot() {
    [[ "$1" = "$root" ]] && echo '.' || echo "${1/$root\//}"
}

function githubio() {
    d="${1%/}/"
    echo "https://${user}.github.io/${repo}/${d#$default_branch/}${2}.txt"
}

if [[ "$format" = "html" ]]; then
    indent=''
    function w() {
        echo -n "$indent";echo "$@"
    }
    function wi() {
        w "$@"
        indent="$indent  "
    }
    function wo() {
        indent="${indent#  }"
        w "$@"
    }
    function e {
      w "<$1>$2</$1>"
    }
    function a() {
        url=$1
        text=$2
        shift 2
        if [ $# -gt 0 ]; then
            cls=' class="'"$*"'"'
        else
            cls=''
        fi
        echo '<a href="'"$url"'"'"$cls"'>'"$text"'</a>'
    }

    function td() {
        e td "$@"
    }
    function th() {
        e th "$@"
    }
    function tr_i() {
        wi "<tr>"
    }
    function tr_o() {
        wo "</tr>"
    }
    function table_i() {
        wi '<table id="'"$1"'">'
    }
    function table_o() {
        wo '</table>'
    }
    function h1() {
      e h1 "$@"
    }
    function h2() {
      e h2 "$@"
    }
    function p() {
      e p "$@"
    }
elif [[ "$format" = "md" ]]; then
    function w() {
        echo "$@"
    }
    function wi() {
        true
    }
    function wo() {
        true
    }
    function a() {
        echo "[$2]($1)"
    }
    function td() {
        echo -n "$1 |"
    }
    function th() {
        echo -n "$1 |"
    }
    function tr_i() {
        echo -n "| "
    }
    function tr_o() {
        echo
    }
    function table_i() {
        echo "| Draft |     |     |     |     |"
        echo "| ----- | --- | --- | --- | --- |"
    }
    function table_o() {
        echo
    }
    function h1() {
        p "# $1"
    }
    function h2() {
        p "## $1"
    }
    function p() {
        echo "$1"
        echo
    }
else
    echo "Unknown format: $format" 2>&1
    exit 2
fi

if [[ "$format" = "html" ]]; then
    w '<!DOCTYPE html>'
    wi '<html>'
    wi '<head>'
    w '<title>'"$user/$repo $branch"' preview</title>'
    w '<meta name="viewport" content="initial-scale=1.0">'
    wi '<style type="text/css">/*<![CDATA[*/'
    w 'body { font-family: "Helvetica Neue","Open Sans", Helvetica, Calibri,sans-serif; }'
    w 'h1, h2, td { font-family: "Helvetica Neue", "Roboto Condensed", "Open Sans", Helvetica, Calibri, sans-serif; }'
    w 'h1 { font-size: 20px; } h2 { font-size: 16px; }'
    w 'table { margin: 5px 10px; border-collapse: collapse; }'
    w 'th, td { font-weight: normal; text-align: left; padding: 2px 5px; }'
    w 'a:link { color: #000; } a:visited { color: #00a; }'
    wo '/*]]>*/</style>'
    wo '</head>'
    wi '<body>'
fi

function list_dir() {
    files=($(find "$1" -maxdepth 1 \( -name 'draft-*.txt' -o -name 'rfc*.txt' \) -print))
    if [[ "${#files[@]}" -eq 0 ]]; then
        return
    fi
    table_i "branch-$2"
    for file in "${files[@]}"; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)

        tr_i
        th "${file}"
        td "$(a "$(reldot "$dir")/${file}.html" html html "$file")"
        td "$(a "$(reldot "$dir")/${file}.txt" "plain text" txt "$file")"
        this_githubio=$(githubio "$branch${dir#$root}" "$file")
        if [[ "$2" != "$default_branch" ]]; then
	          diff=$(rfcdiff $(githubio "$default_branch/" "$file") "$this_githubio")
            td "$(a "$diff" 'diff with '"$default_branch")"
        fi
	      diff=$(rfcdiff "https://tools.ietf.org/id/${file}.txt" "$this_githubio")
        td "$(a "$diff" 'diff with last submission' diff "$file")"
        tr_o
    done
    table_o
}

branchlink="$gh"
[[ "$branch" = "$default_branch" ]] || branchlink="${branchlink}/tree/${branch}"
h1 "Editor's drafts for ${branch} branch of $(a "$branchlink" "${user}/${repo}")"
p "View $(a "issues.html" "saved issues"), or the latest GitHub $(a "${gh}/issues" issues) and $(a "${gh}/pulls" "pull requests")."

list_dir "${root}" $branch

for dir in $(find "${root}" -mindepth 1 -type d \( -name '.*' -prune -o -print \)); do
    dir_branch="${dir#$root/}"
    h2 "Preview for branch $(a "$dir_branch" "$dir_branch")"
    list_dir "$dir" "$dir_branch"
done

if [ "$format" = "html" ]; then
    wi '<script>'
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
    wo '</script>'
    wo '</body>'
    wo '</html>'
fi
