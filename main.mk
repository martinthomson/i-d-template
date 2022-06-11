.PHONY: all latest
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
endif

endif # Summary

latest:: txt html

.DELETE_ON_ERROR:

## Modularity
# Basic files (these can't rely on details from .targets.mk)
LIBDIR ?= lib
include $(LIBDIR)/config.mk
include $(LIBDIR)/id.mk

# Now build .targets.mk, which contains details of draft versions.
targets_file := .targets.mk
targets_drafts := TARGETS_DRAFTS := $(drafts)
targets_tags := TARGETS_TAGS := $(drafts_tags)

ifeq (,$(DISABLE_TARGETS_UPDATE))
# Note that $(shell ) folds multiple lines into one, which is OK here.
ifneq ($(targets_drafts) $(targets_tags),$(shell head -2 $(targets_file) 2>/dev/null))
$(warning Forcing rebuild of $(targets_file))
# Force an update of .targets.mk by setting a double-colon rule with no
# prerequisites if the set of drafts or tags it contains is out of date.
.PHONY: $(targets_file)
endif
endif # DISABLE_TARGETS_UPDATE

.SILENT: $(targets_file)
$(targets_file): $(LIBDIR)/build-targets.sh
	echo "$(targets_drafts)" >$@
	echo "$(targets_tags)" >>$@
	$< $(drafts) >>$@
include $(targets_file)

# Now include the advanced stuff that can depend on draft information.
include $(LIBDIR)/ghpages.mk
include $(LIBDIR)/archive.mk
include $(LIBDIR)/upload.mk
include $(LIBDIR)/update.mk

## Basic Targets
.PHONY: txt html pdf
txt:: $(drafts_txt)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(drafts_source),$(addsuffix .xml,$(drafts)))

export XML_RESOURCE_ORG_PREFIX

MD_PRE =
ifneq (,$(MD_PREPROCESSOR))
MD_PRE += | $(trace) $@ -s preprocessor $(MD_PREPROCESSOR)
endif
ifneq (1,$(words $(drafts)))
NOT_CURRENT = $(filter-out $(basename $<),$(drafts))
MD_PRE += | sed -e '$(join $(addprefix s/,$(addsuffix -latest/,$(NOT_CURRENT))), \
		$(addsuffix /g;,$(NOT_CURRENT)))'
endif
MD_POST = | $(trace) $@ -s venue $(LIBDIR)/add-note.py
ifneq (true,$(USE_XSLT))
MD_POST += | $(trace) $@ -s v2v3 $(xml2rfc) --v2v3 /dev/stdin -o /dev/stdout
endif
ifneq (,$(XML_TIDY))
MD_POST += | $(trace) $@ -s tidy $(XML_TIDY)
endif

%.xml: %.md
	@h=$$(head -1 $< | cut -c 1-4 -); set -o pipefail; \
	if [ "$${h:0:1}" = $$'\ufeff' ]; then echo 'warning: BOM in $<' 1>&2; h="$${h:1:3}"; \
	else h="$${h:0:3}"; fi; \
	if [ "$$h" = '---' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PRE) | $(kramdown-rfc) --v3 $(MD_POST) >$@)'; \
	  cat $< $(MD_PRE) | $(trace) $@ -s kramdowm-rfc $(kramdown-rfc) --v3 $(MD_POST) >$@; \
	elif [ "$$h" = '%%%' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PRE) | $(mmark) $(MD_POST) >$@)'; \
	  cat $< $(MD_PRE) | $(trace) $@ -s mmark $(mmark) $(MD_POST) >$@; \
	else \
	  ! echo "Unable to detect '%%%' or '---' in markdown file" 1>&2; \
	fi && [ -e $@ ]

%.xml: %.org
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
	$(trace) $@ -s xslt-clean $(xsltproc) --novalid $(LIBDIR)/clean-for-DTD.xslt $< > $@

%.html: %.xml $(LIBDIR)/rfc2629.xslt $(LIBDIR)/style.css
	$(trace) $@ -s xslt-html $(xsltproc) --novalid --stringparam xml2rfc-ext-css-contents "$$(cat $(LIBDIR)/style.css)" $(LIBDIR)/rfc2629.xslt $< > $@

%.txt: %.cleanxml
	$(trace) $@ -s xml2rfc-txt $(xml2rfc) $< -o $@ --text --no-pagination
else
%.html: %.xml $(XML2RFC_CSS)
	$(trace) $@ -s xml2rfc-html $(xml2rfc) --css=$(XML2RFC_CSS) --metadata-js-url=/dev/null $< -o $@ --html
# Workaround for https://trac.tools.ietf.org/tools/xml2rfc/trac/ticket/470
	@-sed -i.rfc-local -e 's,<link[^>]*href=["'"'"]rfc-local.css["'"'"][^>]*>,,' $@; rm -f $@.rfc-local

%.txt: %.xml
	$(trace) $@ -s xml2rfc-txt $(xml2rfc) $< -o $@ --text --no-pagination
endif

%.pdf: %.txt
	$(trace) $@ -s enscript $(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

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
idnits:: $(drafts_next_txt)
	echo $^ | xargs -n 1 sh -c '$(trace) "$$0" -s idnits $(idnits) "$$0"'

CODESPELL_ARGS :=
ifneq (,$(wildcard ./.ignore-words))
CODESPELL_ARGS += -I .ignore-words
endif

.PHONY: spellcheck
spellcheck:: $(drafts_source)
	$(trace) $@ codespell $(CODESPELL_ARGS) $^

## Build diffs between the current draft versions and the most recent version
draft_diffs := $(addprefix diff-,$(addsuffix .html,$(drafts_with_prev)))
.PHONY: diff
diff: $(draft_diffs)

## Generate a test report
ifneq (,$(CIRCLE_TEST_REPORTS))
TEST_REPORT := $(CIRCLE_TEST_REPORTS)/report/drafts.xml
else
TEST_REPORT := report.xml
endif
all_outputs := $(drafts_html) $(drafts_txt)
.PHONY: report
report: $(TEST_REPORT)
$(TEST_REPORT):
	@echo build_report $^
	@mkdir -p $(dir $@)
	@echo '<?xml version="1.0" encoding="UTF-8"?>' >$@
	@passed=();failed=();for i in $(all_outputs); do \
	  if [ -f "$$i" ]; then passed+=("$$i"); else failed+=("$$i"); fi; \
	done; echo '<testsuite' >>$@; \
	echo '    tests="'"$$(($${#passed[@]} + $${#failed[@]}))"'"' >>$@; \
	echo '    failures="'"$${#failed[@]}"'">' >>$@; \
	for i in "$${passed[@]}"; do \
	  echo '  <testcase name="'"$$i"'" classname="build.'"$${i%.*}"'"/>' >>$@; \
	done; \
	for i in "$${failed[@]}"; do \
	  echo '  <testcase name="'"$$i"'" classname="build.'"$${i%.*}"'">' >>$@; \
	  echo '    <failure message="Error building file"/>' >>$@; \
	  echo '  </testcase>' >>$@; \
	done; \
	echo '</testsuite>' >>$@

.PHONY: lint lint-whitespace lint-default-branch lint-docname
lint:: lint-whitespace lint-docname
ifneq (true,$(CI))
lint:: lint-default-branch
endif

lint-whitespace::
	@err=0; for f in $(drafts_source); do \
	  if [  ! -z "$$(tail -c 1 "$$f")" ]; then \
	    $(trace) "$$f" -s nl ! echo "$$f has no newline on the last line"; err=1; \
	  fi; \
	  if ! $(trace) "$$f" -s ws ! grep -n $$' \r*$$' "$$f"; then \
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
.PHONY: clean
clean::
	-rm -f .tags $(targets_file) issues.json \
	    $(addsuffix .{txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html \
	    $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)raw.txt$(COMMA)html$(COMMA)pdf},$(drafts)) \
	    $(filter-out $(drafts_source),$(addsuffix .xml,$(drafts))) \
	    $(uploads) $(draft_diffs)
