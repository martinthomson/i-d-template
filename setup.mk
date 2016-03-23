.PHONY: setup
setup: setup-readme setup-ghpages

LIBDIR ?= lib
include $(LIBDIR)/main.mk

TEMPLATE_FILES := \
  Makefile .gitignore \
  README.md CONTRIBUTING.md \
  .travis.yml circle.yml

.PHONY: setup-readme
setup-readme: $(addsuffix .xml,$(drafts)) $(TEMPLATE_FILES)
ifneq (1,$(words $(drafts)))
	@! echo "Error: This setup only works with a single draft"
endif
	git add $(addsuffix $(firstword $(draft_types)),$(basename $<))
	DRAFT_NAME=$$(echo $< | cut -f 1 -d . -); \
	  AUTHOR_LABEL=$$(echo $< | cut -f 2 -d - -); \
	  WG_NAME=$$(echo $< | cut -f 3 -d - -); \
	  DRAFT_STATUS=$$(test "$$AUTHOR_LABEL" = ietf && echo Working Group || echo Individual); \
	  GITHUB_USER=$(GITHUB_USER); GITHUB_REPO=$(GITHUB_REPO); \
	  DRAFT_TITLE=$$(sed -e '/<title[^>]*>[^<]*$$/{s/.*>//g;H;};/<\/title>/{H;x;s/.*<title/</g;s/<[^>]*>//g;q;};d' $<); \
	  sed -i~ $(foreach label,DRAFT_NAME DRAFT_TITLE DRAFT_STATUS GITHUB_USER GITHUB_REPO WG_NAME,-e 's~{$(label)}~'"$$$(label)"'~g') $(filter %.md,$(TEMPLATE_FILES))
	@-rm -f $(addsuffix ~,$(TEMPLATE_FILES))
	git add $(TEMPLATE_FILES)
ifndef SUBMODULE
	echo $(LIBDIR) >> .gitignore
	git add .gitignore
endif
ifneq (xml,$(firstword $(draft_types)))
	echo $< >> .gitignore
	git add .gitignore
endif
	git commit -m "Setup repository for $(basename $<)"

$(TEMPLATE_FILES): $(addprefix $(LIBDIR)/template/,$(TEMPLATE_FILES))
	cp -u $? .

GIT_ORIG := $(shell git branch | grep '*' | cut -c 3-)
ifneq (1,$(words $(GIT_ORIG)))
$(error Unable to work from non-branch: $(GIT_ORIG))
endif

.PHONY: setup-ghpages
setup-ghpages:
# Abort if there are local changes
	@test `git status -s | wc -l` -eq 0 || \
	  ! echo "Error: Uncommitted changes on branch"
	@git remote show -n origin >/dev/null 2>&1 || \
	  ! echo "Error: No remote named 'origin' configured"
# Check if the gh-pages branch already exists locally
	@if git show-ref refs/heads/gh-pages >/dev/null 2>&1; then \
	  ! echo "Error: gh-pages branch already exists"; \
	else true; fi
# Check if the gh-pages branch already exists on origin
	@if git show-ref origin/gh-pages >/dev/null 2>&1; then \
	  echo 'Warning: gh-pages already present on the origin'; \
	  git branch gh-pages origin/gh-pages; false; \
	else true; fi
	@echo "Initializing gh-pages branch"
	git checkout --orphan gh-pages
	git rm -rf .
	touch index.html
	echo 'general:' >circle.yml
	echo '  branches:' >>circle.yml
	echo '    ignore:' >>circle.yml
	echo '      - gh-pages' >>circle.yml
	git add index.html circle.yml
	git commit -m "Automatic setup of gh-pages."
	git push --set-upstream origin gh-pages
	git checkout -qf "$(GIT_ORIG)"
	git clean -qfdX
