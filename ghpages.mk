## Update the gh-pages branch with useful files

ifneq (,$(CI_BRANCH))
SOURCE_BRANCH := $(CI_BRANCH)
else
SOURCE_BRANCH := $(shell git branch | grep '*' | cut -c 3-)
endif
ifneq (,$(findstring detached from,$(SOURCE_BRANCH)))
SOURCE_BRANCH := $(shell git show -s --format='format:%H')
endif

TARGET_DIR := $(filter-out master/,$(SOURCE_BRANCH)/)

ifeq (true,$(CI))
# If we have the write key or a token, we can push
ifneq (,$(GH_TOKEN)$(CI_HAS_WRITE_KEY))
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

# Can't do a shallow fetch for master; need history to check ages
ifeq (true,$(CI))
ifneq (master,$(SOURCE_BRANCH))
FETCH_SHALLOW := --depth=5
endif
endif
FETCH_SHALLOW ?=

.PHONY: fetch-ghpages
fetch-ghpages:
	-git fetch -q $(FETCH_SHALLOW) origin gh-pages:gh-pages

ifeq (true,$(CI))
CLONE_LOCAL :=
else
ifeq (Darwin,$(shell uname -s))
stat_fs := stat -f %d
else
stat_fs := stat -c %d
endif
ifeq ($(shell $(stat_fs) .),$(shell $(stat_fs) /tmp))
CLONE_LOCAL := --local
else
CLONE_LOCAL := --local --no-hardlink
endif
endif
GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
ghpages: $(GHPAGES_TMP)
.INTERMEDIATE: $(GHPAGES_TMP)
$(GHPAGES_TMP): fetch-ghpages
	git clone -q $(CLONE_LOCAL) -b gh-pages . $@

PUBLISHED := index.html $(drafts_html) $(drafts_txt)

ifeq (master,$(SOURCE_BRANCH))
ifeq (true,$(PUSH_GHPAGES))
EXTANT_BRANCHES := $(subst refs/heads/,,$(foreach remote,$(shell git remote),$(shell git ls-remote --heads $(remote) | cut -f 2)))
OBSOLETE_DIRECTORIES := $(shell git ls-tree -t --name-only gh-pages)
OBSOLETE_DIRECTORIES := $(filter-out circle.yml .gitignore,$(OBSOLETE_DIRECTORIES))
OBSOLETE_DIRECTORIES := $(filter-out $(EXTANT_BRANCHES),$(OBSOLETE_DIRECTORIES))
OBSOLETE_DIRECTORIES := $(filter-out $(PUBLISHED),$(OBSOLETE_DIRECTORIES))
endif
endif
OBSOLETE_DIRECTORIES ?=

.PHONY: ghpages gh-pages
gh-pages: ghpages
ghpages: $(PUBLISHED)

ifneq (true,$(CI))
	@git show-ref refs/heads/gh-pages >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/gh-pages >/dev/null 2>&1 && \
	    git branch -t gh-pages origin/gh-pages) || \
	  ! echo 'Error: No gh-pages branch, run `make setup-ghpages` to initialize it.'
else
	git -C $(GHPAGES_TMP) config user.email "ci-bot@example.com"
	git -C $(GHPAGES_TMP) config user.name "CI Bot"
endif
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(TARGET_DIR))
	mkdir -p $(GHPAGES_TMP)/$(TARGET_DIR)
endif

	@EXCESS_FILES="$(addprefix $(TARGET_DIR),$(filter-out $^,$(notdir $(foreach ext,*.html *.txt,$(wildcard $(GHPAGES_TMP)/$(TARGET_DIR)/$(ext))))))"; \
	if [ -n "$$EXCESS_FILES" ]; \
		then git -C $(GHPAGES_TMP) rm -f --ignore-unmatch -- $$EXCESS_FILES; \
	fi

ifneq (0,$(words $(OBSOLETE_DIRECTORIES)))
	@CUTOFF=`date +%s -d '-30 days'`; \
	for item in $(OBSOLETE_DIRECTORIES); do \
		if [ -d "$(GHPAGES_TMP)/$$item" ] && \
			[ "`git -C $(GHPAGES_TMP) log -r -t -n 1 --format=%ct $$item`" -lt "$$CUTOFF" ]; \
			then git -C $(GHPAGES_TMP) rm -f -r $$item; \
		fi \
	done;
endif

	cp -f $(filter-out $(GHPAGES_TMP),$^) $(GHPAGES_TMP)/$(TARGET_DIR)
	git -C $(GHPAGES_TMP) add -f $(addprefix $(TARGET_DIR),$(filter-out $(GHPAGES_TMP),$^))
	if test `git -C $(GHPAGES_TMP) status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git -C $(GHPAGES_TMP) commit -m "Script updating gh-pages. [ci skip]"; fi
ifneq (,$(CI_HAS_WRITE_KEY))
	git -C $(GHPAGES_TMP) push https://github.com/$(CI_REPO_FULL).git gh-pages
else
ifneq (,$(GH_TOKEN))
	@echo git -C $(GHPAGES_TMP) push -q https://github.com/$(CI_REPO_FULL) gh-pages
	@git -C $(GHPAGES_TMP) push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL) gh-pages >/dev/null 2>&1
else
	git -C $(GHPAGES_TMP) push origin gh-pages
endif
endif
	-rm -rf $(GHPAGES_TMP)
endif # PUSH_GHPAGES

## Save published documents to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
.PHONY: artifacts
ifeq (true,$(SAVE_ISSUES_ARTIFACT))
artifacts: issues.json
endif
artifacts: $(PUBLISHED)
	cp -f $^ $(CI_ARTIFACTS)
endif
