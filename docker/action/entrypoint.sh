#!/bin/sh
set -e
if [ "$1" = "setup" ]; then
  echo "Running setup"
  exec make -f lib/setup.mk
fi
if [ ! -f Makefile ]; then
  echo "Cloning i-d-template into lib for default configuration."
  git clone https://github.com/martinthomson/i-d-template lib
  ln -s lib/template/Makefile Makefile
fi

make .targets.mk
exec make "$@"
