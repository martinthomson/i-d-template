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
SOURCE_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
ifeq (HEAD,$(SOURCE_BRANCH))
SOURCE_BRANCH := $(shell git rev-parse --short HEAD)
endif
endif

ifeq (true,$(CI))
# If we have the write key or a token, we can push
ifneq (,$(GH_TOKEN)$(CI_HAS_WRITE_KEY)$(SELF_TEST))
PUSH_GHPAGES := true
else
PUSH_GHPAGES := false
endif
else # !CI
PUSH_GHPAGES := true
endif

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

.PHONY: fetch-ghpages
fetch-ghpages:
	-git fetch -q origin gh-pages:gh-pages

GHPAGES_ROOT := /tmp/ghpages$(shell echo $$$$)
ghpages: $(GHPAGES_ROOT)
$(GHPAGES_ROOT): fetch-ghpages
	@git show-ref refs/heads/gh-pages >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/gh-pages >/dev/null 2>&1 && \
	    git branch -t gh-pages origin/gh-pages) || \
	  ! echo 'Error: No gh-pages branch, run `make -f $(LIBDIR)/setup.mk setup-ghpages` to initialize it.'
	git clone -q -b gh-pages . $@

GHPAGES_TARGET := $(GHPAGES_ROOT)$(filter-out /master,/$(SOURCE_BRANCH))
ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
$(GHPAGES_TARGET): $(GHPAGES_ROOT)
	mkdir -p $@
endif

GHPAGES_PUBLISHED := $(drafts_html) $(drafts_txt)
GHPAGES_INSTALLED := $(addprefix $(GHPAGES_TARGET)/,$(GHPAGES_PUBLISHED))
$(GHPAGES_INSTALLED): $(GHPAGES_PUBLISHED) $(GHPAGES_TARGET)
	cp -f $(notdir $@) $@

GHPAGES_ALL := $(GHPAGES_INSTALLED) $(GHPAGES_TARGET)/index.html
$(GHPAGES_TARGET)/index.html: $(GHPAGES_INSTALLED)
	$(LIBDIR)/build-index.sh "$(dir $@)" "$(GITHUB_USER)" "$(GITHUB_REPO)" >$@

ifneq ($(GHPAGES_TARGET),$(GHPAGES_ROOT))
GHPAGES_ALL += $(GHPAGES_ROOT)/index.html
$(GHPAGES_ROOT)/index.html: $(GHPAGES_INSTALLED)
	$(LIBDIR)/build-index.sh "$(dir $@)" "$(GITHUB_USER)" "$(GITHUB_REPO)" >$@
endif

.PHONY: cleanup-ghpages
cleanup-ghpages: $(GHPAGES_ROOT)
	-@for remote in `git remote`; do \
	  git remote prune $$remote; \
	done;

# Clean up obsolete directories
	@CUTOFF=`date +%s -d '-30 days'`; \
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
	  echo git -C $(GHPAGES_ROOT) rm -fq --ignore-unmatch -- $(GHPAGES_TARGET)/*.html $(GHPAGES_TARGET)/*.txt; \
	  git -C $(GHPAGES_ROOT) rm -fq --ignore-unmatch -- $(GHPAGES_TARGET)/*.html $(GHPAGES_TARGET)/*.txt; \
	fi


.PHONY: ghpages gh-pages
gh-pages: ghpages
ghpages: cleanup-ghpages $(GHPAGES_ALL)
	git -C $(GHPAGES_ROOT) add -f $(GHPAGES_ALL)
	if test `git -C $(GHPAGES_ROOT) status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git -C $(GHPAGES_ROOT) $(CI_AUTHOR) commit -m "Script updating gh-pages from $(shell git rev-parse --short HEAD). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(CI_HAS_WRITE_KEY))
	git -C $(GHPAGES_ROOT) push https://github.com/$(CI_REPO_FULL).git gh-pages
else
ifneq (,$(GH_TOKEN))
	@echo git -C $(GHPAGES_ROOT) push -q https://github.com/$(CI_REPO_FULL) gh-pages
	@git -C $(GHPAGES_ROOT) push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL) gh-pages >/dev/null 2>&1
else
	git -C $(GHPAGES_ROOT) push origin gh-pages
endif
endif
	-rm -rf $(GHPAGES_ROOT)
endif # PUSH_GHPAGES

## Save published documents to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
.PHONY: artifacts
artifacts: $(GHPAGES_PUBLISHED)
	cp -f $^ $(CI_ARTIFACTS)
endif
