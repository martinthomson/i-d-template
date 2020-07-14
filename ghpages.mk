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
SOURCE_BRANCH := $(notdir $(GITHUB_REF))
else
SOURCE_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
ifeq (HEAD,$(SOURCE_BRANCH))
SOURCE_BRANCH := $(shell git rev-parse --short HEAD)
endif
endif
endif

# Default to pushing if a key or token is available.
ifeq (pull_request,$(GITHUB_EVENT_NAME))
PUSH_GHPAGES ?= false
endif
ifneq (,$(GITHUB_PUSH_TOKEN)$(CI_HAS_WRITE_KEY))
PUSH_GHPAGES ?= true
endif
PUSH_GHPAGES ?= false

index.html: $(drafts_html) $(drafts_txt)
ifeq (1,$(words $(drafts)))
	cp $< $@
else
	@echo '<!DOCTYPE html>' >$@
	@echo '<html>' >>$@
	@echo '<head><title>$(GITHUB_REPO) drafts</title></head>' >>$@
	@echo '<body><ul>' >>$@
	@for draft in $(drafts); do \
	  echo '<li><a href="'"$${draft}"'.html">'"$${draft}"'</a> (<a href="'"$${draft}"'.txt">txt</a>)</li>' >>$@; \
	done
	@echo '</ul></body>' >>$@
	@echo '</html>' >>$@
endif

.IGNORE: fetch-ghpages
.PHONY: fetch-ghpages
fetch-ghpages:
	git fetch -qf origin gh-pages:gh-pages

GHPAGES_ROOT := /tmp/ghpages$(shell echo $$$$)
ghpages: $(GHPAGES_ROOT)
$(GHPAGES_ROOT): fetch-ghpages
	@git show-ref refs/heads/gh-pages >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/gh-pages >/dev/null 2>&1 && \
	    git branch -t gh-pages origin/gh-pages) || \
	  ! echo 'Error: No gh-pages branch, run `make -f $(LIBDIR)/setup.mk setup-ghpages` to initialize it.'
	git clone -q -b gh-pages . $@

GHPAGES_TARGET := $(GHPAGES_ROOT)$(filter-out /$(DEFAULT_BRANCH),/$(SOURCE_BRANCH))
ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
$(GHPAGES_TARGET): $(GHPAGES_ROOT)
	mkdir -p $@
endif

GHPAGES_PUBLISHED := $(drafts_html) $(drafts_txt) $(GHPAGES_EXTRA)
GHPAGES_INSTALLED := $(addprefix $(GHPAGES_TARGET)/,$(GHPAGES_PUBLISHED))
$(GHPAGES_INSTALLED): $(GHPAGES_PUBLISHED) $(GHPAGES_TARGET)
	cp -f $(notdir $@) $@

GHPAGES_ALL := $(GHPAGES_INSTALLED) $(GHPAGES_TARGET)/index.html
$(GHPAGES_TARGET)/index.html: $(GHPAGES_INSTALLED)
	$(LIBDIR)/build-index.sh "$(dir $@)" "$(SOURCE_BRANCH)" "$(GITHUB_USER)" "$(GITHUB_REPO)" >$@

ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
GHPAGES_ALL += $(GHPAGES_ROOT)/index.html
$(GHPAGES_ROOT)/index.html: $(GHPAGES_INSTALLED)
	$(LIBDIR)/build-index.sh "$(dir $@)" $(DEFAULT_BRANCH) "$(GITHUB_USER)" "$(GITHUB_REPO)" >$@
endif

.PHONY: cleanup-ghpages
cleanup-ghpages: $(GHPAGES_ROOT)
	-@for remote in `git remote`; do \
	  git remote prune $$remote; \
	done;

# Drop old gh-pages commits (keep 30-60 days of history)
	@KEEP=$$((`date '+%s'`-2592000)); CUTOFF=$$((`date '+%s'`-5184000)); \
	ROOT=`git -C $(GHPAGES_ROOT) rev-list --max-parents=0 gh-pages`; \
	if [ `git -C $(GHPAGES_ROOT) show -s --format=%ct $$ROOT` -lt $$CUTOFF ]; then \
	  NEW_ROOT=`git -C $(GHPAGES_ROOT) rev-list --min-age=$$KEEP --max-count=1 gh-pages`; \
	  if [ $$NEW_ROOT != $$ROOT ]; then \
		git -C $(GHPAGES_ROOT) replace --graft $$NEW_ROOT && \
		git -C $(GHPAGES_ROOT) filter-branch gh-pages; \
	  fi \
	fi

# Clean up obsolete directories (2592000 = 30 days)
	@CUTOFF=$$(($$(date '+%s')-2592000)); \
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
ghpages: cleanup-ghpages $(GHPAGES_ALL)
	git -C $(GHPAGES_ROOT) add -f $(GHPAGES_ALL)
	if test `git -C $(GHPAGES_ROOT) status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git -C $(GHPAGES_ROOT) $(CI_AUTHOR) commit -m "Script updating gh-pages from $(shell git rev-parse --short HEAD). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(if $(CI_HAS_WRITE_KEY),1,$(if $(GITHUB_PUSH_TOKEN),,1)))
	git -C $(GHPAGES_ROOT) push -f https://github.com/$(GITHUB_REPO_FULL) gh-pages
else
	@echo git -C $(GHPAGES_ROOT) push -qf https://github.com/$(GITHUB_REPO_FULL) gh-pages
	@git -C $(GHPAGES_ROOT) push -qf https://$(GITHUB_PUSH_TOKEN)@github.com/$(GITHUB_REPO_FULL) gh-pages >/dev/null 2>&1
endif
else
	git -C $(GHPAGES_ROOT) push -f origin gh-pages
endif # PUSH_GHPAGES
	-rm -rf $(GHPAGES_ROOT)

## Save published documents to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
$(CI_ARTIFACTS):
	mkdir -p $@

.PHONY: artifacts
artifacts: $(GHPAGES_PUBLISHED) $(CI_ARTIFACTS)
	cp -f $(filter-out $(CI_ARTIFACTS),$^) $(CI_ARTIFACTS)
endif
