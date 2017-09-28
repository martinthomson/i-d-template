#!/usr/bin/env bash

tool="$1"
version="$2"

tmp=$(mktemp -t "${tool}XXXXX.tgz")
trap 'rm -f $tmp' EXIT

curl -sSLf "https://tools.ietf.org/tools/${tool}/${tool}-${version}".tgz -o "$tmp"
sum=$(curl -sSLf "https://tools.ietf.org/tools/${tool}/distinfo" | \
          sed -e 's/SHA256 ('"${tool}-${version}"'.tgz) = //;t;d')
[ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sum" ]
target="/usr/local/bin/${tool}"
tar xzfO "$tmp" "${tool}-${version}/${tool}" >"$target"
chmod 755 "$target"
