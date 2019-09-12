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
issues: fetch-ghissues issues.json pulls.json
issues.json: $(drafts_source)
	@if [ -f $@ ] && [ "$(call last_modified,$@)" -gt "$(call last_commit,$(GH_ISSUES),$@)" ] 2>/dev/null; then \
	  echo 'Skipping update of $@ (it is newer than the one on the branch)'; exit; \
	fi; \
	skip=$(DISABLE_ISSUE_FETCH); \
	if [ $(CI) = true -a "$$skip" != true -a \
	     $$(($$(date '+%s')-28800)) -lt "$$(git log -n 1 --pretty=format:%ct $(GH_ISSUES) -- $@)" ] 2>/dev/null; then \
	    skip=true; echo 'Skipping update of $@ (most recent update was in the last 8 hours)'; \
	fi; \
	if [ "$$skip" = true ]; then \
	    git show $(GH_ISSUES):$@ > $@; exit; \
	fi; \
	tmp_headers=$$(mktemp /tmp/$(basename $(notdir $@))-headers.XXXXXX);  \
	tmp_old=$$(mktemp /tmp/$(basename $(notdir $@))-old.XXXXXX); \
	tmp_new=$$(mktemp /tmp/$(basename $(notdir $@))-new.XXXXXX); \
	trap 'rm -f $$tmp_headers $$tmp_new $$tmp_old' EXIT; \
	if git show $(GH_ISSUES):$@ > $$tmp_old && [ ! -s "$$tmp_old" ]; then \
		url="https://api.github.com/repos/$(GITHUB_REPO_FULL)$(basename $(notdir $@))?state=all&since=$$(git log -n 1 --pretty=format:%cI $(GH_ISSUES) -- $@)"; \
	    merge=true; \
	else \
		url="https://api.github.com/repos/$(GITHUB_REPO_FULL)$(basename $(notdir $@))?state=all"; \
		merge=false; \
	fi; \
	echo '[' > $$tmp_new; \
	while [ -n "$$url" ]; do \
	  echo "Fetching $(basename $(notdir $@)) from $$url"; \
	  echo $(curl) $(GITHUB_OAUTH) -D $$tmp_headers "$$url"; \
	  $(curl) $(GITHUB_OAUTH) -D $$tmp_headers "$$url" | sed -e '1s/^ *\[//;$$s/\] *$$//' >> $$tmp_new; \
	  if ! head -1 $$tmp_headers | grep -q ' 200 OK'; then \
	    echo "Error loading $$url:"; cat $$tmp; exit 1; \
	  fi; \
	  url=$$(sed -e 's/^Link:.*<\([^>]*\)>;[^,]*rel="next".*/\1/;t;d' $$tmp_headers); \
	  [ -n "$$url" ] && echo , >> $$tmp_new; \
	done; \
	echo ']' >> $$tmp_new; \
	if [ "$$merge" = true ]; then \
		jq --slurpfile old_file $$tmp_old --slurpfile new_file $$tmp_new -n '$$old_file | .[0] as $$old | $$new_file | .[0] as $$new | $$new + $$old | unique_by(.id) | sort_by(.number)' > $@; \
	else \
		mv $$tmp_new $@; \
	fi;


pulls.json: issues.json
	@if [ -f $@ ] && [ "$(call last_modified,$@)" -gt "$(call last_commit,$(GH_ISSUES),$@)" ] 2>/dev/null; then \
	  echo 'Skipping update of $@ (it is newer than the one on the branch)'; exit; \
	fi; \
	skip=$(DISABLE_ISSUE_FETCH); \
	if [ $(CI) = true -a "$$skip" != true -a \
	     $$(($$(date '+%s')-28800)) -lt "$$(git log -n 1 --pretty=format:%ct $(GH_ISSUES) -- $@)" ] 2>/dev/null; then \
	    skip=true; echo 'Skipping update of $@ (most recent update was in the last 8 hours)'; \
	fi; \
	if [ "$$skip" = true ]; then \
	    git show $(GH_ISSUES):$@ > $@; exit; \
	fi; \
	jq --slurpfile issues $< -n '[ $issues | .[] | map(select( .pull_request)) | sort_by(.number)]' > $@;


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
