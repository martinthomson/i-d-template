## Identify drafts, types and versions

drafts := $(sort $(basename $(wildcard $(foreach pattern,? *-[-a-z]? *-?[a-z] *[a-z0-9]??,$(foreach ext,xml org md,draft-$(pattern).$(ext))))))

ifeq (,$(drafts))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

draft_types := $(foreach draft,$(drafts),$(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml))))

f_prev_tag = $(shell git tag | grep '$(draft)-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
f_next_tag = $(if $(f_prev_tag),$(shell printf "%.2d" $$(( 1$(f_prev_tag) - 99)) ),00)
drafts_next := $(foreach draft,$(drafts),$(draft)-$(f_next_tag))
drafts_prev := $(foreach draft,$(drafts),$(draft)-$(f_prev_tag))

drafts_txt := $(addsuffix .txt,$(drafts))
drafts_html := $(addsuffix .html,$(drafts))
drafts_next_txt := $(addsuffix .txt,$(drafts_next))
drafts_prev_txt := $(addsuffix .txt,$(drafts_prev))

# CI config
CI_BRANCH = $(TRAVIS_BRANCH)$(CIRCLE_BRANCH)
CI_USER = $(patsubst /%,,$(TRAVIS_BRANCH))$(CIRCLE_PROJECT_USERNAME)
CI_REPO = $(patsubst %/,,$(TRAVIS_BRANCH))$(CIRCLE_PROJECT_REPONAME)
CI_REPO_FULL = $(CI_USER)/$(CI_REPO)
ifneq (,$(TRAVIS_PULL_REQUEST)$(CI_PULL_REQUESTS))
  CI_IS_PR = true
else
  CI_IS_PR = false
endif

# Github guesses
ifndef CI_REPO_FULL
GITHUB_REPO_FULL := $(shell git ls-remote --get-url | sed -e 's/^.*github\.com.//;s/\.git$$//')
GITHUB_USER := $(word 1,$(subst /, ,$(GITHUB_REPO_FULL)))
GITHUB_REPO := $(word 2,$(subst /, ,$(GITHUB_REPO_FULL)))
else
GITHUB_REPO_FULL := $(CI_REPO_FULL)
GITHUB_USER := $(CI_USER)
GITHUB_REPO:= $(CI_REPO)
endif

