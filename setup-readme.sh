#!/usr/bin/env bash

# Usage: $0 <user> <repo> [draftxml ...]

user="$1"
repo="$2"
shift 2

githubio="https://${user}.github.io/${repo}/#go"

function fixup_other_md() {
    markdown=(LICENSE.md CONTRIBUTING.md)
    s='s~{WG_NAME}~'"$1"'~g'
    s="$s"';s~{GITHUB_USER}~'"$user"'~g'
    s="$s"';s~{GITHUB_REPO}~'"$repo"'~g'
    sed -i~ -e "$s" "${markdown[@]}"
    for i in "${markdown[@]}"; do
        rm -f "$i"~
    done
}

first=true
for d in "$@"; do
    fullname="${d%.xml}"
    author=$(echo "${fullname}" | cut -f 2 -d - -)
    wg=$(echo "${fullname}" | cut -f 3 -d - -)
    wgupper=$(echo "${wg}" | tr 'a-z' 'A-Z')
    title=$(sed -e '/<title[^>]*>/,/<\/title>/{s/.*<title[^>]*>//;/<\/title>/{s/<\/title>.*//;H;x;q;};H;};d' "$d" | xargs echo)

    if "$first"; then
        fixup_other_md "$wg"

        if [ "$author" = "ietf" ]; then
            status="IETF ${wgupper} Working Group Internet-Draft"
        else
            status="individual Internet-Draft"
        fi
        if [ $# -gt 1 ]; then
            echo "# ${wgupper} Drafts"
            status="${status}s"
        else
            echo "# $title"
            status="the ${status}, \"${title}\""
        fi
        echo
        echo "This is the working area for ${status}."
        first=false
    fi

    if [ $# -gt 1 ]; then
        echo
        echo "## $title"
    fi
    echo
    echo "* [Editor's Copy](${githubio}.${fullname}.html)"
    echo "* [Working Group Draft](https://tools.ietf.org/html/${fullname})"
    echo "* [Compare Editor's Copy to Working Group Draft](${githubio}.${fullname}.diff)"
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
[guidelines for contributions](https://github.com/${user}/${repo}/blob/master/CONTRIBUTING.md).
EOF
