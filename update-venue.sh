#!/usr/bin/env bash

# Usage: $0 <user> <repo> [drafts...]

set -e

. "$(dirname "$0")/wg-meta.sh"

user="$1"
repo="$2"
shift 2

if [[ "$OSTYPE" =~ (darwin|bsd).* ]] ; then
  function sed_no_backup() { sed -i '' "$@" ; }
else
  function sed_no_backup() { sed -i "$@" ; }
fi

last_wg=
for d in "$@"; do
    if ! head -1 "$d" | grep -q "^---"; then
        # This only works for kramdown-rfc drafts
        continue
    fi
    w="${d#draft-}"
    w="${w#*-}"
    w="${w%%-*}"

    sed_no_backup -e '1,/^---/ {
/^venue:/,/^[^# ]/{
s,^[# ]*github: .*,  github: "'"$user/$repo"'",
s,^[# ]*latest: .*,  latest: "'"https://$user.github.io/$repo/${d%.*}.html"'",
}
}' "$d"
    if [[ "$w" == "$last_wg"  ]] || wgmeta "$w"; then
        sed_no_backup -e '1,/^---/ {
s,^[# ]*area: .*,area: "'"$wg_area"'",
s,^[# ]*workgroup: .*,workgroup: "'"$wg_name"'",
/^venue:/,/^[^# ]/{
s,^[# ]*group: .*,  group: "'"$wg_name"'",
s,^[# ]*type: .*,  type: "'"$wg_type"'",
s,^[# ]*mail: .*,  mail: "'"$wg_mail"'",
s,^[# ]*arch: .*,  arch: "'"$wg_arch"'",
}
}' "$d"
        last_wg="$w"
    else
	sed_no_backup -e '1,/^---/ {
s,^[# ]*\(area\|workgroup\):,# \1:,
/^venue:/,/^[^# ]/{
s,^[# ]*\(group\|type\|mail\|arch\):,#  \1:,g
}
}' "$d"
    fi
done
