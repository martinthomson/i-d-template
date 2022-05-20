#!/usr/bin/env bash
# Usage: $0 <targetfile> [-s tool] tool [arguments ...]
file="${1%.*}"
if [[ "$2" == "-s" ]]; then
    stage="$3"
    shift 3
else
    stage="$2"
    shift 1
fi

if [[ -z "$TRACE_FILE" ]]; then
    exec "$@"
fi

tmp=$(mktemp)
trap 'rm -f $tmp' EXIT
set -o pipefail
if [[ "$1" == "!" ]]; then
    shift
    ! "$@"
else
    "$@"
fi | tee -a "$tmp"
status="$?"
echo "$file $stage $status" >>"$TRACE_FILE"
if [[ "$status" -ne 0 ]]; then
    tail -10 "$tmp" | while read line; do
        echo "$file $stage $line" >>"$TRACE_FILE"
    done
fi
exit "$status"
