#!/usr/bin/env bash
trace="$1"
status="$2"

if [[ "$status" -eq 0 ]]; then
    echo "## Build Succeeded"
else
    echo "## Build Failed"
fi
echo

tmp=$(mktemp)
trap 'rm -f $tmp' EXIT
cut -f1 -d' ' "$trace" | sort | uniq | while read -r f; do
    failed=
    grep "^$f " "$trace" | cut -f2- -d' ' | sort | uniq >"$tmp"
    while read -r j s; do
        if [[ "$failed" != "$j" && "$s" != "0" ]]; then
            if [[ -z "$failed" ]]; then
                echo "❌ $f"
                echo
            fi
            echo "<details><summary>❌ step '$j' failed</summary>"
            echo
            echo '```'
            grep "^$f $j " "$trace" | cut -f3- -d' ' | tail +2
            echo '```'
            echo "</details>"
            echo
            failed=$j
        fi
    done <"$tmp"
    if [[ -z  "$failed" ]]; then
        echo "✅ $f"
        echo
    fi
done
