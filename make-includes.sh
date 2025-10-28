#!/usr/bin/env bash
# Create include dependencies for a given (versioned) file.
# This is a little crude, but it ensures that included content is accessible
# when constructing a versioned file.

LIBDIR=${LIBDIR:-lib}
# The source version. Either HEAD or in the form draft-ietf-whatever-05.
tag="$1"
# The target name is the versioned name.
# This will always be in the form draft-ietf-whatever-06,
# which is extrapolated if $tag == HEAD.
target_name="$2"
# The name of the versioned file that has been created.
filename="$3"

get_includes() {
    case "${2##*.}" in
        md|mkd)
            sed -ne '/^{::include [^\/]/{ s/^{::include versioned\/'"$1"'\///;s/}$//; p; }' "$2"
            ;;
    esac
}

for inc in $(get_includes "$target_name" "$filename"); do
    target="versioned/$target_name/$inc"
    mkdir -p $(dirname "$target")
    if ! git show "$tag:$inc" >"$target" 2>/dev/null; then
        echo "Attempting to make a copy of $inc" 1>&2
        if [ "$tag" = HEAD ]; then
            tmp=.
        else
            tmp="$(mktemp -d)"
            trap 'rm -rf "$tmp"' EXIT
            if git -c advice.detachedHead=false clone . -b "$tag" "$tmp"; then
                ln -s "$PWD/$LIBDIR" "$tmp/$LIBDIR"
            else
                tmp=.
            fi
        fi
        make -C "$tmp" "$inc" && cp "$tmp/$inc" "$target"
    fi
done
