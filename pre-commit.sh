#!/usr/bin/env bash

exec 1>&2

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$BRANCH" = "gh-pages" -o "$BRANCH" = "gh-issues" -o -e .git/MERGE_HEAD ]; then
     exit
fi

hash gmake 2> /dev/null && MAKE=gmake || MAKE=make

srcfiles=()
xmlfiles=()
htmlfiles=()
function cleanup() {
    rm -f "${srcfiles[@]}" "${xmlfiles[@]}" "${htmlfiles[@]}"
}
function abort() {
    echo "Commit refused: document build error."
    echo "To commit anyway, run \"git commit --no-verify\""
    cleanup
    exit 1
}
trap abort ERR
trap cleanup EXIT

files=($(git status --porcelain draft-* rfc* | sed '/^[MAU]/{s/^.. //;p;};/^[RC]/{s/.* -> //;p;};d' | sort))
for f in "${files[@]}"; do
    tmp="${f%.*}"-tmp$$."${f##*.}"
    srcfiles+=("$tmp")
    xmlfiles+=("${tmp%.*}.xml")
    htmlfiles+=("${tmp%.*}.html")
    # This makes a copy of the staged file.
    (git show :"$f" 2>/dev/null || cat "$f") \
         | sed -e "s/${f%.*}-latest/${tmp%.*}-latest/g" > "$tmp"
done
[ "${#files[@]}" -eq 0 ] && exit 0

"$MAKE" "${htmlfiles[@]}" lint "drafts=${xmlfiles[*]%.*}" EXTRA_TARGETS=false
