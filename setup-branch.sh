#!/usr/bin/env bash

set -e

branch="$1"
shift

if git show-ref -s "$branch" >/dev/null 2>&1; then
    echo "The $branch branch already exists, skipping setup."
    exit
fi

tmp=$(mktemp -d /tmp/init-branch-"$branch"-XXXXX)
function cleanup() {
    rm -rf "$tmp"
}
trap cleanup ERR EXIT

echo "Initializing $branch branch"
git clone -n . "$tmp"
git -C "$tmp" checkout -q --orphan "$branch"
git -C "$tmp" rm -rfq .

echo Creating .gitignore and initial files
echo lib > "$tmp"/.gitignore
echo venv >> "$tmp"/.gitignore
echo .refcache >> "$tmp"/.gitignore
for f in "$@"; do
    touch "$tmp"/"$f"
done

echo Commit and push to origin/"$branch"
user=()
git config --global --get user.name >/dev/null || user+=(-c user.name='ID Bot')
git config --global --get user.email >/dev/null || user+=(-c user.email='idbot@example.com')

git -C "$tmp" add .gitignore "$@"
git -C "$tmp" "${user[@]}" commit -m "Automatic setup of $branch."
git -C "$tmp" push origin "$branch"
git push --set-upstream origin "$branch"
