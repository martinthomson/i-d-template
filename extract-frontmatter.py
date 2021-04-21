#!/usr/bin/env python3

import sys
import yaml

def extract(filename):
    try:
        with open(filename, 'r') as fh:
            return next(yaml.safe_load_all(fh))
    except IOError:
        return {}
    except yaml.YAMLError:
        return {}

if __name__ == "__main__":
    frontmatter = extract(sys.argv[1])
    value = frontmatter.get(sys.argv[2], '')
    print(value)
