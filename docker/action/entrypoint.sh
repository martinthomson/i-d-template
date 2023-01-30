#!/bin/sh
set -e
git config --global --add safe.directory "$GITHUB_WORKSPACE"
if [ "$1" = "setup" ]; then
  echo "Running setup"
  exec make -f lib/setup.mk
fi
if [ ! -f Makefile ]; then
  echo "Cloning i-d-template into lib for default configuration."
  echo "Note: Until setup is complete, the editor's copy will not be updated."
  git clone https://github.com/martinthomson/i-d-template lib
  echo "PUSH_GHPAGES := false" >Makefile
  cat lib/template/Makefile >>Makefile
fi

make .targets.mk
exec make "$@"
