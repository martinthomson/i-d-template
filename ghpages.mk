## Update the gh-pages branch with useful files

GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
.INTERMEDIATE: $(GHPAGES_TMP)
ifneq (,$(CI_BRANCH))
GIT_ORIG := $(CI_BRANCH)
else
GIT_ORIG := $(shell git branch | grep '*' | cut -c 3-)
endif
ifneq (,$(findstring detached from,$(GIT_ORIG)))
GIT_ORIG := $(shell git show -s --format='format:%H')
endif

# Only run upload if we are local or on the master branch
IS_LOCAL := $(if $(CI),,true)
ifeq (master,$(CI_BRANCH))
IS_MASTER := $(findstring false,$(CI_IS_PR))
else
IS_MASTER :=
endif

define INDEX_HTML =
<!DOCTYPE html>\n\
<html>\n\
<head><title>$(GITHUB_REPO) drafts</title></head>\n\
<body><ul>\n\
$(foreach draft,$(drafts),<li><a href="$(draft).html">$(draft)</a> (<a href="$(draft).txt">txt</a>)</li>\n)\
</ul></body>\n\
</html>
endef

index.html: $(drafts_html) $(drafts_txt)
ifeq (1,$(words $(drafts)))
	cp $< $@
else
	echo -e '$(INDEX_HTML)' >$@
endif

.PHONY: ghpages
ghpages: index.html $(drafts_html) $(drafts_txt)
ifneq (true,$(CI))
	@git show-ref refs/heads/gh-pages > /dev/null 2>&1 || \
	  ! echo 'Error: No gh-pages branch, run `make setup-ghpages` to initialize it.'
endif
ifneq (,$(or $(IS_LOCAL),$(IS_MASTER)))
	mkdir $(GHPAGES_TMP)
	cp -f $^ $(GHPAGES_TMP)
	git clean -qfdX
ifeq (true,$(CI))
	git config user.email "ci-bot@example.com"
	git config user.name "CI Bot"
	git checkout -q --orphan gh-pages
	git rm -qr --cached .
	git clean -qfd
	git pull -qf origin gh-pages --depth=5
else
	git checkout gh-pages
	git pull
endif
	mv -f $(GHPAGES_TMP)/* $(CURDIR)
	git add $^
	if test `git status -s | wc -l` -gt 0; then git commit -m "Script updating gh-pages. [ci skip]"; fi
ifneq (,$(GH_TOKEN))
	@echo git push -q https://github.com/$(CI_REPO_FULL).git gh-pages
	@git push -q https://$(GH_TOKEN)@github.com/$(CI_REPO_FULL).git gh-pages
endif
	-git checkout -qf "$(GIT_ORIG)"
	-rm -rf $(GHPAGES_TMP)
endif
