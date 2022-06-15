## Installed dependencies
# This framework will automatically install build-time dependencies as a
# prerequisite for build targets.  This installation uses local directors
# (usually under lib/) to store all installed software.
#
# Some dependencies are defined in the framework and will always be installed.
# This includes xml2rfc and kramdown-rfc.  Other dependencies are specific to a
# particular project and will be driven from files that are in the project
# repository.
#
# Currently, this supports three different package installation frameworks:
# * pip for python, specified in requirements.txt
# * gem for ruby, specified in Gemfile
# * npm for nodejs, specified in package.json
# Each system has its own format for specifying dependencies.  What you need to
# know is that if you include any of the above files, you don't need to worry
# about ensuring that these tools are available when a build runs.
#
# This also works in CI runs, with caching, so your builds won't run too slowly.
# The prerequsites that are installed for all users are installed globally in a
# CI docker image, which is faster, so there are some minor differences in how
# CI and local runs operate.
#
# For python, if you have some extra tools, just add them to requirements.txt
# and they will be installed into a venv or virtual environment.
#
# For ruby, listing tools in a `Gemfile` will ensure that files are installed.
# You should add `Gemfile.lock` to your .gitignore file if you do this.
#
# For nodejs, new dependencies can be added to `package.json`.  Use `npm install
# -s <package>` to add files.  You should add `package-lock.json` and
# `node_modules/` to your `.gitignore` file if you do this.
#
# Tools are added to the path, so you should have no problem running them.

DEPS_FILES :=
.PHONY: deps clean-deps update-deps

# Python
VENVDIR ?= $(realpath $(LIBDIR))/.venv
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
rfc-tidy := $(VENV)/rfc-tidy
else
python ?= python3
xml2rfc ?= xml2rfc $(xml2rfcargs)
rfc-tidy ?= rfc-tidy
endif

# Ruby
export BUNDLE_PATH ?= $(realpath $(LIBDIR))/.gems
# Install binaries to somewhere sensible instead of .../ruby/$v/bin where $v
# doesn't even match the current ruby version.
export BUNDLE_BIN := $(BUNDLE_PATH)/bin
export PATH := $(BUNDLE_BIN):$(PATH)
ifneq (,$(wildcard Gemfile))
DEPS_FILES += Gemfile.lock
Gemfile.lock: Gemfile
	bundle install --gemfile=$<
clean-deps::
	-rm -rf $(BUNDLE_PATH)
ifeq (Gemfile.lock,$(wildcard $(BUNDLE_PATH) Gemfile.lock))
$(warning Missing gems in '$(BUNDLE_PATH)', forcing reinstall$(shell touch Gemfile))
endif
endif
ifneq (true,$(CI))
DEPS_FILES += $(LIBDIR)/Gemfile.lock
$(LIBDIR)/Gemfile.lock: $(LIBDIR)/Gemfile
	bundle install --gemfile=$<
clean-deps::
	-rm -rf $(BUNDLE_PATH)
ifeq ($(LIBDIR)/Gemfile.lock,$(wildcard $(BUNDLE_PATH) $(LIBDIR)/Gemfile.lock))
$(warning Missing gems in '$(BUNDLE_PATH)', forcing reinstall$(shell touch $(LIBDIR)/Gemfile))
endif
endif

# Nodejs
ifneq (,$(wildcard package.json))
export PATH := $(abspath node_modules/.bin):$(PATH)
DEPS_FILES += package-lock.json
package-lock.json: package.json
	npm install
clean-deps::
	-rm -rf package-lock.json
endif

# Link everything up
deps:: $(DEPS_FILES)
update-deps::
	-rm -f $(DEPS_FILES)
clean-deps:: update-deps
