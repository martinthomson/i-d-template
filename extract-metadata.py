#!/usr/bin/env python3

import os
import os.path
import sys
import xml
import xml.sax
import yaml


def extract_md(filename):
    try:
        with open(filename, "r") as fh:
            return next(yaml.safe_load_all(fh))
    except IOError:
        return {}
    except yaml.YAMLError:
        return {}


def extract_xml(filename):
    parser = xml.sax.make_parser()
    handler = PIHandler()
    parser.setContentHandler(handler)
    parser.parse(filename)
    return handler.pis


class PIHandler(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.pis = {}

    def processingInstruction(self, target, data):
        self.pis[target.strip()] = data.strip()


extract_funcs = {".md": extract_md, ".xml": extract_xml}


if __name__ == "__main__":
    filename = sys.argv[1]
    target = sys.argv[2]
    if os.path.isfile(filename):
        fileext = os.path.splitext(filename)[1]
        extract_func = extract_funcs.get(fileext, lambda a: {})
        frontmatter = extract_func(filename)
        value = frontmatter.get(target, "")
    else:
        value = ""
    print(value)
