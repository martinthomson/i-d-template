#!/usr/bin/env bash

# Usage: $0 <tagfile> <outputfile> [drafts ...]

drafts=("$@")
candidates=$(("${#drafts[@]}" * 5))

build_target() {
    tag="$1"
    target_name="$2"
    source_file=
    subst=()
    for file in $(git ls-tree --name-only "$tag" | grep '^draft-'); do
        [ "${file%.*}" = "${target_name%-*}" ] && source_file="${file}"
        # Find the tag for each file that is in the tree.
        file_tag=$(git describe --candidates="$candidates" --match "${file%.*}-*" --abbrev=0 "$tag" 2>/dev/null)
        subst+=(-e "s/${file%.*}-latest/${file%.*}-${file_tag:-00}/g")
    done
    if [ -z "$source_file" ]; then
        echo "No file for found at revision $tag for $target_name" 1>&2
        exit 1
    fi
    target="${target_name}.${source_file##*.}"
    echo ".INTERMEDIATE: ${target}"
    echo "${target}:"
    if [ "$tag" = HEAD ]; then
        echo -e "\tsed ${subst[@]} "$source_file" >\$@"
    else
        echo -e "\tgit show "$tag":"$source_file" | sed ${subst[@]} >\$@"
    fi
}

for draft in "${drafts[@]}"; do
    tags=($(git tag --list "${draft}-[0-9][0-9]"))
    for i in "${tags[@]}"; do
        build_target "$i" "$i"
    done
    if [ "${#tags[@]}" -gt 0 ]; then
        current="${tags[-1]##*-}"
        next_draft="${draft}-$(printf "%.2d" $(( 1$current - 99)))"
        build_target HEAD "$next_draft"

        # Write out a diff target
        echo "diff-${draft}.html: ${draft}-${current}.txt ${next_draft}.txt"
        echo -e "\t-\$(rfcdiff) --html --stdout \$^ > \$@"
    fi
done
