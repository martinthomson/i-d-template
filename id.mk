## Identify drafts, types and versions

ifneq (,$(shell git submodule status $(LIBDIR) 2>/dev/null))
SUBMODULE = true
endif

drafts := $(sort $(basename $(wildcard $(foreach pattern,? *-[-a-z]? *-?[a-z] *[a-z0-9]??,$(foreach ext,xml org md,draft-$(pattern).$(ext))))))

ifeq (0,$(words $(drafts)))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Create a draft file before running make)
endif

draft_types := $(foreach draft,$(drafts),\
		   $(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml))))

f_prev_tag = $(shell git tag 2>/dev/null | grep '$(draft)-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
f_next_tag = $(if $(f_prev_tag),$(shell printf "%.2d" $$(( 1$(f_prev_tag) - 99)) ),00)
drafts_next := $(foreach draft,$(drafts),$(draft)-$(f_next_tag))
drafts_prev := $(foreach draft,$(drafts),$(draft)-$(f_prev_tag))

drafts_txt := $(addsuffix .txt,$(drafts))
drafts_html := $(addsuffix .html,$(drafts))
drafts_xml := $(addsuffix .xml,$(drafts))
drafts_next_txt := $(addsuffix .txt,$(drafts_next))
drafts_next_xml := $(addsuffix .xml,$(drafts_next))
drafts_prev_txt := $(addsuffix .txt,$(drafts_prev))

# CI config
CI ?= false
CI_BRANCH = $(TRAVIS_BRANCH)$(CIRCLE_BRANCH)
CI_USER = $(word 1,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_USERNAME)
CI_REPO = $(word 2,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_REPONAME)
ifeq (true,$(CI))
CI_REPO_FULL = $(CI_USER)/$(CI_REPO)
endif
ifeq (false,$(TRAVIS_PULL_REQUEST))
CI_TRAVIS_PR = false
else
CI_TRAVIS_PR = true
endif
CI_IS_PR = $(if $(CI_PULL_REQUESTS),true,$(CI_TRAVIS_PR))

# Github guesses
GIT_REMOTE ?= origin
ifndef CI_REPO_FULL
GITHUB_REPO_FULL := $(shell git ls-remote --get-url $(GIT_REMOTE) 2>/dev/null |\
			sed -e 's/^.*github\.com.//;s/\.git$$//')
GITHUB_USER := $(word 1,$(subst /, ,$(GITHUB_REPO_FULL)))
GITHUB_REPO := $(word 2,$(subst /, ,$(GITHUB_REPO_FULL)))
else
GITHUB_REPO_FULL := $(CI_REPO_FULL)
GITHUB_USER := $(CI_USER)
GITHUB_REPO:= $(CI_REPO)
endif
