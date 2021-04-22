ARCHIVE_BRANCH := gh-pages
.PHONY: fetch-archive
fetch-archive:
	-git fetch -qf origin $(ARCHIVE_BRANCH):$(ARCHIVE_BRANCH)

## Aliases for old stuff for compatibility reasons (added 2020-03-17).
.PHONY: issues ghissues gh-issues
issues: archive
gh-issues gh-issues: gh-archive
DISABLE_ARCHIVE_FETCH ?= $(DISABLE_ISSUE_FETCH)

ifneq (true,$(PUSH_GHPAGES))
DISABLE_ARCHIVE_FETCH ?= true
endif

# Can't load issues without authentication.
ifeq (,$(GITHUB_API_TOKEN))
DISABLE_ARCHIVE_FETCH := true
endif

## Store a copy of any GitHub issues and pull requests.
.PHONY: archive
archive: archive.json
archive.json: fetch-archive $(drafts_source)
	@if [ -f $@ ] && [ "$(call file_size,$@)" -gt 0 ] && \
	    [ "$(call last_modified,$@)" -gt "$(call last_commit,$(ARCHIVE_BRANCH),$@)" ] 2>/dev/null; then \
	  echo 'Skipping update of $@ (it is newer than the ones on the branch)'; exit; \
	fi; \
	skip=$(DISABLE_ARCHIVE_FETCH); \
	if [ $(CI) = true -a "$$skip" != true -a \
	     $$(($$(date '+%s')-28800)) -lt "$$(git log -n 1 --pretty=format:%ct $(ARCHIVE_BRANCH) -- $@)" ] 2>/dev/null; then \
	    skip=true; echo 'Skipping update of $@ (most recent update was in the last 8 hours)'; \
	fi; \
	if [ "$$skip" = true ]; then \
	    echo 'Using existing copy of $@'; \
	    git show $(ARCHIVE_BRANCH):$@ > $@ || true; \
	    exit; \
	fi; \
	old_archive=$$(mktemp /tmp/archive-old.XXXXXX); \
	trap 'rm -f $$old_archive' EXIT; \
	git show $(ARCHIVE_BRANCH):$@ > $$old_archive || true; \
	$(LIBDIR)/archive_repo.py $(GITHUB_REPO_FULL) $(GITHUB_API_TOKEN) $@ --reference $$old_archive;


ARCHIVE_ROOT := /tmp/gharchive$(shell echo $$$$)
$(ARCHIVE_ROOT): fetch-archive
	@git show-ref refs/heads/$(ARCHIVE_BRANCH) >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/$(ARCHIVE_BRANCH) >/dev/null 2>&1 && \
	    git branch -t $(ARCHIVE_BRANCH) origin/$(ARCHIVE_BRANCH)) || \
	  ! echo 'Error: No $(ARCHIVE_BRANCH) branch, run `make -f $(LIBDIR)/setup.mk setup-ghpages` to initialize it.'
	git clone -q -b $(ARCHIVE_BRANCH) . $@

$(ARCHIVE_ROOT)/%.json: %.json $(ARCHIVE_ROOT)
	cp -f $< $@

## Commit and push the changes to $(ARCHIVE_BRANCH)
.PHONY: gh-archive
gh-archive: $(ARCHIVE_ROOT)/archive.json
	cp -f $(LIBDIR)/template/issues.html $(LIBDIR)/template/issues.js $(ARCHIVE_ROOT)
	@-git -C $(ARCHIVE_ROOT) rm --ignore-unmatch -f issues.json pulls.json
	git -C $(ARCHIVE_ROOT) add -f archive.json issues.html issues.js
	if test `git -C $(ARCHIVE_ROOT) status --porcelain archive.json issues.js issues.html | wc -l` -gt 0; then \
	  git -C $(ARCHIVE_ROOT) $(CI_AUTHOR) commit -m "Script updating archive at $(shell date -u +%FT%TZ). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(if $(CI_HAS_WRITE_KEY),1,$(if $(GITHUB_PUSH_TOKEN),,1)))
	git -C $(ARCHIVE_ROOT) push -f https://github.com/$(GITHUB_REPO_FULL) $(ARCHIVE_BRANCH)
else
	@echo git -C $(ARCHIVE_ROOT) push -qf https://github.com/$(GITHUB_REPO_FULL) $(ARCHIVE_BRANCH)
	@git -C $(ARCHIVE_ROOT) push -qf https://$(GITHUB_PUSH_TOKEN)@github.com/$(GITHUB_REPO_FULL) $(ARCHIVE_BRANCH) >/dev/null 2>&1
endif
else
	git -C $(ARCHIVE_ROOT) push -f origin $(ARCHIVE_BRANCH)
endif # PUSH_GHPAGES
	-rm -rf $(ARCHIVE_ROOT)

## Save archive.json to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
.PHONY: artifacts
artifacts: archive.json
endif
