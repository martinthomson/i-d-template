#!/bin/sh
set -e
make .targets.mk
exec make "$@"
