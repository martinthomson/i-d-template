#!/usr/bin/env bash
# Given a tag and a draft, attempt to work out who is responsible for the submission.
#
# This tries several things, starting from a simple UPLOAD_EMAIL environment variable.
# Then it looks at the email of the person that tagged the commit, if that is set.
# Then it starts looking for who made the commit or who authored the commit.
# For each of these, GitHub could use a <user>@users.noreply.github.com address.
# In which case, this attempts to use the GitHub API to get their email.
# Finally, this picks the first listed author email address from the draft.

tried=()
emailok() {
    tried+=("$1")
    if [ -n "$2" -a "$2" != "noreply@github.com" ]; then
        echo "$2"
        exit 0
    fi
}

# Exit on errors,
set -e
# ... but don't print anything; we're using tokens.
set +x

emailok "\$UPLOAD_EMAIL environment variable" "$UPLOAD_EMAIL"

tag="$1"
draft="$2"

for k in taggeremail committeremail authoremail; do
    tagger="$(git tag --list --format '%('"$k"')' "$tag" | sed -e 's/^<//;s/>$//')"
    ghuser="${tagger%@users.noreply.github.com}"
    if [ "$ghuser" = "$tagger" ]; then
        emailok "git $k" "$tagger"
    elif [ -n "$GITHUB_API_TOKEN" ]; then
        script="import json,sys
e=json.load(sys.stdin).get('email')
if isinstance(e, str): print(e)"
        userjson="$(curl -SsLf \
                    -H "Accept: application/vnd.github+json" \
                    -H "Authorization: Bearer $GITHUB_API_TOKEN" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    "https://api.github.com/users/$ghuser" 2>/dev/null)"
        apiok=$?
        emailok "github API for $k ($ghuser)" \
                "$([ "$apiok" -eq 0 ] && echo "$userjson" | python -c "$script" 2>/dev/null)"
    fi
done

if [ -n "$draft" ]; then
    emailok "draft author" "$(xmllint --xpath '/rfc/front/author[1]/address/email/text()' "$draft" 2>/dev/null)"
fi

# Give up
{
    echo "Unable to find email to use for submission."
    echo "Tried:"
    for t in "${tried[@]}"; do
        echo "    $t"
    done
} 1>&2
exit 1
