# The following tools are used by this file.
# All are assumed to be on the path, but you can override these
# in the environment, or command line.

# Mandatory:
#   https://pypi.python.org/pypi/xml2rfc
xml2rfc ?= xml2rfc -q

# If you are using markdown files use either kramdown-rfc2629 or mmark
#   https://github.com/cabo/kramdown-rfc2629
kramdown-rfc2629 ?= kramdown-rfc2629

#  mmark (https://github.com/miekg/mmark)
mmark ?= mmark

# If you are using outline files:
#   https://github.com/Juniper/libslax/tree/master/doc/oxtradoc
oxtradoc ?= oxtradoc.in

# For sanity checkout your draft:
#   https://tools.ietf.org/tools/idnits/
idnits ?= idnits

# For diff:
#   https://tools.ietf.org/tools/rfcdiff/
rfcdiff ?= rfcdiff

# For generating PDF:
#   https://www.gnu.org/software/enscript/
enscript ?= enscript
#   http://www.ghostscript.com/
ps2pdf ?= ps2pdf

# Where to get references
# Use http://xml2rfc.tools.ietf.org/public/rfc if this fails.
XML_RESOURCE_ORG_PREFIX ?= https://xml2rfc.tools.ietf.org/public/rfc

# This is for people running macs
SHELL := bash
