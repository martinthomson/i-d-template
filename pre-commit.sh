#!/bin/bash
# No tests to update gh-pages
BRANCH=$(git symbolic-ref HEAD 2>/dev/null)
[ $BRANCH = "refs/heads/gh-pages" ] && exit 0

git stash save -k -q
make
RESULT=$?
git stash pop -q

if [ $RESULT -ne 0 ]
then
  echo "Commit refused -- documents don't build successfully."
  echo "To commit anyway, run \"git commit --no-verify\""
  exit 1
fi

exit 0
