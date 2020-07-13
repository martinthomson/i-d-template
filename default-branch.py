#!/usr/bin/env python3
# Usage: $0 [gh-user] [gh-repo]

import sys
import requests

url = "https://api.github.com/repos/" + sys.argv[1] + "/" + sys.argv[2]

response = requests.get(url)
response.raise_for_status()
result = response.json()

print(result["default_branch"])
