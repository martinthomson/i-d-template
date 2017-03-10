#!/bin/bash

exec 1>&2

# No tests to update gh-pages
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$BRANCH" = "gh-pages" -o "$BRANCH" = "gh-issues" -o -e .git/MERGE_HEAD ]; then
     exit
fi

files=($(git status --porcelain draft-* | sed '/^[MARCU]/{s/.*draft-/draft-/;p;};d'))
tmpfiles=()
txtfiles=()
trap 'rm -f "${tmpfiles[@]}" "${txtfiles[@]}"' ERR EXIT
for f in "${files[@]}"; do
    tmp="${f%.*}"-tmp$$."${f##*.}"
    tmpfiles+=("$tmp")
    txtfiles+=("${tmp%.*}.txt")
    # This makes a copy of the staged file.
    git show :"$f" > "$tmp"
done
hash gmake 2> /dev/null && MAKE=gmake || MAKE=make
[ "${#txtfiles[@]}" -eq 0 ] || "$MAKE" "${txtfiles[@]}"
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "Commit refused -- documents don't build successfully."
  echo "To commit anyway, run \"git commit --no-verify\""
  exit 1
fi
