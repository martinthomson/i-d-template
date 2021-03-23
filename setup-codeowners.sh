#!/usr/bin/env bash
# Takes as input a list of XML files.

echo "# Automatically generated CODEOWNERS file."
for f in "$@"; do
    if hash xmllint >/dev/null 2>&1; then
        authors=($(xmllint --xpath '/rfc/front/author/address/email/text()' "$f" 2>/dev/null))
    else
        # sed kludge to extract author emails; assumes at most one per line
        authors=($(sed -e '/<front[^>]*>/,${s/^.*<email>\([^<]*\)<\/email>.*$/\1/;T e;p;: e;/<\/front>/Q;};d' "$f"))
    fi

    s=$(git ls-tree --name-only @ "${f%.xml}"*)
    echo "$s ${authors[@]}"
done
