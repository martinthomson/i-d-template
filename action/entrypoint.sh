#!/bin/sh
set -e
make .targets.mk
make "$@"
