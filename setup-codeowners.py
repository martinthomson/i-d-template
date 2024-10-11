#!/usr/bin/env python3

import os
import subprocess
import sys
import xml.sax


class GetAuthorsEmail(xml.sax.handler.ContentHandler):
    states = ["", "front", "author", "email"]

    def __init__(self):
        self.state = 0
        self.email = ""

    def startElement(self, tag, attributes):
        if (
            self.state + 1 < len(GetAuthorsEmail.states)
            and GetAuthorsEmail.states[self.state + 1] == tag.lower()
        ):
            self.state = self.state + 1

    def characters(self, content):
        if self.state + 1 == len(GetAuthorsEmail.states):
            self.email = self.email + content

    def endElement(self, tag):
        if tag.lower() != GetAuthorsEmail.states[self.state]:
            return
        if self.state + 1 == len(GetAuthorsEmail.states):
            print(f" {self.email.strip()}", end="")
            self.email = ""
        self.state = self.state - 1

    @staticmethod
    def get_emails(f):
        parser = xml.sax.make_parser()
        parser.setContentHandler(GetAuthorsEmail())
        parser.parse(f)
        print()


print("# Automatically generated CODEOWNERS")
print("# Regenerate with `make update-codeowners`")
if len(sys.argv) >= 2:
    sink = open(os.devnull, "wb")
    for f in sys.argv[1:]:
        cmd = f"git ls-tree --name-only @ {f.rpartition('.')[0]}.* | head -1"
        s = subprocess.check_output(
            cmd,
            shell=True,
            universal_newlines=True,
            encoding="utf-8",
            stderr=sink,
        ).strip()
        if s != "":
            print(s, end="")
            GetAuthorsEmail.get_emails(f)
else:
    GetAuthorsEmail.get_emails(sys.stdin)
