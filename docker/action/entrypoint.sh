#!/bin/sh
set -e
if [ ! -f Makefile ]; then
  echo "Running setup"
  exec make -f lib/setup.mk
fi
make .targets.mk
exec make "$@"
