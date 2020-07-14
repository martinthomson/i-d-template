#!/usr/bin/env bash

# Usage: $0 <user> <repo> [draftxml ...]

user="$1"
repo="$2"
default_branch="${DEFAULT_BRANCH:-$($(dirname "$0")/default-branch.py)}"
shift 2

githubio="https://${user}.github.io/${repo}/#go"

function fixup_other_md() {
    markdown=(LICENSE.md CONTRIBUTING.md)
    s='s~{WG_NAME}~'"$1"'~g'
    s="$s"';s~{GITHUB_USER}~'"$user"'~g'
    s="$s"';s~{GITHUB_REPO}~'"$repo"'~g'
    s="$s"';s~{GITHUB_BRANCH}~'"$default_branch"'~g'
    sed -i~ -e "$s" "${markdown[@]}"
    for i in "${markdown[@]}"; do
        rm -f "$i"~
    done
}

function get_title() {
    if hash xmllint >/dev/null 2>&1; then
        title=($(xmllint --xpath '/rfc/front/title/text()' "$1"))
    else
        # sed kludge if xmllint isn't available
        title=($(sed -e '/<title[^>]*>/,/<\/title>/{s/.*<title[^>]*>//;/<\/title>/{s/<\/title>.*//;H;x;q;};H;};d' "$1"))
    fi
    # haxx: rely on bash parameter normalization to remove redundant whitespace
    echo "${title[*]}"
}

first=true
for d in "$@"; do
    fullname="${d%.xml}"
    author=$(echo "${fullname}" | cut -f 2 -d - -)
    wg=$(echo "${fullname}" | cut -f 3 -d - -)
    wgupper=$(echo "${wg}" | tr 'a-z' 'A-Z')
    title=$(get_title "$d")

    if "$first"; then
        fixup_other_md "$wg"

        if [ "$author" = "ietf" ]; then
	    status="Working Group"
            status_full="IETF [${wgupper} Working Group](https://datatracker.ietf.org/wg/${wg}/documents/) Internet-Draft"
        else
	    status="Individual"
            status_full="individual Internet-Draft"
        fi
        if [ $# -gt 1 ]; then
            echo "# ${wgupper} Drafts"
            status_full="${status_full}s"
        else
            echo "# $title"
            status_full="the ${status_full}, \"${title}\""
        fi
        echo
        echo "This is the working area for ${status_full}."
        first=false
    fi

    if [ $# -gt 1 ]; then
        echo
        echo "## $title"
    fi
    echo
    echo "* [Editor's Copy](${githubio}.${fullname}.html)"
    echo "* [${status} Draft](https://tools.ietf.org/html/${fullname})"
    echo "* [Compare Editor's Copy to ${status} Draft](${githubio}.${fullname}.diff)"
done

cat <<EOF

## Building the Draft

Formatted text and HTML versions of the draft can be built using \`make\`.

\`\`\`sh
$ make
\`\`\`

This requires that you have the necessary software installed.  See
[the instructions](https://github.com/martinthomson/i-d-template/blob/master/doc/SETUP.md).


## Contributing

See the
[guidelines for contributions](https://github.com/${user}/${repo}/blob/${default_branch}/CONTRIBUTING.md).
EOF
