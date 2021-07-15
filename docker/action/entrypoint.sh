#!/bin/sh
set -e
[ -f Makefile ] && make .targets.mk
exec make "$@"
