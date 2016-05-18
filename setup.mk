.PHONY: setup
setup: setup-master

LIBDIR ?= lib
include $(LIBDIR)/main.mk

# Check that everything is ready
ifeq (,$(wildcard .git))
$(error Please make sure that this is a git repository)
endif
GIT_ORIG := $(shell git branch 2>/dev/null | grep '*' | cut -c 3-)
ifneq (1,$(words $(GIT_ORIG)))
$(error If you are just starting out, please commit something before starting)
endif
ifneq (master,$(GIT_ORIG))
$(warning Using a branch called 'master' is recommended.)
endif
ifneq (1,$(words $(drafts)))
$(warning Sorry, but the setup works best with just one draft.)
$(warning This will use $(firstword $(drafts)).)
endif

LATEST_WARNING := $(strip $(foreach draft,$(join $(drafts),$(draft_types)),\
	   $(shell grep -q $(basename $(draft))-latest $(draft) || \
		echo $(draft) should include a name of $(basename $(draft))-latest. )))
ifneq (,$(LATEST_WARNING))
$(warning Check names: $(LATEST_WARNING))
endif
ifneq (0,$(strip $(shell git status -s --porcelain 2>/dev/null | grep -v '^.. $(LIBDIR)/\?$$' | wc -l)))
$(error You have uncommitted changes, please commit them before running setup)
endif
ifneq ($(GIT_REMOTE),$(shell git remote 2>/dev/null | grep '^$(GIT_REMOTE)$$'))
$(error Please configure a remote called '$(GIT_REMOTE)' before running setup)
endif

TEMPLATE_FILES := \
  Makefile .gitignore \
  README.md CONTRIBUTING.md \
  .travis.yml circle.yml

MARKDOWN_FILES := $(filter %.md,$(TEMPLATE_FILES))

TEMPLATE_FILE_MK := $(LIBDIR)/.template-files.mk
include $(TEMPLATE_FILE_MK)
$(TEMPLATE_FILE_MK): $(LIBDIR)/setup.mk
	@echo '# Automatically generated setup rules' >$@
	@$(foreach f,$(TEMPLATE_FILES),\
	  echo $(f): $(LIBDIR)/template/$(f) >>$@;\
	  echo '	-cp $$< $$@' >>$@;)

.PHONY: setup-files
setup-files: $(TEMPLATE_FILES)
	cp -f $(LIBDIR)/template/README.md README.md
	git add $(join $(drafts),$(draft_types))
	git add $^

.PHONY: setup-gitignore
setup-gitignore: .gitignore
ifndef SUBMODULE
	echo $(LIBDIR) >>$<
endif
	$(foreach x,$(filter-out .xml,$(join $(drafts),$(draft_types))),\
	  echo $(x) >>$<;)
	git add $<

.PHONY: setup-markdown
setup-markdown: $(firstword $(drafts)).xml $(MARKDOWN_FILES)
	DRAFT_NAME=$$(echo $< | cut -f 1 -d . -); \
	  AUTHOR_LABEL=$$(echo $< | cut -f 2 -d - -); \
	  WG_NAME=$$(echo $< | cut -f 3 -d - -); \
	  DRAFT_STATUS=$$(test "$$AUTHOR_LABEL" = ietf && echo Working Group || echo Individual); \
	  GITHUB_USER=$(GITHUB_USER); GITHUB_REPO=$(GITHUB_REPO); \
	  DRAFT_TITLE=$$(sed -e '/<title[^>]*>[^<]*$$/{s/.*>//g;H;};/<\/title>/{H;x;s/.*<title/</g;s/<[^>]*>//g;q;};d' $<); \
	  sed -i~ $(foreach label,DRAFT_NAME DRAFT_TITLE DRAFT_STATUS GITHUB_USER GITHUB_REPO WG_NAME,-e 's~{$(label)}~'"$$$(label)"'~g') $(MARKDOWN_FILES)
	@-rm -f $(addsuffix ~,$(MARKDOWN_FILES))
	git add $(MARKDOWN_FILES)

.PHONY: setup-master
setup-master: setup-files setup-markdown setup-gitignore
	git commit -m "Setup repository for $(firstword $(drafts))"

# Check if the gh-pages branch already exists either remotely or locally
GHPAGES_COMMITS := $(shell git show-ref -s gh-pages 2>/dev/null)
ifeq (,$(strip $(GHPAGES_COMMITS)))
setup: setup-ghpages
else
$(warning The gh-pages branch already exists, skipping setup for that.)
endif

.PHONY: setup-ghpages
setup-ghpages:
	@echo "Initializing gh-pages branch"
	git checkout --orphan gh-pages
	git rm -rf .
	@echo Creating index.html and circle.yml
	@touch index.html
	@echo 'general:' >circle.yml
	@echo '  branches:' >>circle.yml
	@echo '    ignore:' >>circle.yml
	@echo '      - gh-pages' >>circle.yml
	@echo lib > .gitignore
	@echo venv >> .gitignore
	@echo .refcache >> .gitignore
	git add index.html circle.yml .gitignore
	git commit -m "Automatic setup of gh-pages."
	git clean -qfdX
	git push --set-upstream $(GIT_REMOTE) gh-pages
	git checkout -qf "$(GIT_ORIG)"
