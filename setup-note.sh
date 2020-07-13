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

ml() {
    echo "https://mailarchive.ietf.org/arch/browse/$1/"
}

echo '<note title="Discussion Venues" removeInRFC="true">'
echo "<t>Discussion of this document takes place on the
  ${wg^^} Working Group mailing list (${ML:-${wg}@ietf.org}),
  which is archived at <eref target=\"$(ml "${wg}")\"/>.</t>"
echo "<t>Source for this draft and an issue tracker can be found at
  <eref target=\"https://github.com/${user}/${repo}\"/>.</t>"
echo '</note>'
