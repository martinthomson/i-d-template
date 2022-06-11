## Installed dependencies
DEPS_MARKER := .deps.txt
DEPS_FILES :=
.PHONY: deps clean-deps update-deps

# Python
VENVDIR ?= $(LIBDIR)/.venv
REQUIREMENTS_TXT := $(wildcard requirements.txt)
ifneq (true,$(CI))
REQUIREMENTS_TXT += $(LIBDIR)/requirements.txt
endif
ifneq (,$(strip $(REQUIREMENTS_TXT)))
include $(LIBDIR)/venv.mk
DEPS_FILES += $(VENV)/$(MARKER)
export PATH := $(VENV):$(PATH)
clean-deps:: clean-venv
endif
ifneq (true,$(CI))
export VENV
python := $(VENV)/python
xml2rfc := $(VENV)/xml2rfc $(xml2rfcargs)
else
python := python3
xml2rfc := xml2rfc $(xml2rfcargs)
endif

# Ruby
ifneq (true,$(CI))
export BUNDLE_PATH ?= $(abspath $(LIBDIR)/.gems)
kramdown-rfc ?= bundle exec --gemfile=$(LIBDIR)/Gemfile kramdown-rfc
DEPS_FILES += $(LIBDIR)/Gemfile.lock
$(LIBDIR)/Gemfile.lock: $(LIBDIR)/Gemfile
	bundle install --gemfile=$<
clean-deps::
	-rm -rf $(BUNDLE_PATH)
else
kramdown-rfc ?= kramdown-rfc
endif

# Nodejs
ifneq (true,$(CI))
ifneq (,$(wildcard package.json))
DEPS_FILES += package-lock.json
package-lock.json: package.json
	npm install
clean-deps::
	-rm -rf package-lock.json
endif
endif

# Link everything up
$(DEPS_MARKER): $(DEPS_FILES)
deps:: $(DEPS_FILES)
	@touch $(DEPS_FILES)
update-deps::
	-rm -f $(DEPS_FILES)
clean-deps:: update-deps
