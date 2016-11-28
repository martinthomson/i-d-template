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

ifeq (true,$(CI))
FETCH_SHALLOW := --depth=5
else
FETCH_SHALLOW :=
endif
.PHONY: fetch-ghpages
fetch-ghpages:
	-git fetch $(FETCH_SHALLOW) origin gh-pages:gh-pages

ifeq (true,$(CI))
CLONE_LOCAL :=
else
CLONE_LOCAL := --local
endif
GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
ghpages: $(GHPAGES_TMP)
.INTERMEDIATE: $(GHPAGES_TMP)
$(GHPAGES_TMP): fetch-ghpages
	git clone -q $(CLONE_LOCAL) -b gh-pages . $@

.PHONY: ghpages
ghpages: index.html $(drafts_html) $(drafts_txt)
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
	cp -f $(filter-out $(GHPAGES_TMP),$^) $(GHPAGES_TMP)/$(TARGET_DIR)
ifneq (,$(CI_ARTIFACTS))
	cp -f $(filter-out $(GHPAGES_TMP),$^) $(CI_ARTIFACTS)
endif
	git -C $(GHPAGES_TMP) add -f $(addprefix $(TARGET_DIR),$(filter-out $(GHPAGES_TMP),$^))
	if test `git -C $(GHPAGES_TMP) status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git -C $(GHPAGES_TMP) commit -m "Script updating gh-pages. [ci skip]"; fi
ifneq (,$(CI_HAS_WRITE_KEY))
	git -C $(GHPAGES_TMP) push https://github.com/$(CI_REPO_FULL).git gh-pages
else
ifneq (,$(GH_TOKEN))
	@echo -C $(GHPAGES_TMP) git push -q https://github.com/$(CI_REPO_FULL) gh-pages
	@git -C $(GHPAGES_TMP) push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL) gh-pages >/dev/null 2>&1
else
	git -C $(GHPAGES_TMP) push origin gh-pages
endif
endif
	-rm -rf $(GHPAGES_TMP)
endif # PUSH_GHPAGES
