## Identify drafts, types and versions

draft_patterns := draft draft-*[a-z] draft-*[-a-z][0-9] draft-*[a-z0-9][a-z0-9][0-9]
extensions := xml org md
drafts := $(sort $(basename $(wildcard $(foreach pattern,$(draft_patterns),$(foreach ext,$(extensions),$(pattern).$(ext))))))
drafts += $(sort $(basename $(wildcard $(foreach n,d dd ddd dddd ddddd,$(foreach ext,$(extensions),rfc$(subst d,[0-9],$(n)).$(ext))))))

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
drafts_next := $(foreach draft,$(filter draft-%,$(drafts)),$(draft)-$(f_next_tag))
drafts_prev := $(foreach draft,$(filter draft-%,$(drafts)),$(draft)-$(f_prev_tag))
drafts_with_prev := $(foreach draft,$(filter draft-%,$(drafts)),$(if $(f_prev_tag),$(draft)))

drafts_txt := $(addsuffix .txt,$(drafts))
drafts_html := $(addsuffix .html,$(drafts))
drafts_xml := $(addsuffix .xml,$(drafts))
drafts_next_txt := $(addprefix $(VERSIONED)/,$(addsuffix .txt,$(drafts_next)))
drafts_next_xml := $(addprefix $(VERSIONED)/,$(addsuffix .xml,$(drafts_next)))

last_modified = $$(stat $$([ $$(uname -s) = Darwin -o $$(uname -s) = FreeBSD ] && echo -f '%m' || echo -c '%Y') $(1))
file_size = $$(stat $$([ $$(uname -s) = Darwin -o $$(uname -s) = FreeBSD ] && echo -f '%z' || echo -c '%s') $(1))
last_commit = $$(git rev-list -n 1 --timestamp $(1) -- $(2) | sed -e 's/ .*//')

# CI config
CI ?= false
ifneq (,$(GITHUB_REPOSITORY))
CI_USER ?= $(word 1,$(subst /, ,$(GITHUB_REPOSITORY))
CI_REPO ?= $(word 2,$(subst /, ,$(GITHUB_REPOSITORY)))
else
CI_USER ?= $(word 1,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_USERNAME)
CI_REPO ?= $(word 2,$(subst /, ,$(TRAVIS_REPO_SLUG)))$(CIRCLE_PROJECT_REPONAME)
ifneq (,$(CI_USER))
ifneq (,$(CI_REPO))
CI_REPO_FULL = $(CI_USER)/$(CI_REPO)
endif
endif
endif

# CI_IS_PR being true disables some options.
ifdef CI_PULL_REQUESTS
# Circle makes this easy
CI_IS_PR = true
else
ifdef GITHUB_BASE_REF
CI_IS_PR = true
else
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
export GIT_REMOTE
ifeq (,$(CI_REPO_FULL))
# The github.com/user/repository part of either a
# git@github.com:user/repository.git or a https://github.com/user/repository
# remote (or any other hoster's domain/user/repository part if it uses a
# similar structure)
GITHUB_REPO_WITHHOST := $(shell git ls-remote --get-url $(GIT_REMOTE) 2>/dev/null |\
			sed -e 's/^[a-zA-Z0-9+.-]*:\/\///;s/.*@//;s/:/\//;s/\.git$$//')
GITHUB_HOST := $(word 1,$(subst /, ,$(GITHUB_REPO_WITHHOST)))
GITHUB_USER := $(word 2,$(subst /, ,$(GITHUB_REPO_WITHHOST)))
GITHUB_REPO := $(word 3,$(subst /, ,$(GITHUB_REPO_WITHHOST)))
GITHUB_REPO_FULL := $(GITHUB_USER)/$(GITHUB_REPO)
else
GITHUB_REPO_FULL := $(CI_REPO_FULL)
CI_HOST ?= github.com
GITHUB_HOST := $(CI_HOST)
GITHUB_USER := $(CI_USER)
GITHUB_REPO := $(CI_REPO)
endif

# GITHUB_PUSH_TOKEN is used for pushes.
ifneq (,$(and $(GITHUB_ACTOR),$(GITHUB_TOKEN)))
GITHUB_PUSH_TOKEN ?= $(GITHUB_ACTOR):$(GITHUB_TOKEN)
else
GITHUB_PUSH_TOKEN ?= $(GH_TOKEN)
endif
# GITHUB_API_TOKEN is used in the GitHub API.
GITHUB_API_TOKEN ?= $(or $(GITHUB_TOKEN),$(GH_TOKEN))

ifeq (,$(BRANCH_FETCH))
BRANCH_FETCH := true
endif
export BRANCH_FETCH
ifeq (,$(DEFAULT_BRANCH))
DEFAULT_BRANCH := $(shell BRANCH_FETCH=$(BRANCH_FETCH) $(LIBDIR)/default-branch.py $(GITHUB_USER) $(GITHUB_REPO) $(GITHUB_API_TOKEN))
endif
export DEFAULT_BRANCH

PID := $(shell echo $$$$)
