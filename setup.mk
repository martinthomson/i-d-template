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

LATEST_WARNING := $(strip $(foreach draft,$(join $(drafts),$(draft_types)),\
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
	git add $(join $(drafts),$(draft_types))
	git add $^

ifeq (true,$(USE_XSLT))
setup-default-branch: setup-makefile
.PHONY: setup-makefile
setup-makefile: Makefile
	sed -i~ -e '1{h;s/^.*$$/USE_XSLT := true/;p;x;}' $<
	@-rm -f $<~
	git add $<
endif # USE_XSLT

.PHONY: setup-gitignore
setup-gitignore: .gitignore $(LIBDIR)/template/.gitignore
	tmp=`mktemp`; cat $^ | sort -u >$$tmp && mv -f $$tmp $<
ifndef SUBMODULE
	echo $(LIBDIR) >>$<
endif
	$(foreach x,$(filter-out .xml,$(join $(drafts),$(draft_types))),\
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
	$(LIBDIR)/setup-branch.sh gh-pages index.html archive.json
