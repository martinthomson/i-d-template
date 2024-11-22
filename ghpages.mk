## Update the gh-pages branch with useful files

ifeq (true,$(TRAVIS))
# Travis is a nightmare.  It doesn't actually include the branch name in the
# repo at all.  Also, it doesn't consistently set the current branch name.
ifneq (,$(TRAVIS_PULL_REQUEST_BRANCH))
SOURCE_BRANCH := $(TRAVIS_PULL_REQUEST_BRANCH)
else
SOURCE_BRANCH := $(TRAVIS_BRANCH)
endif
else
ifdef GITHUB_REF
ifneq (,$(filter refs/heads/%,$(GITHUB_REF)))
SOURCE_BRANCH := $(patsubst refs/heads/%,%,$(GITHUB_REF))
else
ifneq (,$(filter refs/tags/%,$(GITHUB_REF)))
SOURCE_BRANCH := $(patsubst refs/tags/%,%,$(GITHUB_REF))
else
SOURCE_BRANCH := $(notdir $(GITHUB_REF))
endif
endif
else
SOURCE_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
ifeq (HEAD,$(SOURCE_BRANCH))
SOURCE_BRANCH := $(shell git rev-parse --short HEAD)
endif
endif
endif

# Disable pushing if we're not setup and for pull requests.
# Otherwise, enable it if we appear to have credentials.
ifeq (true,$(PRE_SETUP))
PUSH_GHPAGES ?= false
endif
ifeq (pull_request,$(GITHUB_EVENT_NAME))
PUSH_GHPAGES ?= false
endif
ifneq (,$(GITHUB_PUSH_TOKEN)$(CI_HAS_WRITE_KEY))
PUSH_GHPAGES ?= true
endif
PUSH_GHPAGES ?= false

# PAGES_BRANCH is where the latest upstream version of the (typically GitHub)
# Pages is fetched from, and where it is pushed to. Different hosters have
# different branch names for this purpose (if they do it that way at all).
ifeq (github.com,$(GITHUB_HOST))
PAGES_BRANCH ?= gh-pages
else ifeq (tmp,$(GITHUB_HOST))
# OK, this is gross, but this is what happens when we are operating under test.
PAGES_BRANCH ?= gh-pages
else
# This is common across all Forgejo instances, and as there is no more
# generic default, this is also the catch-all.
PAGES_BRANCH ?= pages
endif

.IGNORE: fetch-ghpages
.PHONY: fetch-ghpages
fetch-ghpages:
	git fetch -qf origin ${PAGES_BRANCH}:${PAGES_BRANCH}

GHPAGES_ROOT := $(TMPDIR)/ghpages$(PID)
ghpages: $(GHPAGES_ROOT)
$(GHPAGES_ROOT): fetch-ghpages
	@git show-ref refs/heads/${PAGES_BRANCH} >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/${PAGES_BRANCH} >/dev/null 2>&1 && \
	    git branch -t ${PAGES_BRANCH} origin/${PAGES_BRANCH}) || \
	  ! echo 'Error: No ${PAGES_BRANCH} branch, run `make -f $(LIBDIR)/setup.mk setup-ghpages` to initialize it.'
	git clone -q -b ${PAGES_BRANCH} . $@

GHPAGES_TARGET := $(GHPAGES_ROOT)$(filter-out /$(DEFAULT_BRANCH),/$(SOURCE_BRANCH))
ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
$(GHPAGES_TARGET): $(GHPAGES_ROOT)
	mkdir -p $@
endif

GHPAGES_PUBLISHED := $(drafts_html) $(drafts_txt) $(GHPAGES_EXTRA)
GHPAGES_INSTALLED := $(addprefix $(GHPAGES_TARGET)/,$(GHPAGES_PUBLISHED))
$(GHPAGES_INSTALLED): $(GHPAGES_PUBLISHED) $(GHPAGES_TARGET) | cleanup-ghpages
	cp -f $(notdir $@) $@

GHPAGES_ALL := $(GHPAGES_INSTALLED) $(GHPAGES_TARGET)/index.$(INDEX_FORMAT)
$(GHPAGES_TARGET)/index.$(INDEX_FORMAT): $(GHPAGES_INSTALLED) $(DEPS_FILES) | cleanup-ghpages
	$(LIBDIR)/build-index.sh $(INDEX_FORMAT) "$(dir $@)" "$(SOURCE_BRANCH)" "$(GITHUB_HOST)" "$(GITHUB_USER)" "$(GITHUB_REPO)" $(drafts_source) >$@

ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
GHPAGES_ALL += $(GHPAGES_ROOT)/index.$(INDEX_FORMAT)
$(GHPAGES_ROOT)/index.$(INDEX_FORMAT): $(GHPAGES_INSTALLED) $(DEPS_FILES)
	$(LIBDIR)/build-index.sh $(INDEX_FORMAT) "$(dir $@)" "$(DEFAULT_BRANCH)" "$(GITHUB_HOST)" "$(GITHUB_USER)" "$(GITHUB_REPO)" $(drafts_source) >$@
endif

# GHPAGES_COMMIT_TTL is the number of days worth of commits to keep on the ${PAGES_BRANCH} branch.
GHPAGES_COMMIT_TTL ?= 90
# GHPAGES_BRANCH_TTL is the number of days to retain a directory on ${PAGES_BRANCH}
# after the corresponding branch has been deleted. This is measured from the last change.
GHPAGES_BRANCH_TTL ?= 30
.PHONY: cleanup-ghpages
cleanup-ghpages: $(GHPAGES_ROOT)
	-@for remote in `git remote`; do \
	  git remote prune $$remote; \
	done;

ifneq (true,$(CI))
# Drop old ${PAGES_BRANCH} commits.
# Retain $(GHPAGES_COMMIT_TTL) days of history.
# Only run this if more than $(GHPAGES_COMMIT_TTL)*2 days of history exists.
	@KEEP=$$((`date '+%s'`-($(GHPAGES_COMMIT_TTL)*86400))); \
	CUTOFF=$$((`date '+%s'`-($(GHPAGES_COMMIT_TTL)*172800))); \
	ROOT=`git -C $(GHPAGES_ROOT) rev-list --max-parents=0 ${PAGES_BRANCH}`; \
	if [ `git -C $(GHPAGES_ROOT) show -s --format=%ct $$ROOT` -lt $$CUTOFF ]; then \
	  NEW_ROOT=`git -C $(GHPAGES_ROOT) rev-list --min-age=$$KEEP --max-count=1 ${PAGES_BRANCH}`; \
	  if [ $$NEW_ROOT != $$ROOT ]; then \
		git -C $(GHPAGES_ROOT) replace --graft $$NEW_ROOT && \
		FILTER_BRANCH_SQUELCH_WARNING=1 git -C $(GHPAGES_ROOT) filter-branch ${PAGES_BRANCH}; \
	  fi \
	fi
endif

# Clean up obsolete directories
# Keep old branches for $(GHPAGES_BRANCH_TTL) days after the last changes (on the ${PAGES_BRANCH} branch).
	@CUTOFF=$$(($$(date '+%s')-($(GHPAGES_BRANCH_TTL)*86400))); \
	MAYBE_OBSOLETE=`comm -13 <(git branch -a | sed -e 's,.*[ /],,' | sort | uniq) <(ls $(GHPAGES_ROOT) | sed -e 's,.*/,,')`; \
	for item in $$MAYBE_OBSOLETE; do \
	  if [ -d "$(GHPAGES_ROOT)/$$item" ] && \
	     [ `git -C $(GHPAGES_ROOT) log -n 1 --format=%ct -- $$item` -lt $$CUTOFF ]; then \
	    echo "Remove obsolete '$$item'"; \
	    git -C $(GHPAGES_ROOT) rm -rfq -- $$item; \
	  fi \
	done

# Clean up contents of target directory
	@if [ -d $(GHPAGES_TARGET) ]; then \
	  echo git -C $(GHPAGES_ROOT) rm -fq --ignore-unmatch -- $(GHPAGES_TARGET)/draft-*.html $(GHPAGES_TARGET)/draft-*.txt $(addprefix $(GHPAGES_TARGET)/,$(GHPAGES_EXTRA)); \
	  git -C $(GHPAGES_ROOT) rm -fq --ignore-unmatch -- $(GHPAGES_TARGET)/draft-*.html $(GHPAGES_TARGET)/draft-*.txt $(addprefix $(GHPAGES_TARGET)/,$(GHPAGES_EXTRA)); \
	fi

.PHONY: ghpages gh-pages
gh-pages: ghpages
ifneq (,$(MAKE_TRACE))
ghpages:
	@$(call MAKE_TRACE,ghpages)
else
ghpages: $(GHPAGES_ALL)
	git -C $(GHPAGES_ROOT) add -f $(GHPAGES_ALL)
	if test `git -C $(GHPAGES_ROOT) status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git -C $(GHPAGES_ROOT) $(CI_AUTHOR) commit -m "Script updating ${PAGES_BRANCH} from $(shell git rev-parse --short HEAD). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(if $(CI_HAS_WRITE_KEY),1,$(if $(GITHUB_PUSH_TOKEN),,1)))
	$(trace) all -s ghpages-push git -C $(GHPAGES_ROOT) push -f "$(shell git remote get-url --push $(GIT_REMOTE))" ${PAGES_BRANCH}
else
	@echo git -C $(GHPAGES_ROOT) push -qf https://****@github.com/$(GITHUB_REPO_FULL) ${PAGES_BRANCH}
	@git -C $(GHPAGES_ROOT) push -qf https://$(GITHUB_PUSH_TOKEN)@github.com/$(GITHUB_REPO_FULL) ${PAGES_BRANCH} >/dev/null 2>&1 \
	  || $(trace) all -s ghpages-push ! echo "git -C $(GHPAGES_ROOT) push -qf https://****@github.com/$(GITHUB_REPO_FULL) ${PAGES_BRANCH}"
endif
else
ifeq (true,$(CI))
	@echo "*** Warning: pushing to the ${PAGES_BRANCH} branch is disabled."
else
	$(trace) all -s ghpages-push git -C $(GHPAGES_ROOT) push -f origin ${PAGES_BRANCH}
endif
endif # PUSH_GHPAGES
	-rm -rf $(GHPAGES_ROOT)
endif # MAKE_TRACE

## Save published documents to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
$(CI_ARTIFACTS):
	mkdir -p $@

.PHONY: artifacts
artifacts: $(GHPAGES_PUBLISHED) $(CI_ARTIFACTS)
	cp -f $(filter-out $(CI_ARTIFACTS),$^) $(CI_ARTIFACTS)
endif
