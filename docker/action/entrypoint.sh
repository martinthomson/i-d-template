#!/bin/sh
set -e
if [ "$1" = "setup" ]; then
  echo "Running setup"
  exec make -f lib/setup.mk
fi
if [ ! -f Makefile ]; then
  echo "Repository isn't setup, aborting..."
  exit 1
fi

make .targets.mk
exec make "$@"
