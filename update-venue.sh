#!/usr/bin/env bash

# Usage: $0 <user> <repo> [drafts...]

set -e

. $(dirname "$0")/wg-meta.sh

user="$1"
repo="$2"
shift 2

# Determine if the draft is a kramdown draft with a venue section.
hasvenue() {
    head -1 "$1" | grep -q "^---" && \
        sed -e '2,/^---/p;d' "$1" | grep -q '^venue:'
}

last_wg=
for d in "$@"; do
    if ! head -1 "$d" | grep -q "^---"; then
        continue
    fi
    w="${d#draft-}"
    w="${w#*-}"
    w="${w%%-*}"

    if [[ "$w" == "$last_wg"  ]] || wgmeta "$w"; then
        cmds=""
        cmds="s/^ *group: .*/  group: $group_name/;"
        sed -i -e '/^venue:/,/^[^ ]/{'"
s|^ *group: .*|  group: $wg_name|
s|^ *type: .*|  type: $wg_type|
s|^ *mail: .*|  mail: $wg_mail|
s|^ *arch: .*|  arch: $wg_arch|
s|^ *github: .*|  github: $user/$repo|
"'}' "$d"
        last_wg="$w"
    fi
done
