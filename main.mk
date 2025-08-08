ifeq (,$(TRACE_FILE))
SUMMARY_REPORT ?= $(GITHUB_STEP_SUMMARY)
ifneq (,$(SUMMARY_REPORT))
TRACE_FILE := $(shell mktemp)
export TRACE_FILE

define MAKE_TRACE
$(MAKE) -k $(1); \
  STATUS=$$?; \
  $(LIBDIR)/format-trace.sh $(TRACE_FILE) $$STATUS >>$(SUMMARY_REPORT); \
  rm -f $(TRACE_FILE); \
  exit $$STATUS
endef

all::
	@$(call MAKE_TRACE,latest lint)
else
all:: latest lint
endif # SUMMARY_REPORT
endif # TRACE_FILE

latest:: txt html

MAKEFLAGS += --no-builtin-rules --no-builtin-variables --no-print-directory
.PHONY: all latest
.SUFFIXES:
.DELETE_ON_ERROR:

## Modularity
# Basic files (these can't rely on details from .targets.mk)
LIBDIR ?= lib
export LIBDIR
include $(LIBDIR)/config.mk
include $(LIBDIR)/id.mk
include $(LIBDIR)/deps.mk

# Now include the advanced stuff that can depend on draft information.
include $(LIBDIR)/ghpages.mk
include $(LIBDIR)/archive.mk
include $(LIBDIR)/upload.mk
include $(LIBDIR)/update.mk

-include .includes.mk
.includes.mk: $(filter %.md,$(drafts_source))
	@rm -f $@
	@for d in $^; do \
	  for f in $$(sed -e $$'s/^{::include\\(-nested\\)* \\(.*\\)}$$/\\2/;t\nd' "$$d"); do \
	    echo "$${d%.md}.xml: $$f" >> $@; \
	  done; \
	done

## Basic Targets
.PHONY: txt html pdf
txt:: $(drafts_txt)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(drafts_source),$(addsuffix .xml,$(drafts)))

ifeq (true,$(CI))
VERBOSE ?= true
endif
ifeq (true,$(VERBOSE))
trace := $(trace) -v
echo := echo
at :=
else
echo := :
at := @
endif

MD_PRE =
ifneq (,$(MD_PREPROCESSOR))
MD_PRE += | $(trace) $@ -s preprocessor $(MD_PREPROCESSOR)
endif
ifneq (1,$(words $(drafts)))
NOT_CURRENT = $(filter-out $(basename $<),$(drafts))
MD_PRE += | sed -e '$(join $(addprefix s/,$(addsuffix -latest/,$(NOT_CURRENT))), \
		$(addsuffix /g;,$(NOT_CURRENT)))'
endif
MD_POST = | $(trace) -q $@ -s venue $(python) $(LIBDIR)/add-note.py
ifneq (true,$(USE_XSLT))
MD_POST += | $(trace) -q $@ -s v2v3 $(xml2rfc) --v2v3 /dev/stdin -o /dev/stdout
endif
ifeq (true,$(TIDY))
MD_POST += | $(trace) -q $@ -s tidy $(rfc-tidy)
endif

%.xml: %.md $(DEPS_FILES)
	@h=$$(head -1 $< | cut -c 1-4 -); set -o pipefail; \
	if [ "$${h:0:1}" = $$'\ufeff' ]; then echo 'warning: BOM in $<' 1>&2; h="$${h:1:3}"; \
	else h="$${h:0:3}"; fi; \
	if [ "$$h" = '---' ]; then \
	  $(echo) '$(subst ','"'"',cat $< $(MD_PRE) | $(kramdown-rfc) --v3 $(MD_POST) >$@)'; \
	  cat $< $(MD_PRE) | $(trace) $@ -s kramdown-rfc $(kramdown-rfc) --v3 $(MD_POST) >$@; \
	elif [ "$$h" = '%%%' ]; then \
	  $(echo) '$(subst ','"'"',cat $< $(MD_PRE) | $(mmark) $(MD_POST) >$@)'; \
	  cat $< $(MD_PRE) | $(trace) $@ -s mmark $(mmark) $(MD_POST) >$@; \
	else \
	  ! echo "Unable to detect '%%%' or '---' in markdown file" 1>&2; \
	fi && [ -e $@ ]

%.xml: %.org $(DEPS_FILES)
	$(trace) $@ -s oxtradoc $(oxtradoc) -m outline-to-xml -n "$@" $< | $(xml2rfc) --v2v3 /dev/stdin -o $@

XSLTDIR ?= $(LIBDIR)/rfc2629xslt
ifeq (true,$(USE_XSLT))
$(LIBDIR)/rfc2629.xslt: $(XSLTDIR)/rfc2629.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(LIBDIR)/clean-for-DTD.xslt: $(LIBDIR)/rfc2629xslt/clean-for-DTD.xslt $(LIBDIR)/rfc2629-no-doctype.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(LIBDIR)/rfc2629-no-doctype.xslt: $(LIBDIR)/rfc2629xslt/rfc2629-no-doctype.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(XSLTDIR)/clean-for-DTD.xslt $(XSLTDIR)/rfc2629.xslt: $(XSLTDIR)
$(XSLTDIR):
	git clone --depth 10 $(CLONE_ARGS) -b master https://github.com/reschke/xml2rfc $@

%.cleanxml: %.xml $(LIBDIR)/clean-for-DTD.xslt $(LIBDIR)/rfc2629.xslt
	$(at)$(trace) $@ -s xslt-clean $(xsltproc) --novalid $(LIBDIR)/clean-for-DTD.xslt $< > $@

%.html: %.xml $(LIBDIR)/rfc2629.xslt $(LIBDIR)/style.css
	$(at)$(trace) $@ -s xslt-html $(xsltproc) --novalid --stringparam xml2rfc-ext-css-contents "$$(cat $(LIBDIR)/style.css)" $(LIBDIR)/rfc2629.xslt $< > $@

%.txt: %.cleanxml $(DEPS_FILES)
	$(at)$(trace) $@ -s xml2rfc-txt $(xml2rfc) $(XML2RFC_TEXT) $< -o $@
else
%.html: %.xml $(XML2RFC_CSS) $(DEPS_FILES)
	$(at)$(trace) $@ -s xml2rfc-html $(xml2rfc) $(XML2RFC_HTML) $< -o $@
# Workaround for https://trac.tools.ietf.org/tools/xml2rfc/trac/ticket/470
	@-sed -i.rfc-local -e 's,<link[^>]*href=["'"'"]rfc-local.css["'"'"][^>]*>,,' $@; rm -f $@.rfc-local
ifneq (,$(FAVICON))
	@-sed -i.favicon -e '/<link[^>]*rel="license">/{p;c \'$$'\n''$(FAVICON)'$$'\n'';}' $@; rm -f $@.favicon
endif

%.txt: %.xml $(DEPS_FILES)
	$(at)$(trace) $@ -s xml2rfc-txt $(xml2rfc) $(XML2RFC_TEXT) $< -o $@
endif

%.pdf: %.txt
	$(at)$(trace) $@ -s enscript $(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

## Build copies of drafts for submission
.PHONY: next
next:: $(drafts_next_txt) $(drafts_next_xml)

## Remind people to use CI
.PHONY: submit
submit::
	@echo "\`make submit\` is not really necessary."
	@echo "\`make\` on its own is a pretty good preview."
	@echo "To upload a new draft to datatracker, enable CI and try this:"
	@echo
	@for i in $(drafts_next); do \
	  echo "    git tag -a $$i"; \
	done
	@for i in $(drafts_next); do \
	  echo "    git push origin $$i"; \
	done
	@echo
	@echo "Don't forget the \`-a\`."
	@echo
	@echo "To get a preview, use \`make next\`."

## Check for validity
.PHONY: check idnits
check:: idnits

# Mode can be "normal", "submission", or "forgive-checklist"
idnits_mode ?= normal
ifneq (true,$(NO_NODEJS))
idnits_bin ?= node_modules/.bin/idnits
$(idnits_bin):
	npm install -q --no-save github:ietf-tools/idnits
else
idnits_bin :=
endif

idnits:: $(drafts_next_xml) | $(idnits_bin)
	@for i in $^; do \
	  [ "$$i" == "$(idnits_bin)" ] || \
	    $(trace) "$$i" -s idnits $(idnits) -m $(idnits_mode) "$$i"; \
	done

CODESPELL_ARGS :=
ifneq (,$(wildcard ./.ignore-words))
CODESPELL_ARGS += -I .ignore-words
endif

.PHONY: spellcheck
spellcheck:: $(drafts_source) $(VENV)/codespell$(EXE)
	$(trace) $@ codespell $(CODESPELL_ARGS) $(drafts_source)

## Build diffs between the current draft versions and the most recent version
draft_diffs := $(addprefix diff-,$(addsuffix .html,$(drafts_with_prev)))
.PHONY: diff
diff: $(draft_diffs)

.PHONY: lint lint-whitespace lint-default-branch lint-docname
lint::
ifneq (true,$(CI))
lint:: lint-default-branch
endif
ifneq (true,$(PRE_SETUP))
# Disable most lints during repository setup
lint:: lint-docname lint-whitespace
endif

lint-whitespace::
	@err=0; for f in $(drafts_source); do \
	  if [  ! -z "$$(tail -c 1 "$$f")" ]; then \
	    $(trace) -q "$$f" -s nl ! echo "$$f has no newline on the last line"; err=1; \
	  fi; \
	  if ! $(trace) -q "$$f" -s ws ! grep -n $$' \r*$$' "$$f"; then \
	    $(if $(TRACE_FILE),echo "$${f%.*} ws $$f contains trailing whitespace" >>$(TRACE_FILE);) \
	    echo "$$f contains trailing whitespace"; err=1; \
	  fi; \
	done; [ "$$err" -eq 0 ] || ! echo "*** Run 'make fix-lint' to automatically fix some errors" 1>&2

lint-default-branch::
	@-if ! git rev-parse --abbrev-ref refs/remotes/$(GIT_REMOTE)/HEAD >/dev/null 2>&1; then \
	  echo "warning: A default branch for '$(GIT_REMOTE)' is not recorded in this clone."; \
	  echo "         Running 'make fix-lint' will set the default branch to '$$(git rev-parse --abbrev-ref HEAD)'."; \
	fi

lint-docname::
	@err=(); for f in $(drafts_source); do \
	  if [ "$${f#draft-}" != "$$f" ] && ! grep -q "$${f%.*}-latest" "$$f"; then \
	    $(trace) "$$f" -s lint-docname ! echo "$$f does not contain its own name ($${f%.*}-latest)"; err=1; \
	  fi; \
	done; [ "$${#err}" -eq 0 ] || ! echo "*** Correct the name of drafts in docname or similar fields" 1>&2

.PHONY: fix-lint fix-lint-whitespace fix-lint-default-branch
fix-lint:: fix-lint-whitespace fix-lint-default-branch
fix-lint-whitespace::
	for f in $(drafts_source); do \
	  [  -z "$$(tail -c 1 "$$f")" ] || echo >>"$$f"; \
	done
	sed -i~ -e 's/ *$$//' $(drafts_source)

fix-lint-default-branch:
	if ! git rev-parse --abbrev-ref refs/remotes/$(GIT_REMOTE)/HEAD >/dev/null 2>&1; then \
	  echo "ref: refs/remotes/$(GIT_REMOTE)/$$(git rev-parse --abbrev-ref HEAD)" > $$(git rev-parse --git-dir)/refs/remotes/$(GIT_REMOTE)/HEAD; \
	fi

## Cleanup
COMMA := ,
.PHONY: clean clean-all
clean::
	-rm -f .tags $(targets_file) issues.json \
	    $(addsuffix .{txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html \
	    $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)raw.txt$(COMMA)html$(COMMA)pdf},$(drafts)) \
	    $(filter-out $(drafts_source),$(addsuffix .xml,$(drafts))) \
	    $(uploads) $(draft_diffs)
clean-all:: clean clean-deps

include $(LIBDIR)/targets.mk
