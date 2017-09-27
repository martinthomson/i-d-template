#!/usr/bin/env bash

# Usage: $0 <tagfile> <outputfile> [drafts ...]

drafts=("$@")
candidates=$(("${#drafts[@]}" * 5))

next() {
    printf "${1%-*}-%2.2d" $((1${1##*-} - 99))
}

# This builds a make target for a specific tag.
build_target() {
    tag="$1"
    target_name="$2"
    source_file=
    subst=()
    for file in $(git ls-tree --name-only "$tag" | grep '^draft-'); do
        if [ "${file%.*}" = "${target_name%-*}" ]; then
            source_file="$file"
            file_tag="$target_name"
        else
            # This is the last tag for the identified file at the tag we're
            # interested in.
            prev_file_tag=$(git describe --candidates="$candidates" \
                                --match "${file%.*}-*" --abbrev=0 "$tag" 2>/dev/null)

            # If we are building for HEAD, then we need to use the next tag.
            if [ "$tag" = HEAD ]; then
                file_tag=$(next "$prev_file_tag")
            else
                file_tag="${prev_file_tag:-${file%.*}-00}"
            fi
        fi
        subst+=(-e "s/${file%.*}-latest/${file_tag}/g")
    done

    if [ -z "$source_file" ]; then
        echo "warning: No file for found at revision $tag for $target_name" 1>&2
        return
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
        next_draft=$(next "${tags[-1]}")
    else
        next_draft="${draft}-00"
    fi
    build_target HEAD "$next_draft"

    if [ "${#tags[@]}" -gt 0 ]; then
        # Write out a diff target
        echo "diff-${draft}.html: ${tags[-1]}.txt ${next_draft}.txt"
        echo -e "\t-\$(rfcdiff) --html --stdout \$^ > \$@"
    fi
done
