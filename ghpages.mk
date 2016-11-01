## Update the gh-pages branch with useful files

ifeq (,$(CI_ARTIFACTS))
GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
ghpages: $(GHPAGES_TMP)
.INTERMEDIATE: $(GHPAGES_TMP)
$(GHPAGES_TMP):
	mkdir $(GHPAGES_TMP)
else
GHPAGES_TMP := $(CI_ARTIFACTS)
endif

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

.PHONY: ghpages
ghpages: index.html $(drafts_html) $(drafts_txt)
ifneq (true,$(CI))
	@git show-ref refs/heads/gh-pages >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/gh-pages >/dev/null 2>&1 && \
	    git branch -t gh-pages origin/gh-pages) || \
	  ! echo 'Error: No gh-pages branch, run `make setup-ghpages` to initialize it.'
endif
ifeq (true,$(PUSH_GHPAGES))
	cp -f $(filter-out $(GHPAGES_TMP),$^) $(GHPAGES_TMP)
	git clean -qfdX
ifeq (true,$(CI))
	git config user.email "ci-bot@example.com"
	git config user.name "CI Bot"
	git checkout -q --orphan gh-pages
	git rm -qrf --cached .
	git clean -qfd
	git pull -qf origin gh-pages
else
	git checkout gh-pages
	git pull
endif
ifneq (,$(TARGET_DIR))
	mkdir -p $(CURDIR)/$(TARGET_DIR)
endif
	cp -f $(GHPAGES_TMP)/* $(CURDIR)/$(TARGET_DIR)
	git add -f $(addprefix $(TARGET_DIR),$(filter-out $(GHPAGES_TMP),$^))
	if test `git status --porcelain | grep '^[A-Z]' | wc -l` -gt 0; then \
	  git commit -m "Script updating gh-pages. [ci skip]"; fi
ifneq (,$(CI_HAS_WRITE_KEY))
	git push https://github.com/$(CI_REPO_FULL).git gh-pages
else
ifneq (,$(GH_TOKEN))
	@echo git push -q https://github.com/$(CI_REPO_FULL).git gh-pages
	@git push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL).git gh-pages >/dev/null 2>&1
endif
endif
	-git checkout -qf "$(SOURCE_BRANCH)"
ifeq (,$(CI_ARTIFACTS))
	-rm -rf $(GHPAGES_TMP)
endif
endif # PUSH_GHPAGES
