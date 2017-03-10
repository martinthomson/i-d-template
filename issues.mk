## Store a copy of any github issues
.PHONY: issues
issues: issues.json
issues.json: $(drafts_source)
	@echo '[' > $@
ifeq (,$(SELF_TEST))
	@tmp=$$(mktemp /tmp/issues.XXXXXX); \
	url=https://api.github.com/repos/$(GITHUB_REPO_FULL)/issues?state=open; \
	while [ "$$url" != "" ]; do \
	   echo Fetching issues from $$url; \
	   curl -s $$url -D $$tmp | head -n -1 | tail -n +2 >> $@; \
	   url=$$(sed -e 's/^Link:.*<\([^>]*\)>;[^,]*rel="next".*/\1/;t;d' $$tmp); \
	   if [ "$$url" != "" ]; then echo , >> $@; fi; \
	done; \
	rm -f $$tmp
else
	echo '{}' >> $@
endif
	@echo ']' >> $@

.PHONY: fetch-ghissues
fetch-ghissues:
	-git fetch -q origin gh-issues:gh-issues

GHISSUES_TMP := /tmp/ghissues$(shell echo $$$$)
.INTERMEDIATE: $(GHISSUES_TMP)
$(GHISSUES_TMP): fetch-ghissues
	@git show-ref refs/heads/gh-issues >/dev/null 2>&1 || \
	  (git show-ref refs/remotes/origin/gh-issues >/dev/null 2>&1 && \
	    git branch -t gh-issues origin/gh-issues) || \
	  ! echo 'Error: No gh-issues branch, run `make -f $(LIBDIR)/setup.mk setup-issues` to initialize it.'
	git clone -q -b gh-issues . $@

$(GHISSUES_TMP)/issues.json: issues.json $(GHISSUES_TMP)
	cp -f $< $@


## Commit and push the changes to gh-issues
.PHONY: ghissues gh-issues
gh-issues: ghissues
ghissues: $(GHISSUES_TMP)/issues.json

	git -C $(GHISSUES_TMP) add -f issues.json
	if test `git -C $(GHISSUES_TMP) status --porcelain issues.json | wc -l` -gt 0; then \
	  git -C $(GHISSUES_TMP) $(CI_AUTHOR) commit -m "Script updating gh-issues at $(shell date -u +%FT%TZ). [ci skip]"; fi
ifeq (true,$(PUSH_GHPAGES))
ifneq (,$(CI_HAS_WRITE_KEY))
	git -C $(GHISSUES_TMP) push https://github.com/$(CI_REPO_FULL).git gh-issues
else
ifneq (,$(GH_TOKEN))
	@echo git -C $(GHISSUES_TMP) push -q https://github.com/$(CI_REPO_FULL) gh-issues
	@git -C $(GHISSUES_TMP) push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL) gh-issues >/dev/null 2>&1
else
	git -C $(GHISSUES_TMP) push origin gh-issues
endif
endif
	-rm -rf $(GHISSUES_TMP)
endif # PUSH_GHPAGES


## Save issues.json to the CI_ARTIFACTS directory
ifneq (,$(CI_ARTIFACTS))
ifeq (true,$(SAVE_ISSUES_ARTIFACT))
.PHONY: artifacts
artifacts: issues.json
endif
endif
