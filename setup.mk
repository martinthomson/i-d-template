.PHONY: setup
setup: setup-master

LIBDIR ?= lib
include $(LIBDIR)/main.mk

# Check that everything is ready
ifeq (,$(wildcard .git))
$(error Please make sure that this is a git repository by running "git init")
endif
GIT_ORIG := $(shell git branch 2>/dev/null | grep '*' | cut -c 3-)
ifneq (1,$(words $(GIT_ORIG)))
$(error If you are just starting out, please commit something before starting)
endif
ifneq (master,$(GIT_ORIG))
$(warning Using a branch called 'master' is recommended)
endif
ifneq (1,$(words $(drafts)))
$(warning Sorry, but the setup works best with just one draft)
$(warning This will use $(firstword $(drafts)).)
endif

LATEST_WARNING := $(strip $(foreach draft,$(join $(drafts),$(draft_types)),\
	   $(shell grep -q $(basename $(draft))-latest $(draft) || \
		echo $(draft) should include a name of $(basename $(draft))-latest. )))
ifneq (,$(LATEST_WARNING))
$(warning Check names: $(LATEST_WARNING))
endif
ifneq (,$(strip $(shell git status -s --porcelain 2>/dev/null | egrep -v '^.. (.targets.mk|$(LIBDIR)/?|$(LIBDIR)/.template-files.mk)$$')))
$(error You have uncommitted changes, please commit them before running setup)
endif
ifneq ($(GIT_REMOTE),$(shell git remote 2>/dev/null | grep '^$(GIT_REMOTE)$$'))
$(error Please configure a remote called '$(GIT_REMOTE)' before running setup)
endif
ifeq (,$(shell git show-ref origin/$(GIT_ORIG)))
$(error Please push the '$(GIT_ORIG)' branch to '$(GIT_REMOTE)', e.g., "git push $(GIT_REMOTE) $(GIT_ORIG)")
endif

TEMPLATE_FILES := \
  Makefile .gitignore \
  README.md CONTRIBUTING.md LICENSE.md \
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
	git add $(join $(drafts),$(draft_types))
	git add $^

ifeq (true,$(USE_XSLT))
setup-master: setup-makefile setup-circle
.PHONY: setup-makefile
setup-makefile: Makefile
	sed -i~ -e '1{h;s/^.*$$/USE_XSLT := true/;p;x}' $<
	@-rm -f $<~
	git add $<

.PHONY: setup-circle
setup-circle: circle.yml
	sed -i~ -e '/^dependencies:/,/^  pre:$$/{p;s/^  pre:$$/    - sudo apt-get -qq update; sudo apt-get -q install xsltproc/;t;d}' $<
	@-rm -f $<~
	git add $<
endif # USE_XSLT

.PHONY: setup-gitignore
setup-gitignore: .gitignore
ifndef SUBMODULE
	echo $(LIBDIR) >>$<
endif
	$(foreach x,$(filter-out .xml,$(join $(drafts),$(draft_types))),\
	  echo $(basename $(x)).xml >>$<;)
	git add $<

.PHONY: setup-markdown
setup-markdown: $(firstword $(drafts)).xml $(MARKDOWN_FILES)
	DRAFT_NAME=$$(echo $< | cut -f 1 -d . -); \
	  AUTHOR_LABEL=$$(echo $< | cut -f 2 -d - -); \
	  WG_NAME=$$(echo $< | cut -f 3 -d - -); \
	  DRAFT_STATUS=$$(test "$$AUTHOR_LABEL" = ietf && echo Working Group || echo Individual); \
	  GITHUB_USER=$(GITHUB_USER); GITHUB_REPO=$(GITHUB_REPO); \
	  DRAFT_TITLE=$$(sed -e '/<title[^>]*>/,/<\/title>/{s/.*<title[^>]*>//;/<\/title>/{s/<\/title>.*//;H;x;q;};H;};d' $< | xargs echo); \
	  sed -i~ $(foreach label,DRAFT_NAME DRAFT_TITLE DRAFT_STATUS GITHUB_USER GITHUB_REPO WG_NAME,-e 's~{$(label)}~'"$$$(label)"'~g') $(MARKDOWN_FILES)
	@-rm -f $(addsuffix ~,$(MARKDOWN_FILES))
	git add $(MARKDOWN_FILES)

.PHONY: setup-master
setup-master: setup-files setup-markdown setup-gitignore
	git $(CI_AUTHOR) commit -m "Setup repository for $(firstword $(drafts)) using https://github.com/martinthomson/i-d-template"
	-ln -s ../../lib/pre-commit.sh .git/hooks/pre-commit

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
	git clone -n . $(GHPAGES_TMP)
	git -C $(GHPAGES_TMP) checkout -q --orphan gh-pages
	git -C $(GHPAGES_TMP) rm -rfq .
	@echo Creating index.html and circle.yml
	@touch $(GHPAGES_TMP)/index.html
	@echo 'general:' >$(GHPAGES_TMP)/circle.yml
	@echo '  branches:' >>$(GHPAGES_TMP)/circle.yml
	@echo '    ignore:' >>$(GHPAGES_TMP)/circle.yml
	@echo '      - gh-pages' >>$(GHPAGES_TMP)/circle.yml
	@echo lib > $(GHPAGES_TMP)/.gitignore
	@echo venv >> $(GHPAGES_TMP)/.gitignore
	@echo .refcache >> $(GHPAGES_TMP)/.gitignore
	git -C $(GHPAGES_TMP) add index.html circle.yml .gitignore
	git -C $(GHPAGES_TMP) $(CI_AUTHOR) commit -m "Automatic setup of gh-pages."
	git -C $(GHPAGES_TMP) push origin gh-pages
	git push --set-upstream $(GIT_REMOTE) gh-pages
	-rm -rf $(GHPAGES_TMP)


GHISSUES_COMMITS := $(shell git show-ref -s gh-issues 2>/dev/null)
ifeq (,$(strip $(GHISSUES_COMMITS)))
setup: setup-ghissues
else
$(warning The gh-issues branch already exists, skipping setup for that.)
endif

.PHONY: setup-ghissues
setup-ghissues:
	@echo "Initializing gh-issues branch"
	git clone -n . $(GHISSUES_TMP)
	git -C $(GHISSUES_TMP) checkout -q --orphan gh-issues
	git -C $(GHISSUES_TMP) rm -rfq .
	@echo Creating issues.json and circle.yml
	touch $(GHISSUES_TMP)/issues.json
	@echo 'general:' >$(GHISSUES_TMP)/circle.yml
	@echo '  branches:' >>$(GHISSUES_TMP)/circle.yml
	@echo '    ignore:' >>$(GHISSUES_TMP)/circle.yml
	@echo '      - gh-issues' >>$(GHISSUES_TMP)/circle.yml
	@echo lib > $(GHISSUES_TMP)/.gitignore
	@echo venv >> $(GHISSUES_TMP)/.gitignore
	@echo .refcache >> $(GHISSUES_TMP)/.gitignore
	git -C $(GHISSUES_TMP) add issues.json circle.yml .gitignore
	git -C $(GHISSUES_TMP) $(CI_AUTHOR) commit -m "Automatic setup of gh-issues."
	git -C $(GHISSUES_TMP) push origin gh-issues
	git push --set-upstream $(GIT_REMOTE) gh-issues
	-rm -rf $(GHISSUES_TMP)
