## Identify drafts, types and versions

drafts := $(sort $(basename $(wildcard $(foreach pattern,? *-[-a-z]? *-?[a-z] *[a-z0-9]??,$(foreach ext,xml org md,draft-$(pattern).$(ext))))))

ifeq (0,$(words $(drafts)))
drafts := $(sort $(basename $(wildcard rfc[0-9]*.xml)))
endif

ifeq (0,$(words $(drafts)))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Create a draft file before running make)
endif

draft_types := $(foreach draft,$(drafts),\
		   $(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml))))
drafts_source := $(join $(drafts),$(draft_types))

drafts_tags := $(shell git tag --sort=refname 2>/dev/null | grep '^draft-')
f_prev_tag = $(lastword $(subst -, ,$(lastword $(filter $(draft)-%,$(drafts_tags)))))
f_next_tag = $(if $(f_prev_tag),$(shell printf "%.2d" $$(( 1$(f_prev_tag) - 99)) ),00)
drafts_next := $(foreach draft,$(drafts),$(draft)-$(f_next_tag))
drafts_prev := $(foreach draft,$(drafts),$(draft)-$(f_prev_tag))
drafts_with_prev := $(foreach draft,$(drafts),$(if $(f_prev_tag),$(draft)))

drafts_txt := $(addsuffix .txt,$(drafts))
drafts_html := $(addsuffix .html,$(drafts))
drafts_xml := $(addsuffix .xml,$(drafts))
drafts_next_txt := $(addsuffix .txt,$(drafts_next))
drafts_next_xml := $(addsuffix .xml,$(drafts_next))
drafts_prev_txt := $(addsuffix .txt,$(drafts_prev))

last_modified = $$(stat $$([ $$(uname -s) = Darwin ] && echo -f '%m' || echo -c '%Y') $(1))
last_commit = $$(git rev-list -n 1 --timestamp $(1) -- $(2) | sed -e 's/ .*//')

# CI config
CI ?= false
CI_USER ?= $(word 1,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_USERNAME)
CI_REPO ?= $(word 2,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_REPONAME)
ifneq (,$(CI_USER))
ifneq (,$(CI_REPO))
CI_REPO_FULL = $(CI_USER)/$(CI_REPO)
endif
endif
ifdef CI_PULL_REQUESTS
CI_IS_PR = true
else
# Circle makes this easy
ifdef TRAVIS_PULL_REQUEST
ifeq (false,$(TRAVIS_PULL_REQUEST))
# If $TRAVIS_PULL_REQUEST is the word 'false', it's a branch build.
CI_IS_PR = false
else
CI_IS_PR = true
endif
else
CI_IS_PR = false
endif
endif
CI_ARTIFACTS := $(CIRCLE_ARTIFACTS)

ifeq (,$(shell git config --global --get user.name))
CI_AUTHOR = -c user.name="ID Bot"
endif
ifeq (,$(shell git config --global --get user.email))
CI_AUTHOR += -c user.email="idbot@example.com"
endif

# Github guesses
GIT_REMOTE ?= origin
ifeq (,$(CI_REPO_FULL))
GITHUB_REPO_FULL := $(shell git ls-remote --get-url $(GIT_REMOTE) 2>/dev/null |\
		      sed -e 's/^.*github\.com.//;s/\.git$$//')
GITHUB_USER := $(word 1,$(subst /, ,$(GITHUB_REPO_FULL)))
GITHUB_REPO := $(word 2,$(subst /, ,$(GITHUB_REPO_FULL)))
else
GITHUB_REPO_FULL := $(CI_REPO_FULL)
GITHUB_USER := $(CI_USER)
GITHUB_REPO := $(CI_REPO)
endif
