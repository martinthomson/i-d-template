#!/usr/bin/env bash
# Build extra targets for make.  This includes targets that are a little tricky
# to build.  This includes all versions of the draft other than the latest: all
# tagged versions and the next version for submission.  As a result, it also
# includes diffs.

# Usage: $0 <tagfile> <outputfile> [drafts ...]

drafts=("$@")
candidates=$((${#drafts[@]} * 5))

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
            prev_file_tag=$(git describe --candidates="$candidates" --tags \
                                --match "${file%.*}-*" --abbrev=0 "$tag" 2>/dev/null)

            # No previous: -00, building for HEAD: next, otherwise use tag.
            if [ -n "$prev_file_tag" ]; then
                file_tag="${file%.*}-00"
            elif [ "$tag" = HEAD -a -n "$prev_file_tag" ]; then
                file_tag=$(next "$prev_file_tag")
            else
                file_tag="$prev_file_tag"
            fi
        fi
        subst+=(-e "s/${file%.*}-latest/${file_tag}/g")
    done

    if [ -z "$source_file" ]; then
        echo "warning: No file found at revision $tag for $target_name" 1>&2
        return
    fi

    target="${target_name}.${source_file##*.}"
    if [ "$tag" == HEAD ]; then
        echo "${target}: ${source_file}"
        echo -e "\tsed ${subst[@]} \$< >\$@"
    else
        echo ".INTERMEDIATE: ${target}"
        echo "${target}:"
        echo -e "\tgit show "$tag":"$source_file" | sed ${subst[@]} >\$@"
    fi
}

for draft in "${drafts[@]%.*}"; do
    tags=($(git tag --list "${draft}-[0-9][0-9]"))
    for i in "${tags[@]}"; do
        build_target "$i" "$i"
    done

    if [ "${#tags[@]}" -gt 0 ]; then
        next_draft=$(next "${tags[$((${#tags[@]}-1))]}")
    else
        next_draft="${draft}-00"
    fi
    build_target HEAD "$next_draft"

    if [ "${#tags[@]}" -gt 0 ]; then
        # Write out a diff target
        echo "diff-${draft}.html: ${tags[$((${#tags[@]}-1))]}.txt ${next_draft}.txt"
        echo -e "\t-\$(rfcdiff) --html --stdout \$^ > \$@"
    fi
done
