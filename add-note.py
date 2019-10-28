#!/usr/bin/env python3

import fileinput
import re

found = False
frontEnd = re.compile(" *</front>")
for line in fileinput.input():
    if not found:
        match = frontEnd.match(line)
        if match:
            found = True
            if match.start() > 0:
                print(line[: match.start()], end="")

            try:
                with fileinput.FileInput(files=(".note.xml")) as note:
                    for n in note:
                        print(n, end="")
            except:
                pass

            print(line[match.start() :], end="")
            continue

        # Don't add a note if there is one already.
        if line.find("</note>") >= 0:
            found = True

    print(line, end="")
