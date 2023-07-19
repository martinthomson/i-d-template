#!/usr/bin/env bash

# Usage: $0 github.com <user> <repo> [drafts...]

set -e

host="$1"
user="$2"
repo="$3"
shift 3

# Determine if the draft is a kramdown draft with a venue section.
hasvenue() {
    head -1 "$1" | grep -q "^---" && \
        sed -e '2,/^---/p;d' "$1" | grep -q '^venue:'
}

if [[ -z "$WG" ]]; then
    # Guess the working group name from the drafts
    first=true
    for d in "$@"; do
        # If a kramdown has a venue section, skip it.
        if hasvenue "$d"; then
            continue
        fi

        w="${d#draft-}"
        w="${w#*-}"
        w="${w%%-*}"
        if $first; then
            wg="$w"
            first=false
        elif [[ "$wg" != "$w" ]]; then
            echo "Found conflicting working group names in drafts" 1>&2
            echo "  $wg != $w" 1>&2
            wg=""
            break
        fi
    done
else
    wg="${WG}"
fi

if $first; then
    exit 0
fi

. $(dirname "$0")/wg-meta.sh
if ! wgmeta "$wg"; then
    wg=""
fi

echo '<note title="Discussion Venues" removeInRFC="true">'
if [[ -n "$wg" ]]; then
  echo "<t>Discussion of this document takes place on the
    ${wg_name} ${wg_type} mailing list (${wg_mail}),
    which is archived at <eref target=\"${wg_arch}\"/>.</t>"
fi
echo "<t>Source for this draft and an issue tracker can be found at
    <eref target=\"https://${host}/${user}/${repo}\"/>.</t>"
echo '</note>'
