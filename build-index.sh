#!/usr/bin/env bash

# Usage: $0 html [dir] [branch] github.com [gh-user] [gh-repo] [draft source...] > index.html
# Usage: $0 md [dir] [branch] github.com [gh-user] [gh-repo] [draft source...] > index.md

hash realpath 2>/dev/null || function realpath() { cd "$1"; pwd -P; }

format="$1"
root=$(realpath "${2:-.}")
hoster="${4:-github.com}"
user="${5:-<user>}"
repo="${6:-<repo>}"
default_branch="${DEFAULT_BRANCH:-$("$(dirname "$0")/default-branch.py")}"
branch="${3:-$default_branch}"
libdir="${LIBDIR:-"$(realpath "$(dirname "$0")")"}"
TMPDIR="${TMPDIR:-/tmp}"
[[ -n "$VENV" ]] && python="${python:-"${VENV}/python"}"
python="${python:-python3}"
shift 6
# Remaining arguments (now $@) are source files
all_drafts=("$@")

gh="https://${hoster}/${user}/${repo}"

case "$hoster" in
  codeberg.org)
    hosterpages="codeberg.page"
    ;;
  github.com)
    hosterpages="github.io"
    ;;
  gitlab.com)
    hosterpages="gitlab.io"
    ;;
  *)
    hosterpages="pages.${hoster}"
    ;;
esac

function rfcdiff() {
    function arg() {
        if [[ "$1" != "${1#*:}" ]]; then
            echo "url_$2=$1"
        else
            echo "doc_$2=$1"
        fi
    }
    echo "https://author-tools.ietf.org/api/iddiff?$(arg "$1" 1)&$(arg "$2" 2)"
}

function reldot() {
    [[ "$1" = "$root" ]] && echo '.' || echo "${1/"$root"\//}"
}

function githubio() {
    d="${1%/}/"
    echo "https://${user}.${hosterpages}/${repo}/${d#"$default_branch"/}${2}.txt"
}

function githubcom() {
    echo "https://${hoster}/${user}/${repo}/${1}"
}

DATERE='[0-9]* [A-Z][a-z]* 20[0-9][0-9]'
IGNOREDATE=(
    'sed' '-e' "/^   This Internet-Draft will expire on ${DATERE}./d"
    '-e' "s/^Expires: $DATERE/Expires: DATEHERE/"
    '-e' 's/\(.\{56\}\).\{11\} 20[0-9][0-9]$/\1/'
)

if [[ "$format" = "html" ]]; then
    indent=''
    function q() {
        v="${1//&/&amp;}"
        echo "${v//</&lt;}"
    }
    function qq() {
        q '"'"$1"'"'
    }
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
        url="$1"
        txt="$2"
        cls="$3"
        ttl="$4"
        [[ -n "$cls" ]] && cls=" class=$(qq "$cls")"
        [[ -n "$ttl" ]] && ttl=" title=$(qq "$ttl")"
        echo "<a href=$(qq $url)$cls$ttl>$(q "$txt")</a>"
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
        wi "<table id=$(qq "branch-$1")>"
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
    function q() {
        v="$1"
        shift
        for c in "$@"; do
            v="${v//${c}/\\${c}}"
        done
        echo "$v"
    }
    function w() {
        echo "$@"
    }
    function wi() {
        :
    }
    function wo() {
        :
    }
    function a() {
        url="$1"
        txt="$2"
        ttl="$4"
        [[ -n "$ttl" ]] && ttl=" \"$(q "$ttl" '"')\""
        echo "[$(q "$txt" "]")]($(q "$url" ")")$ttl)"
    }
    function td() {
        echo -n " $1 |"
    }
    function th() {
        echo -n " $1 |"
    }
    function tr_i() {
        echo -n "|"
    }
    function tr_o() {
        echo
    }
    function table_i() {
        extra=""
        if [[ "$1" == "$2" ]]; then
            extra=" --- | --- |"
        fi
        echo "| Draft |     |     |     |${extra//-/ }"
        echo "| ----- | --- | --- | --- |${extra}"
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

# Mac versions of bash are old and terrible.
if declare -A test >/dev/null 2>&1; then
    declare -A issue_labels=()
else
    disable_cache=true
fi
function issue_label() {
    file="$1"
    if [[ -z "$disable_cache" && -n "${issue_labels[file]}" ]]; then
        echo "${issue_labels[file]:1}"
        return
    fi
    for i in "${all_drafts[@]}"; do
        if [[ "${i%.*}" == "$file" ]]; then
            label=$("$python" "${libdir}/extract-metadata.py" "$i" github-issue-label)
            [[ -z "$disable_cache" ]] && issue_labels[file]="x$label"
            echo "$label"
            return
        fi
    done
}

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

tmpfiles=()
trap 'rm -f "${tmpfiles[@]}"' EXIT
function list_dir() {
    dir="$1"
    branch="$2"
    files=($(find "$dir" -maxdepth 1 \( -name 'draft-*.txt' -o -name 'rfc*.txt' \) -print))
    if [[ "${#files[@]}" -eq 0 ]]; then
        return
    fi
    table_i "$branch" "$default_branch"
    for file in "${files[@]}"; do
        dir=$(dirname "$file")
        file=$(basename "$file" .txt)

        tr_i
        src="${branch}:$(git ls-tree --name-only "$branch" -- "$file".md "$file".xml 2>/dev/null | head -1)"
        [[ -n "${src##*:}" ]] || \
            src="origin/${branch}:$(git ls-tree --name-only "origin/$branch" -- "$file".md "$file".xml 2>/dev/null | head -1)"
        if [[ -n "${src##*:}" ]]; then
            tmp="$(mktemp "${TMPDIR}/build-index$$-XXXXXX").${src##*.}"
            tmpfiles+=("$tmp")
            git show "$src" >"$tmp"
            src="$tmp"
        else
            # Fallback to the file in the current directory.
            src=$(ls "$file".{md,xml} 2>/dev/null | head -1)
        fi
        abbrev=$("$python" "${libdir}/extract-metadata.py" "$src" abbrev)
        title=$("$python" "${libdir}/extract-metadata.py" "$src" title)
        td "$(a "$(reldot "$dir")/${file}.html" "$abbrev" "html $file" "$title (HTML)")"
        td "$(a "$(reldot "$dir")/${file}.txt" "plain text" "txt $file" "$title (Text)")"
        this_githubio=$(githubio "$branch" "$file")
        if [[ "$2" == "$default_branch" ]]; then
            td "$(a "https://datatracker.ietf.org/doc/${file}" datatracker "dt $file" "Datatracker for $file")"
            diff=$(rfcdiff "$file" "$this_githubio")
            td "$(a "$diff" 'diff with last submission' "diff $file")"
            if [[ "${#files[@]}" -eq 1 ]]; then
                td ""
            else
                label=$(issue_label "$file")
                if [[ -n "$label" ]]; then
                    td "$(a "$(githubcom labels/$label)" issues "issues $file")"
                else
                    td ""
                fi
            fi
        elif diff -q <("${IGNOREDATE[@]}" "${root}/${file}.txt") <("${IGNOREDATE[@]}" "${dir}/${file}.txt") >/dev/null; then
            td "same as $default_branch"
        else
            diff=$(rfcdiff $(githubio "$default_branch/" "$file") "$this_githubio")
            td "$(a "$diff" 'diff with '"$default_branch" "diff $file")"
        fi
        tr_o
    done
    table_o
}

branchlink="$gh"
[[ "$branch" = "$default_branch" ]] || branchlink="${branchlink}/tree/${branch}"
h1 "Editor's drafts for $(q "$branch") branch of $(a "$branchlink" "${user}/${repo}")"
[[ "$branch" = "$default_branch" ]] && \
    p "View $(a "issues.html" "saved issues"), or the latest GitHub $(a "${gh}/issues" issues) and $(a "${gh}/pulls" "pull requests") in the $(a "${gh}" repo)."

list_dir "${root}" "$branch"

for dir in $(find "${root}" -mindepth 1 -type d \( -name '.*' -prune -o -print \)); do
    dir_branch="${dir#$root/}"
    h2 "Preview for branch $(a "$dir_branch" "$dir_branch")"
    list_dir "$dir" "$dir_branch"
done

if [ "$format" = "html" ]; then
    wi '<script>'
    cat <<EOJS
window.onload = function() {
  var referrer_branch = '$default_branch';
  // e.g., "https://github.com/user/repo/tree/$default_branch"
  var chunks = document.referrer.split("/");
  if (chunks[2] === '${hoster}' && chunks[5] === 'tree') {
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
