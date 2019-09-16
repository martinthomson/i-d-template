#!/usr/bin/env bash

mod=$1

fatal=0
if ! which pyang 2>&1 > /dev/null ; then
  echo "error in $0: pyang required; please install\n(pip install pyang)"
  fatal=1
fi

HAS_YANGLINT=1
if ! which yanglint 2>&1 > /dev/null ; then
  HAS_YANGLINT=0
fi

if [ "$fatal" != "0" ]; then
  exit 1
fi

set -e

if [ ! -d modules/ ]; then
  mkdir -p modules/
fi

before=$(ls modules/ | wc -l)
after=${before}
last=$((before-1))

echo "checking for module dependencies (downloading into modules/...)"
while [ "${last}" != "${after}" ]; do
  last=${after}
  for mod in ${all_modules}; do
    missing=$( ( pyang --verbose --path modules:. ${mod} 2>&1 || true ) | \
      grep "error: module" | \
      sed -e 's/.*: error: module "\([^"]*\)" not found in search path.*/\1/')
    if [ "$missing" != "" ]; then
      if ! which rsync 2>&1 > /dev/null ; then
        echo "error in $0: rsync required; please install"
      fi

      for mis in ${missing}; do
        bash -e -x -c "rsync -cvz rsync.iana.org::assignments/yang-parameters/${mis}*.yang modules/"
      done
    fi

    # sample:
    # err : Importing "ietf-routing-types" module into "ietf-dorms" failed.

    # unfortunately, you can't distinguish between missing and erroring,
    # so in particular when multiple local modules import each other but
    # the bottom one is missing things, skip pulling local stuff, and
    # instead re-check those.  TBD: set them up as dependencies?

    # TBD: maybe better to use yangcatalog.org to support I-D refs?
    # see, e.g.: 
    # https://www.yangcatalog.org/yang-search/module_details.php?module=ietf-crypto-types@2019-07-02.yang

    # unfortunately, yanglint and pyang might use different dependencies.
    # gotta check both.
    if [ "${HAS_YANGLINT}" = "1" ]; then
      missing=$( ( yanglint -f json -D -V -p . -p modules ${mod} 2>&1 || true ) | \
        grep "err : Importing " | \
        sed -e 's/err : Importing "\([^"]*\)" module .* failed./\1/')
      locals=""
      while [ -f ${missing}.yang ]; do
        already=0
        for loc in ${locals}; do
          if [ "${loc}" = "${missing}.yang" ]; then
            already=1
          fi
        done
        if [ "${already}" != "0" ]; then
          break
        fi
        locals="${locals} ${missing}.yang"
        missing=$( ( yanglint -f json -D -V -p . -p modules ${mod} 2>&1 || true ) | \
          grep "err : Importing " | \
          sed -e 's/err : Importing "\([^"]*\)" module .* failed./\1/')
      done
      if [ "$missing" != "" ]; then
        for mis in ${missing}; do
          if [ -f "$mis.yang" ]; then
            missing=$( ( yanglint -f json -D -V -p . -p modules ${mis}.yang 2>&1 || true ) | \
              grep "err : Importing " | \
              sed -e 's/err : Importing "\([^"]*\)" module .* failed./\1/')
            break
          fi
        done

        if ! which rsync 2>&1 > /dev/null ; then
          echo "error in $0: rsync required; please install"
        fi
        for mis in ${missing}; do
          bash -e -x -c "rsync -cvz rsync.iana.org::assignments/yang-parameters/${mis}*.yang modules/"
        done
      fi
    fi
  done
  after=$(ls modules/ | wc -l)
done

