#!/bin/bash

exec 1>&2

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$BRANCH" = "gh-pages" -o "$BRANCH" = "gh-issues" -o -e .git/MERGE_HEAD ]; then
     exit
fi

hash gmake 2> /dev/null && MAKE=gmake || MAKE=make

function abort() {
    echo "Commit refused: documents don't build successfully."
    echo "To commit anyway, run \"git commit --no-verify\""
    exit 1
}
trap abort ERR

files=($(git status --porcelain draft-* | sed '/^[MARCU]/{s/.*draft-/draft-/;p;};d' | sort))
tmpfiles=()
trap 'rm -f "${tmpfiles[@]}" "${txtfiles[@]}"' EXIT
for f in "${files[@]}"; do
    tmp="${f%.*}"-tmp$$."${f##*.}"
    tmpfiles+=("$tmp")
    tmpfiles+=("${tmp%.*}.txt")
    # This makes a copy of the staged file.
    (git show :"$f" 2>/dev/null || cat "$f") > "$tmp"
done
[ "${#files[@]}" -eq 0 ] && exit 0

export targets_file=.targets$$.mk
tmpfiles+=("$targets_file")
"$MAKE" txt lint "drafts=${files[*]%.*}"
