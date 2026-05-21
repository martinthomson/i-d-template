#!/usr/bin/env bash

found=false
args=()
for i in "$@"; do
    found=true
    f="${i%:*}"
    if [[ -f "$f" ]]; then
        f="$(realpath "$f")"
    else
        f="tests/${f}.feature"
    fi
    [[ "$i" != "${i#*:}" ]] && f="${f}:${i#*:}"
    args+=("$f")
done

cd "$(dirname "$0")/.."
[[ -d tests/.venv ]] || python -m venv tests/.venv
[[ -x tests/.venv/bin/behave ]] || tests/.venv/bin/pip install behave
[[ "${#args[@]}" -eq 0 ]] && args=(tests/*.feature)
exec tests/.venv/bin/behave "${args[@]}"
