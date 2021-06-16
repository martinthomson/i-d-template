# The following tools are used by this file.
# All are assumed to be on the path, but you can override these
# in the environment, or command line.

ifneq (,$(USE_DOCKER))
XML2RFC_REFCACHEDIR := /id/.cache/xml2rfc
KRAMDOWN_REFCACHEDIR := $(XML2RFC_REFCACHEDIR)
IMAGE := ghcr.io/larseggert/i-d-toolchain:latest
DOCKER := docker run \
		--env XML2RFC_REFCACHEDIR=${XML2RFC_REFCACHEDIR} \
		--env KRAMDOWN_REFCACHEDIR=${KRAMDOWN_REFCACHEDIR} \
		--volume ${CURDIR}:/id:delegated \
		--interactive \
		--cap-add=SYS_ADMIN ${IMAGE}
endif

# Mandatory:
#   https://pypi.python.org/pypi/xml2rfc
XML2RFC_RFC_BASE_URL := https://datatracker.ietf.org/doc/html/
XML2RFC_ID_BASE_URL := https://datatracker.ietf.org/doc/html/
xml2rfc ?= ${DOCKER} xml2rfc -q -s 'Setting consensus="true" for IETF STD document' --rfc-base-url $(XML2RFC_RFC_BASE_URL) --id-base-url $(XML2RFC_ID_BASE_URL)
# Tell kramdown not to generate targets on references so the above takes effect.
KRAMDOWN_NO_TARGETS := true
export KRAMDOWN_NO_TARGETS
KRAMDOWN_PERSISTENT := true
export KRAMDOWN_PERSISTENT

# If you are using markdown files use either kramdown-rfc2629 or mmark
#   https://github.com/cabo/kramdown-rfc2629
kramdown-rfc2629 ?= ${DOCKER} kramdown-rfc2629

#  mmark (https://github.com/miekg/mmark)
mmark ?= ${DOCKER} mmark

# If you are using outline files:
#   https://github.com/Juniper/libslax/tree/master/doc/oxtradoc
oxtradoc ?= oxtradoc.in

# When using rfc2629.xslt extensions:
#   https://greenbytes.de/tech/webdav/rfc2629xslt.html
xsltproc ?= ${DOCKER} xsltproc

# For sanity checkout your draft:
#   https://tools.ietf.org/tools/idnits/
idnits ?= ${DOCKER} idnits

# For diff:
#   https://tools.ietf.org/tools/rfcdiff/
rfcdiff ?= ${DOCKER} rfcdiff

# For generating PDF:
#   https://www.gnu.org/software/enscript/
enscript ?= ${DOCKER} enscript
#   http://www.ghostscript.com/
ps2pdf ?= ${DOCKER} ps2pdf

# Where to get references
XML_RESOURCE_ORG_PREFIX ?= https://xml2rfc.tools.ietf.org/public/rfc

# This is for people running macs
SHELL := ${DOCKER} bash

python ?= ${DOCKER} /usr/bin/env python3

# For uploading draft "releases" to the datatracker.
curl ?= ${DOCKER} curl -sS
DATATRACKER_UPLOAD_URL ?= https://datatracker.ietf.org/api/submit

# The type of index that is created for gh-pages.
# Supported options are 'html' and 'md'.
INDEX_FORMAT ?= html

# For spellchecking: pip install --user codespell
codespell ?= ${DOCKER} codespell

# Setup a shared cache for xml2rfc and kramdown-rfc2629
ifeq (,$(KRAMDOWN_REFCACHEDIR))
XML2RFC_REFCACHEDIR ?= $(HOME)/.cache/xml2rfc
KRAMDOWN_REFCACHEDIR := $(XML2RFC_REFCACHEDIR)
else
XML2RFC_REFCACHEDIR ?= $(KRAMDOWN_REFCACHEDIR)
endif
xml2rfc += --cache=$(XML2RFC_REFCACHEDIR)
ifneq (,$(shell mkdir -p $(KRAMDOWN_REFCACHEDIR)))
$(info Created cache directory at $(KRAMDOWN_REFCACHEDIR))
endif
export KRAMDOWN_REFCACHEDIR
