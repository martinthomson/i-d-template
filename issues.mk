GH_ISSUES := gh-pages
.PHONY: fetch-ghissues
fetch-ghissues:
	-git fetch -q origin $(GH_ISSUES):$(GH_ISSUES)

ifneq (,$(GH_TOKEN))
GITHUB_OAUTH := -H "Authorization: token $(GH_TOKEN)"
endif

ifneq (true,$(PUSH_GHPAGES))
DISABLE_ISSUE_FETCH ?= true
endif

## Store a copy of any github issues
.PHONY: issues
.INTERMEDIATE: archive_repo
issues: issues.json pulls.json
issues.json pulls.json: archive_repo
archive_repo: fetch-ghissues $(drafts_source)
	@if [ -f issues.json ] && [ -f pulls.json ] && \
	   [ "$(call last_modified,issues.json)" -gt "$(call last_commit,$(GH_ISSUES),issues.json)" ] && \
	   [ "$(call last_modified,pulls.json)" -gt "$(call last_commit,$(GH_ISSUES),pulls.json)" ] 2>/dev/null; then \
	  echo 'Skipping update of issues.json and pulls.json (they are newer than the ones on the branch)'; exit; \
	fi; \
	skip=$(DISABLE_ISSUE_FETCH); \
	if [ $(CI) = true -a "$$skip" != true -a \
	     $$(($$(date '+%s')-28800)) -lt "$$(git log -n 1 --pretty=format:%ct $(GH_ISSUES) -- issues.json)" ] 2>/dev/null; then \
	    skip=true; echo 'Skipping update of issues.json and pulls.json (most recent update was in the last 8 hours)'; \
	fi; \
	if [ "$$skip" = true ]; then \
	    git show $(GH_ISSUES):issues.json > issues.json; \
		git show $(GH_ISSUES):pulls.json > pulls.json; \
		exit; \
	fi; \
	old_issues=$$(mktemp /tmp/issues-old.XXXXXX); \
	old_pulls=$$(mktemp /tmp/pulls-old.XXXXXX); \
	new_issues=$$(mktemp /tmp/issues-new.XXXXXX); \
	new_pulls=$$(mktemp /tmp/pulls-new.XXXXXX); \
	trap 'rm -f $$old_issues $$old_pulls $$new_issues $$new_pulls' EXIT; \
	git show $(GH_ISSUES):issues.json > $$old_issues; \
	git show $(GH_ISSUES):pulls.json > $$old_pulls; \
	$(LIBDIR)/archive_repo.py $(GITHUB_REPO_FULL) $$new_issues $$new_pulls -token $(GH_TOKEN) -date $$(git log -n 1 --pretty=format:%cI $(GH_ISSUES) -- issues.json) -ri $$old_issues -rp $$old_pulls --omit-old; \
	jq --slurpfile old_file $$old_issues --slurpfile new_file $$new_issues -n '$$old_file | .[0] as $$old | $$new_file | .[0] as $$new | $$new + $$old | unique_by(.id) | sort_by(.number)' > issues.json; \
	jq --slurpfile old_file $$old_pulls --slurpfile new_file $$new_pulls -n '$$old_file | .[0] as $$old | $$new_file | .[0] as $$new | $$new + $$old | unique_by(.id) | sort_by(.number)' > pulls.json; \


GHISSUES_ROOT := /tmp/ghissues$(shell echo $$$$)
$(GHISSUES_ROOT): fetch-ghissues
	@git show-ref refs/heads/$(GH_ISSUES) >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/$(GH_ISSUES) >/dev/null 2>&1 && \
	    git branch -t $(GH_ISSUES) origin/$(GH_ISSUES)) || \
	  ! echo 'Error: No $(GH_ISSUES) branch, run `make -f $(LIBDIR)/setup.mk setup-ghpages` to initialize it.'
	git clone -q -b $(GH_ISSUES) . $@

$(GHISSUES_ROOT)/%.json: %.json $(GHISSUES_ROOT)
	cp -f $< $@

## Commit and push the changes to $(GH_ISSUES)
.PHONY: ghissues gh-issues
gh-issues: ghissues
ghissues: $(GHISSUES_ROOT)/issues.json $(GHISSUES_ROOT)/pulls.json
	cp -f $(LIBDIR)/template/issues.html $(LIBDIR)/template/issues.js $(GHISSUES_ROOT)
	git -C $(GHISSUES_ROOT) add -f issues.json pulls.json issues.html issues.js
	if test `git -C $(GHISSUES_ROOT) status --porcelain issues.json pulls.json issues.js issues.html | wc -l` -gt 0; then \
	  git -C $(GHISSUES_ROOT) $(CI_AUTHOR) commit -m "Script updating issues at $(shell date -u +%FT%TZ). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(if $(CI_HAS_WRITE_KEY),1,$(if $(GH_TOKEN),,1)))
	git -C $(GHISSUES_ROOT) push https://github.com/$(GITHUB_REPO_FULL) $(GH_ISSUES)
else
	@echo git -C $(GHISSUES_ROOT) push -q https://github.com/$(GITHUB_REPO_FULL) $(GH_ISSUES)
	@git -C $(GHISSUES_ROOT) push -q https://$(GH_TOKEN)@github.com/$(GITHUB_REPO_FULL) $(GH_ISSUES) >/dev/null 2>&1
endif
else
	git -C $(GHISSUES_ROOT) push origin $(GH_ISSUES)
endif # PUSH_GHPAGES
	-rm -rf $(GHISSUES_ROOT)

## Save issues.json to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
.PHONY: artifacts
artifacts: issues.json pulls.json
endif
