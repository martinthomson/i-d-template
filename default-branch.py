#!/usr/bin/env python3
# Usage: $0 [gh-user] [gh-repo] [gh-token]

import os
import subprocess
import sys

if os.environ.get("DEFAULT_BRANCH") is not None:
    print(os.environ["DEFAULT_BRANCH"])
    exit(0)


def warn(m):
    print(f"warning: {sys.argv[0]}: {m}", file=sys.stderr)


def get_branch(rev):
    try:
        revparse = ["git", "rev-parse", "--abbrev-ref", rev]
        v = subprocess.check_output(revparse, stderr=open(os.devnull, "wb"))

        print(v.decode("utf-8").strip(" \r\n").split("/")[-1])
        exit(0)
    except subprocess.CalledProcessError:
        pass


remote = os.environ.get("GIT_REMOTE", default="origin")
get_branch(f"{remote}/HEAD")
get_branch(f"refs/remotes/{remote}/HEAD")

# We shouldn't get here...

if (
    len(sys.argv) < 3
    or os.environ.get("BRANCH_FETCH", default="true").lower() == "false"
):
    warn("unable to determine default branch")
    get_branch("HEAD")
    exit(1)

try:
    import requests
except ImportError:
    warn("need 'requests' to determine default branch")
    warn("    'pip3 install [--user] requests' to install")
    get_branch("HEAD")
    exit(1)


url = f"https://api.github.com/repos/{sys.argv[1]}/{sys.argv[2]}"
headers = {}
if len(sys.argv) >= 4:
    headers["Authorization"] = f"bearer {sys.argv[3]}"
response = requests.get(url, headers=headers)
response.raise_for_status()
result = response.json()

# Fix it
head = f"refs/remotes/{remote}/HEAD"
ref = f"refs/remotes/{remote}/{result['default_branch']}"
warn("correcting the default branch locally:")
warn(f"    git symbolic-ref {head} {ref}")
subprocess.check_output(["git", "symbolic-ref", head, ref])

# Report it
print(result["default_branch"])
