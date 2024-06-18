#!/usr/bin/env python3

import os
import os.path
import re
import sys
import xml
import xml.sax


def extract_md(filename):
    try:
        with open(filename, "r") as fh:
            section_header = fh.readline().strip()
            if section_header != r"%%%" and section_header != r"---":
                raise Exception(
                    'Unexpected first line in markdown file: got "{section_header}", expected `%%%` or `---`'
                )
            header_data = ""
            for line in fh:
                if line.strip() == section_header:
                    break
                header_data += line
            if section_header == r"---":
                try:
                    import yaml

                    return next(yaml.safe_load_all(header_data))
                except ImportError as err:
                    raise Exception(
                        "Unable to import python `yaml` library, needed for Kramdown processing"
                    ) from err
            if section_header == r"%%%":
                try:
                    import toml

                    return toml.loads(header_data)
                except ImportError as err:
                    raise Exception(
                        "Unable to import python `toml` library, needed for Mmark processing"
                    ) from err
    except Exception as err:
        return {}


def extract_xml(filename):
    parser = xml.sax.make_parser()
    handler = XmlHandler()
    parser.setContentHandler(handler)
    parser.parse(filename)
    return handler.metadata


class XmlHandler(xml.sax.handler.ContentHandler):
    interesting_elements = ["title", "area", "workgroup"]
    wsp = re.compile(r"\s+")

    def __init__(self):
        self.metadata = {}
        self.stack = []
        self.content = ""
        self.attrs = {}
        self.in_front = False

    def startElement(self, name, attrs):
        self.stack.append(name)
        self.attrs = attrs
        if self.stack == ["rfc", "front"]:
            self.in_front = True

    def endElement(self, name):
        pop_name = self.stack.pop()
        assert name == pop_name
        if self.in_front and pop_name == "front":
            self.in_front = False
        if self.in_front and name in self.interesting_elements:
            if name == "title" and self.attrs.get("abbrev", "").strip() != "":
                self.metadata["abbrev"] = self.attrs["abbrev"]
            self.metadata[name] = self.wsp.sub(" ", self.content.strip())
        self.content = ""
        self.attrs = {}

    def characters(self, data):
        self.content += data

    def processingInstruction(self, target, data):
        self.metadata[target.strip()] = data.strip()


extract_funcs = {".md": extract_md, ".xml": extract_xml}


if __name__ == "__main__":
    filename = sys.argv[1]
    target = sys.argv[2]
    if os.path.isfile(filename):
        fileext = os.path.splitext(filename)[1]
        extract_func = extract_funcs.get(fileext, lambda a: {})
        metadata = extract_func(filename)
        if target == "abbrev":
            value = metadata.get("abbrev", None)
            if value == None:
                value = metadata.get("title", "")
        else:
            value = metadata.get(target, "")
    else:
        value = ""
    print(value)
