#!/usr/bin/env bash

# Usage: $0 [dir] [gh-user] [gh-repo] > index.md

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
    for file in "$1"/*.txt; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)
    	this_githubio=$(githubio "$branch${dir#$root}" "$file")
    	diff=$(rfcdiff "https://tools.ietf.org/id/${file}.txt" "$this_githubio")
        if [ "$2" != "$default_branch" ]; then
            ddiff=$(rfcdiff $(githubio "$default_branch/" "$file") "$this_githubio")
            default_diff="[diff with '$default_branch']($ddiff)"
        fi
        p "| ${file} | [${file}]($(reldot $dir)/${file}.html) | [plain text]($(reldot $dir)/${file}.txt) | $default_diff | [diff with last submission]($diff) |"
    done
}

branchlink="$gh"
[ "$branch" = "$default_branch" ] || branchlink="${branchlink}/tree/${branch}"
p "# Editor's drafts for ${branch} branch of [${user}/${repo}](${branchlink})"
p ""
p "View [saved issues](issues.html) or the latest GitHub [issues](${gh}/issues) and [pull requests](${gh}/pulls)"
p ""
list_dir "${root}" $branch

for dir in $(find "${root}" -mindepth 1 -type d \( -name '.*' -prune -o -print \)); do
    dirbranch="${dir#$root/}"
    p "## Preview for branch [${dirbranch}](${dirbranch})"
    p ""
    list_dir "$dir" "$dirbranch"
done

