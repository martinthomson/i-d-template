#!/usr/bin/env bash

input_md=$1

if [ ! -f "$input_md" ] ; then
  echo "usage: $0 <input.md> :"
  echo "  inserts yang into input.md"
  echo "    YANG-MODULE <mod.yang> (inserts module)"
  echo "    YANG-TREE <mod.yang> (builds tree view and inserts it)"
  echo "    YANG-DATA <mod.yang> <example.json> (inserts example.json)"
  echo "error: no input file: '$input_md'"
  exit 1
fi

modules=$(grep YANG-MODULE $input_md | awk '{print $2;}' | tr "\n" " ")
tree_modules=$(grep YANG-TREE $input_md | awk '{print $2;}' | tr "\n" " ")
data_modules_str=$(grep YANG-DATA $input_md | awk '{print $2;}' | tr "\n" " ")

if [ "$modules" = "" -a "$data_modules_str" = "" -a "$tree_modules" = "" ]; then
  if [ -f "$input_md.yangdeps" ]; then
    echo "" > $input_md.yangdeps
  fi
  exit 0
fi

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

echo "${target_xml}: ${all_modules} ${data_json_str}" > ${input_md}.yangdeps

fatal=0
if ! which pyang 2>&1 > /dev/null ; then
  echo "error in $0: pyang required; please install\n(pip install pyang)"
  fatal=1
fi

if ! which python3 2>&1 > /dev/null ; then
  echo "error in $0: python3 required; please install"
  fatal=1
fi

if [ "$fatal" != "0" ]; then
  exit 1
fi

echo "generating ${input_md}.withyang"
python3 lib/yang-inject.py ${input_md} || exit 1

