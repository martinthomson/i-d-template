# The following tools are used by this file.
# All are assumed to be on the path, but you can override these
# in the environment, or command line.

# Set XML2RFCV3 to "true" to use the xml2rfc v3 path, described at
# https://tools.ietf.org/src/xml2rfc/trunk/cli/doc/xml2rfc3.html.
XML2RFCV3 ?= false

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

# When using rfc2629.xslt extensions:
#   https://greenbytes.de/tech/webdav/rfc2629xslt.html
xsltproc ?= xsltproc

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
XML_RESOURCE_ORG_PREFIX ?= https://xml2rfc.tools.ietf.org/public/rfc

# This is for people running macs
SHELL := bash

# For uploading draft "releases" to the datatracker.
curl ?= curl -sS
DATATRACKER_UPLOAD_URL ?= https://datatracker.ietf.org/api/submit
