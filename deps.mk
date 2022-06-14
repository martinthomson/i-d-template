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
# and they will be installed into a venv or virtual environment.  Tools are
# added to the path, so you should have no problem running them.
#
# For ruby, listing tools in a Gemfile will ensure that files are installed, but
# you need to execute them with `bundle exec` rather than calling them from the
# path.  You should add Gemfile.lock to your .gitignore file if you do this.
#
# For nodejs, new dependencies can be added to package.json (using `npm install
# -s <package>`) and run with `npx`.  You should add package-lock.json and
# node_modules/ to your .gitignore file if you do this.
#
# The plan is to put tools on the path properly, but this might take some time
# to refine.

DEPS_MARKER := .deps.txt
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
ifneq (,$(wildcard Gemfile))
DEPS_FILES += Gemfile.lock
Gemfile.lock: Gemfile
	bundle install --gemfile=$<
clean-deps::
	-rm -rf $(BUNDLE_PATH)
endif
ifneq (true,$(CI))
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
