## Installed dependencies
.PHONY: deps update-deps
deps::
update-deps::

# Python
VENVDIR ?= $(LIBDIR)/.venv
REQUIREMENTS_TXT := $(wildcard requirements.txt)
ifneq (true,$(CI))
REQUIREMENTS_TXT += $(LIBDIR)/requirements.txt
endif
ifneq (,$(strip $(REQUIREMENTS_TXT)))
include $(LIBDIR)/venv.mk
deps:: venv
export PATH := $(VENV):$(PATH)
ifneq (true,$(CI))
update-deps::
	-rm -f $(VENV)/$(MARKER)
export VENV
python := $(VENV)/python
xml2rfc := $(VENV)/xml2rfc $(xml2rfcargs)
else
python := python3
xml2rfc := xml2rfc $(xml2rfcargs)
endif
endif

# Ruby
ifneq (true,$(CI))
export BUNDLE_PATH ?= $(abspath $(LIBDIR)/.gems)
deps:: $(LIBDIR)/Gemfile.lock
$(LIBDIR)/Gemfile.lock: $(LIBDIR)/Gemfile
	bundle install --gemfile=$<
update-deps::
	-rm -f $(LIBDIR)/Gemfile.lock
endif

# Nodejs
ifneq (true,$(CI))
ifneq (,$(wildcard package.json))
deps:: package-lock.json
package-lock.json: package.json
	npm install
update-deps::
	-rm -f package-lock.json
endif
endif
