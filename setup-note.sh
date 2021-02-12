#!/usr/bin/env bash

# Usage: $0 <user> <repo> [drafts...]

user="$1"
repo="$2"
shift 2

if [[ -z "$WG" ]]; then
    # Guess the working group name from the drafts
    for d in "$@"; do
        d="${d#draft-}"
        d="${d#*-}"
        d="${d%%-*}"
        if [[ -z "$wg" ]]; then
            wg="$d"
        elif [[ "$wg" != "$d" ]]; then
	    echo "Found conflicting working group names in drafts" 1>&2
	    echo "  $wg != $d" 1>&2
	    exit 1
        fi
    done
else
    wg="${WG}"
fi

api="https://datatracker.ietf.org"
wgmeta="$api/api/v1/group/group/?format=xml&acronym=$wg"
tmp=$(mktemp)
trap 'rm -f $tmp' EXIT
if hash xmllint && curl -Ssf "$wgmeta" -o "$tmp"; then
    group_name="$(xmllint --xpath '/response/objects/object[1]/name/text()' "$tmp")"
    group_type_url="$(xmllint --xpath '/response/objects/object[1]/type/text()' "$tmp")"
    group_type="$(curl -Ssf "${api}${group_type_url}?format=xml" | \
                 xmllint --xpath '/object/verbose_name/text()' /dev/stdin)"
    ml="$(xmllint --xpath '/response/objects/object[1]/list_email/text()' "$tmp")"
    ml_arch="$(xmllint --xpath '/response/objects/object[1]/list_archive/text()' "$tmp")"
else
    wgname="$(echo "$wg" | tr '[a-z]' '[A-Z]')"
    ml="${ML:-${wg}@ietf.org}"
    ml_arch="https://mailarchive.ietf.org/arch/browse/${wg}/"
fi

echo '<note title="Discussion Venues" removeInRFC="true">'
echo "<t>Discussion of this document takes place on the
  ${group_name} ${group_type} mailing list (${ml}),
  which is archived at <eref target=\"${ml_arch}\"/>.</t>"
echo "<t>Source for this draft and an issue tracker can be found at
  <eref target=\"https://github.com/${user}/${repo}\"/>.</t>"
echo '</note>'
