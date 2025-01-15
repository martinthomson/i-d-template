#!/usr/bin/env bash

# Usage: $0 <user> <repo> [draftxml ...]

user="$1"
repo="$2"
default_branch="${DEFAULT_BRANCH:-$("$(dirname "$0")/default-branch.py")}"
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
        t=($(xmllint --xpath '/rfc/front/title/text()' "$1"))
    else
        # sed kludge if xmllint isn't available
        t=($(sed -e '/<title[^>]*>/,/<\/title>/{s/.*<title[^>]*>//;/<\/title>/{s/<\/title>.*//;H;x;q;};H;};d' "$1"))
    fi
    # haxx: rely on bash parameter normalization to remove redundant whitespace
    echo "${t[*]}"
}

if [[ "$OSTYPE" =~ (darwin|bsd).* ]] ; then
  function sed_no_backup() { sed -i '' "$@" ; }
else
  function sed_no_backup() { sed -i "$@" ; }
fi

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
            status_full="IETF [${wgupper} Working Group](https://datatracker.ietf.org/group/${wg}/documents/) Internet-Draft"
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
        wg_all="$wg"
        first=false
    elif [ "$wg" != "$wg_all" ]; then
        wg_all=""
    fi

    if [ $# -gt 1 ]; then
        echo
        echo "## $title"
    fi
    echo
    echo "* [Editor's Copy](${githubio}.${fullname}.html)"
    echo "* [Datatracker Page](https://datatracker.ietf.org/doc/${fullname})"
    echo "* [${status} Draft](https://datatracker.ietf.org/doc/html/${fullname})"
    echo "* [Compare Editor's Copy to ${status} Draft](${githubio}.${fullname}.diff)"
done

cat <<EOF


## Contributing

See the
[guidelines for contributions](https://github.com/${user}/${repo}/blob/${default_branch}/CONTRIBUTING.md).

Contributions can be made by creating pull requests.
The GitHub interface supports creating pull requests using the Edit (✏) button.


## Command Line Usage

Formatted text and HTML versions of the draft can be built using \`make\`.

\`\`\`sh
$ make
\`\`\`

Command line usage requires that you have the necessary software installed.  See
[the instructions](https://github.com/martinthomson/i-d-template/blob/main/doc/SETUP.md).

EOF

if [ -n "$wg_all" ]; then
    api="https://datatracker.ietf.org"
    wgmeta="${api}/api/v1/group/group/?format=xml&acronym=${wg_all}"
    tmp=$(mktemp)
    trap 'rm -f $tmp' EXIT
    if hash xmllint && curl -SsLf "$wgmeta" -o "$tmp" &&
       [ "$(xmllint --xpath '/response/meta/total_count/text()' "$tmp")" == "1" ]; then
        group_name="$(xmllint --xpath '/response/objects/object[1]/name/text()' "$tmp")"
        group_type_url="$(xmllint --xpath '/response/objects/object[1]/type/text()' "$tmp")"
        # Getting the abbreviation for the group type is pure haxx
        group_type_abbr="${group_type_url%/}"
        group_type_abbr="${group_type_abbr##*/}"
        group_type="$(curl -Ssf "${api}${group_type_url}?format=xml" | \
                    xmllint --xpath '/object/verbose_name/text()' /dev/stdin)"
        ml="$(xmllint --xpath '/response/objects/object[1]/list_email/text()' "$tmp")"
        ml_arch="$(xmllint --xpath '/response/objects/object[1]/list_archive/text()' "$tmp")"
        ml_sub="$(xmllint --xpath '/response/objects/object[1]/list_subscribe/text()' "$tmp")"

        # This little script probably needs some documentation:
        # /^$/{H;d;} appends blank lines in the hold buffer, without printing them.
        # /^## .*/d deletes from the the Working Group Info section header to the end.
        # /./{x;/\n/{s/.//;p;};x;} prints a blank line before a non-blank line,
        #    but only if the hold buffer has a blank line in it.
        #    The s/.//;p; part ensures that an extra blank line isn't added by deleting one.
        sed_no_backup -e '/^$/{H;d;};/^## Working Group Info/,$d;/./{x;/\n/{s/.//;p;};x;}' CONTRIBUTING.md
        cat >>CONTRIBUTING.md <<EOF


## Working Group Information

Discussion of this work occurs on the [${group_name}
${group_type} mailing list](mailto:${ml})
([archive](${ml_arch}),
[subscribe](${ml_sub})).
In addition to contributions in GitHub, you are encouraged to participate in
discussions there.

**Note**: Some working groups adopt a policy whereby substantive discussion of
technical issues needs to occur on the mailing list.

You might also like to familiarize yourself with other
[${group_type} documents](https://datatracker.ietf.org/${group_type_abbr}/${wg_all}/documents/).
EOF
    fi
fi
