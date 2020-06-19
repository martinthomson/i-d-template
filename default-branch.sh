#!/usr/bin/env bash
# Usage: $0 [remote]
# Get the name of the remote HEAD for the named remote (default: origin).

origin="${1:-${GIT_REMOTE:-origin}}"
branch=$(git rev-parse --abbrev-ref "$origin/HEAD" 2>/dev/null)
if [[ "$branch" == "$origin/HEAD" ]]; then
    # If $origin doesn't exist, then the above rev-parse will fail, but that is
    # OK.  We can let git remote report the error.
    set -e
    git remote set-head -a "$origin" 2>/dev/null 1>&2
    branch=$(git rev-parse --abbrev-ref "$origin/HEAD" 2>/dev/null)
fi
echo "${branch##*/}"
