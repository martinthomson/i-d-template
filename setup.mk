.PHONY: setup
setup: setup-default-branch setup-ghpages setup-precommit

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

LATEST_WARNING := $(strip $(foreach draft,$(drafts_source),\
	   $(shell grep -q $(basename $(draft))-latest $(draft) || \
		echo $(draft) should include a name of $(basename $(draft))-latest. )))
ifneq (,$(LATEST_WARNING))
$(warning Check names: $(LATEST_WARNING))
endif
ifneq (,$(strip $(shell git status -s --porcelain 2>/dev/null | egrep -v '^.. (.targets.mk|$(LIBDIR)/?|$(LIBDIR)/.template-files.mk)$$')))
$(error You have uncommitted changes or untracked files, please commit them before running setup)
endif
ifneq ($(GIT_REMOTE),$(shell git remote 2>/dev/null | grep '^$(GIT_REMOTE)$$'))
$(error Please configure a remote called '$(GIT_REMOTE)' before running setup)
endif
ifeq (,$(shell git show-ref $(GIT_REMOTE)/$(GIT_ORIG)))
$(error Please push the '$(GIT_ORIG)' branch to '$(GIT_REMOTE)', e.g., "git push $(GIT_REMOTE) $(GIT_ORIG)")
endif

TEMPLATE_FILES := \
  Makefile .gitignore \
  CONTRIBUTING.md LICENSE.md \
  .circleci/config.yml \
  $(addprefix .github/workflows/,ghpages.yml publish.yml archive.yml)

TEMPLATE_FILE_MK := $(LIBDIR)/.template-files.mk
include $(TEMPLATE_FILE_MK)
$(TEMPLATE_FILE_MK): $(LIBDIR)/setup.mk
	@echo '# Automatically generated setup rules' >$@
	@$(foreach f,$(TEMPLATE_FILES),\
	  echo $(f): $(LIBDIR)/template/$(f) >>$@;\
	  echo '	mkdir -p $$(dir $$@)' >>$@;\
	  echo '	-cp $$< $$@' >>$@;)

.PHONY: setup-files
setup-files: $(TEMPLATE_FILES) README.md .note.xml
	git add $(drafts_source)
	git add $^

ifeq (true,$(USE_XSLT))
setup-default-branch: setup-makefile-xslt
.PHONY: setup-makefile-xslt
setup-makefile-xslt: Makefile
	sed -i~ -e '1{h;s/^.*$$/USE_XSLT := true/;p;x;}' $<
	@-rm -f $<~
	git add $<
endif # USE_XSLT

ifneq (html,$(INDEX_FORMAT))
setup-default-branch: setup-makefile-index-format
.PHONY: setup-makefile-index-format
setup-makefile-index-format: Makefile
	sed -i~ -e '1{h;s/^.*$$/INDEX_FORMAT := $(INDEX_FORMAT)/;p;x;}' $<
	@-rm -f $<~
	git add $<
endif # INDEX_FORMAT

.PHONY: setup-gitignore
setup-gitignore: .gitignore $(LIBDIR)/template/.gitignore
	tmp=`mktemp`; cat $^ | sort -u >$$tmp && mv -f $$tmp $<
ifndef SUBMODULE
	echo $(LIBDIR) >>$<
endif
	$(foreach x,$(filter-out .xml,$(drafts_source)),\
	  echo $(basename $(x)).xml >>$<;)
	git add $<

README.md: $(LIBDIR)/setup-readme.sh $(drafts_xml) $(filter %.md, $(TEMPLATE_FILES))
	$(LIBDIR)/setup-readme.sh $(GITHUB_USER) $(GITHUB_REPO) $(filter %.xml,$^) >$@
	git add $@ $(filter %.md, $(TEMPLATE_FILES))

.note.xml: $(LIBDIR)/setup-note.sh
	$(LIBDIR)/setup-note.sh $(GITHUB_USER) $(GITHUB_REPO) $(drafts) >$@
	git add $@

.PHONY: setup-master
setup-master:
	$(error The setup-master make target was renamed to setup-default-branch)

.PHONY: setup-default-branch
setup-default-branch: setup-files README.md setup-gitignore
	git $(CI_AUTHOR) commit -m "Setup repository for $(firstword $(drafts)) using https://github.com/martinthomson/i-d-template"

.PHONY: setup-precommit
setup-precommit: .git/hooks/pre-commit
.git/hooks/pre-commit:
	-ln -s ../../lib/pre-commit.sh $@

.PHONY: setup-ghpages
setup-ghpages:
	$(LIBDIR)/setup-branch.sh gh-pages index.$(INDEX_FORMAT) archive.json
