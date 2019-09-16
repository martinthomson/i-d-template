#!/usr/bin/env bash

input_md=$1

if [ ! -f "$input_md" ] ; then
  echo "usage: $0 <input.md> :"
  echo "  inserts yang into input.md+validates if VALIDATE_YANG=1"
  echo "    YANG-MODULE <mod.yang> (pyang lint)"
  echo "    YANG-TREE <mod.yang> (pyang lint)"
  echo "    YANG-DATA <mod.yang> <example.json> (yanglint validate json)"
  echo "  uses rsync to download imported modules to modules/ from iana"
  echo "error: no input file: '$input_md'"
  exit 1
fi

modules=$(grep YANG-MODULE $input_md | awk '{print $2;}' | tr "\n" " ")
tree_modules=$(grep YANG-TREE $input_md | awk '{print $2;}' | tr "\n" " ")
data_modules_str=$(grep YANG-DATA $input_md | awk '{print $2;}' | tr "\n" " ")

data_json_str="$(grep YANG-DATA $input_md | awk '{print $3;}' | tr "\n" " ")"
all_modules="$(echo "$modules $tree_modules $data_modules_str" | tr " " "\n" | sort | uniq | tr "\n" " " | sed -e 's/^ *//' | sed -e 's/ *$//')"

data_jsons=(); for d in $data_json_str; do data_jsons+=("$d"); done
data_modules=(); for d in $data_modules_str; do data_modules+=("$d"); done

#echo "input=$input_md, data='${#data_jsons[@]}: $data_jsons', mods='$all_modules'"

had_error=0

target_xml="$(echo ${input_md} | sed -e 's/.md$/.xml/')"
for ((i=0; i < ${#data_jsons[@]}; i++)); do
  if [ ! -f "${data_jsons[i]}" ]; then
    echo "no example data file ${data_jsons[i]}"
    had_error=1
  fi
done
for mod in ${all_modules}; do
  if [ ! -f ${mod} ]; then
    echo "no module file ${mod}"
    had_error=1
  fi
done

if [ "${had_error}" != "0" ]; then
  echo "error: some files not found, exiting"
  exit 1
fi

fatal=0
if ! which pyang 2>&1 > /dev/null ; then
  echo "error in $0: pyang required; please install\n(pip install pyang)"
  fatal=1
fi

if ! which yanglint 2>&1 > /dev/null ; then
  echo "error in $0: yanglint required; please install libyang:"
  echo "(install libyang-dev or equivalent if available, or build:)"
  echo " git clone https://github.com/CESNET/libyang"
  echo " mkdir libyang/build"
  echo " pushd libyang/build"
  echo " cmake .."
  echo " make && sudo make install"
  echo " popd"
  echo " yanglint --help"
  echo "if it can't load libyang.so, try something like:"
  echo " cmake -DCMAKE_INSTALL_PREFIX=$$HOME/local-installs -DCMAKE_INSTALL_RPATH=$$HOME/local-installs/lib .."
  fatal=1
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
  done
  after=$(ls modules/ | wc -l)
done

echo "checking modules..."
for mod in ${all_modules}; do
  if ! bash -x -e -c "pyang -E --verbose --ietf --lint --max-line-length 72 --path modules:. ${mod}" ; then
    had_error=1
  fi
done

echo "checking examples..."
for ((i=0; i < ${#data_modules[@]} && i < ${#data_jsons[@]}; i++)); do
  # TBD: ideally, yanglint would have a "treat warnings as errors" mode,
  #   which ideally would be used here.
  # TBD: ideally, also iana-if-type@2019-07-16.yang would not contain
  #   a redundant version that always reports this warning:
  # warn: Module's revisions are not unique (2018-06-28).
  bash -x -e -c "yanglint -f json -t data -D -s -V -p modules -p . -o /dev/null ${data_modules[i]} ${data_jsons[i]}" 2>&1 | grep -v "warn: Module's revisions are not unique (2018-06-28)"
  if [ "${PIPESTATUS[0]}" != "0" ]; then
    had_error=1
  fi
done

if [ "${had_error}" != "0" ]; then
  echo "encountered yang errors in ${input_md}"
  exit 1
fi
echo "yang passed checks in ${input_md}"

