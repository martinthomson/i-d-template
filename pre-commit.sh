#!/bin/bash

exec 1>&2

# No tests to update gh-pages
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$BRANCH" = "gh-pages" ] ||
   [ "$BRANCH" = "gh-issues" ] ||
   [ -e .git/MERGE_HEAD ]; then
     exit 0
fi

STASHED=0
if [ `git status --porcelain | grep '^[A-Z]' | wc -l` -gt 0 ]; then
  git stash save -k -q
  STASHED=1
fi

make
RESULT=$?

if test $STASHED -ne 0; then
  git stash pop -q
fi

if [ $RESULT -ne 0 ]
then
  echo "Commit refused -- documents don't build successfully."
  echo "To commit anyway, run \"git commit --no-verify\""
  exit 1
fi
