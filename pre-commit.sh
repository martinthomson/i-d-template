#!/bin/bash
# No tests to update gh-pages
BRANCH=$(git symbolic-ref HEAD 2>/dev/null)
[ $BRANCH = "refs/heads/gh-pages" ] && exit 0

git stash save -k -q
make
RESULT=$?
git stash pop -q
[ $RESULT -ne 0 ] && exit 1
exit 0
