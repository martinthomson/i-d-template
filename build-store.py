#!/usr/bin/env python3
# Keep a copy of the current build of each draft on the pages branch, so that
# diff.html can compare any two builds in the browser.
#
# usage: build-store.py <builds-dir> <ttl-days> <draft>.txt...
#
# Each <draft>.txt is copied to <builds-dir>/<draft>-<commit>.txt, where
# <commit> is the abbreviated hash of HEAD in the source repository (the
# current directory). <builds-dir>/index.json lists the stored builds, newest
# first, with the date and subject of the source commit. Builds whose commit
# is older than <ttl-days> are removed, along with their files.
#
# Copies of a build share their blob with the draft text committed next to
# them, so storing them costs a tree entry, not a second copy of the text.

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone


def main(argv):
    if len(argv) < 3:
        sys.exit('usage: build-store.py <builds-dir> <ttl-days> <draft>.txt...')
    builds_dir, ttl_days, drafts = argv[0], int(argv[1]), argv[2:]
    index_file = os.path.join(builds_dir, 'index.json')

    head = subprocess.run(
        ['git', 'log', '-1', '--format=%h%x00%ct%x00%s', 'HEAD'],
        capture_output=True, text=True, check=True,
    ).stdout.rstrip('\n').split('\0')
    sha, timestamp, subject = head[0], int(head[1]), head[2]

    try:
        with open(index_file) as f:
            builds = json.load(f)['builds']
    except (OSError, ValueError, KeyError):
        builds = []
    builds = [b for b in builds if b.get('sha') != sha]

    os.makedirs(builds_dir, exist_ok=True)
    names = []
    for draft in drafts:
        name = os.path.basename(draft)[:-len('.txt')]
        shutil.copyfile(draft, os.path.join(builds_dir, f'{name}-{sha}.txt'))
        names.append(name)
    builds.insert(0, {
        'sha': sha,
        'date': datetime.fromtimestamp(timestamp, timezone.utc).strftime('%Y-%m-%d'),
        'timestamp': timestamp,
        'subject': subject[:80],
        'drafts': names,
    })

    cutoff = int((datetime.now(timezone.utc) - timedelta(days=ttl_days)).timestamp())
    kept = []
    for b in builds:
        if b.get('timestamp', cutoff) >= cutoff:
            kept.append(b)
            continue
        for name in b.get('drafts', []):
            try:
                os.remove(os.path.join(builds_dir, f"{name}-{b['sha']}.txt"))
            except OSError:
                pass

    with open(index_file, 'w') as f:
        json.dump({'builds': kept}, f, indent=1)
        f.write('\n')


if __name__ == '__main__':
    main(sys.argv[1:])
