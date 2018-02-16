GH_ISSUES := gh-pages
.PHONY: fetch-ghissues
fetch-ghissues:
	-git fetch -q origin $(GH_ISSUES):$(GH_ISSUES)

## Store a copy of any github issues
.PHONY: issues
issues: issues.json pulls.json
issues.json pulls.json: fetch-ghissues $(drafts_source)
ifeq (,$(DISABLE_ISSUE_FETCH))
	@echo '[' > $@
	@tmp=$$(mktemp /tmp/$(basename $(notdir $@)).XXXXXX); \
	if [ $(CI) = true -a -n "$$(git rev-list -n 1 --since=$$(($$(date '+%s')-28800)) $(GH_ISSUES) -- $@)" ]; then \
	    echo 'Skipping update of $@ (most recent update was in the last 8 hours)'; \
	    git show $(GH_ISSUES):$@ | head -n -1 | tail -n +2 >> $@; \
	    exit; \
	fi; \
	url=https://api.github.com/repos/$(GITHUB_REPO_FULL)/$(basename $(notdir $@))?state=all; \
	while [ "$$url" != "" ]; do \
	   echo Fetching $(basename $(notdir $@)) from $$url; \
	   $(curl) $$url -D $$tmp | head -n -1 | tail -n +2 >> $@; \
	   if ! head -1 $$tmp | grep -q ' 200 OK'; then \
	       echo "Error loading $$url:"; cat $$tmp; exit 1; \
	   fi; \
	   url=$$(sed -e 's/^Link:.*<\([^>]*\)>;[^,]*rel="next".*/\1/;t;d' $$tmp); \
	   if [ "$$url" != "" ]; then echo , >> $@; fi; \
	done; \
	rm -f $$tmp
	@echo ']' >> $@
else
	git show $(GH_ISSUES):$@ >> $@
endif

GHISSUES_ROOT := /tmp/ghissues$(shell echo $$$$)
$(GHISSUES_ROOT): fetch-ghissues
	@git show-ref refs/heads/$(GH_ISSUES) >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/$(GH_ISSUES) >/dev/null 2>&1 && \
	    git branch -t $(GH_ISSUES) origin/$(GH_ISSUES)) || \
	  ! echo 'Error: No $(GH_ISSUES) branch, run `make -f $(LIBDIR)/setup.mk setup-issues` to initialize it.'
	git clone -q -b $(GH_ISSUES) . $@

$(GHISSUES_ROOT)/%.json: %.json $(GHISSUES_ROOT)
	cp -f $< $@

## Commit and push the changes to $(GH_ISSUES)
.PHONY: ghissues gh-issues
gh-issues: ghissues
ghissues: $(GHISSUES_ROOT)/issues.json $(GHISSUES_ROOT)/pulls.json
	cp -f $(LIBDIR)/template/issues.html $(LIBDIR)/template/issues.js $(GHISSUES_ROOT)
	git -C $(GHISSUES_ROOT) add -f issues.json pulls.json issues.html issues.js
	if test `git -C $(GHISSUES_ROOT) status --porcelain issues.json issues.js issues.html | wc -l` -gt 0; then \
	  git -C $(GHISSUES_ROOT) $(CI_AUTHOR) commit -m "Script updating issues at $(shell date -u +%FT%TZ). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(if $(CI_HAS_WRITE_KEY),1,$(if $(GH_TOKEN),,1)))
	git -C $(GHISSUES_ROOT) push https://github.com/$(CI_REPO_FULL) $(GH_ISSUES)
else
	@echo git -C $(GHISSUES_ROOT) push -q https://github.com/$(CI_REPO_FULL) $(GH_ISSUES)
	@git -C $(GHISSUES_ROOT) push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL) $(GH_ISSUES) >/dev/null 2>&1
endif
else
	git -C $(GHISSUES_ROOT) push origin $(GH_ISSUES)
endif # PUSH_GHPAGES
	-rm -rf $(GHISSUES_ROOT)

## Save issues.json to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
ifeq (true,$(SAVE_ISSUES_ARTIFACT))
.PHONY: artifacts
artifacts: issues.json pulls.json
endif
endif
