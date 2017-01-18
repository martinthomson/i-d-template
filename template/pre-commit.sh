#!/bin/bash
git stash save -q --keep-index
make
RESULT=$?
git stash pop -q
[ $RESULT -ne 0 ] && exit 1
exit 0
