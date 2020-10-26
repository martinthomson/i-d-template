#!/bin/bash

exec 1>&2

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$BRANCH" = "gh-pages" -o "$BRANCH" = "gh-issues" -o -e .git/MERGE_HEAD ]; then
     exit
fi

hash gmake 2> /dev/null && MAKE=gmake || MAKE=make

txtfiles=()
tmpfiles=()
function cleanup() {
    rm -f "${tmpfiles[@]}" "${htmlfiles[@]}"
}
function abort() {
    echo "Commit refused: documents don't build successfully."
    echo "To commit anyway, run \"git commit --no-verify\""
    cleanup
    exit 1
}
trap abort ERR
trap cleanup EXIT

files=($(git status --porcelain draft-* | sed '/^[MARCU]/{s/.*draft-/draft-/;p;};d' | sort))
for f in "${files[@]}"; do
    tmp="${f%.*}"-tmp$$."${f##*.}"
    tmpfiles+=("$tmp")
    htmlfiles+=("${tmp%.*}.html")
    # This makes a copy of the staged file.
    (git show :"$f" 2>/dev/null || cat "$f") \
         | sed -e "s/${f%.*}-latest/${tmp%.*}-latest/g" > "$tmp"
done
[ "${#files[@]}" -eq 0 ] && exit 0

"$MAKE" "${htmlfiles[@]}" lint "drafts=${tmpfiles[*]%.*}" DISABLE_TARGETS_UPDATE=true
