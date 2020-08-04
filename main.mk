.PHONY: latest
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
.PHONY: txt raw html pdf
txt:: $(drafts_txt)
raw:: $(drafts_raw)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))

export XML_RESOURCE_ORG_PREFIX

MD_PRE :=
ifneq (,$(MD_PREPROCESSOR))
MD_PRE += | $(MD_PREPROCESSOR)
endif
ifneq (1,$(words $(drafts)))
NOT_CURRENT = $(filter-out $(basename $<),$(drafts))
MD_PTR += | sed -e '$(join $(addprefix s/,$(addsuffix -latest/,$(NOT_CURRENT))), \
		$(addsuffix /g;,$(NOT_CURRENT)))'
endif
MD_POST := | $(LIBDIR)/add-note.py
ifeq (true,$(USE_XSLT))
MD_POST +=  >
else
MD_POST += | $(xml2rfc) --v2v3 /dev/stdin -o
endif

%.xml: %.md
	@h=$$(head -1 $< | cut -c 1-4 -); set -o pipefail; \
	if [ "$${h:0:1}" = $$'\ufeff' ]; then echo 'warning: BOM in $<' 1>&2; h="$${h:1:3}"; \
	else h="$${h:0:3}"; fi; \
	if [ "$$h" = '---' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PRE) | $(kramdown-rfc2629) --v3 $(MD_POST) $@)'; \
	  cat $< $(MD_PRE) | $(kramdown-rfc2629) --v3 $(MD_POST) $@; \
	elif [ "$$h" = '%%%' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PRE) | $(mmark) -xml2 -page $(MD_POST) $@)'; \
	  cat $< $(MD_PRE) | $(mmark) -xml2 -page $(MD_POST) $@; \
	else \
	  ! echo "Unable to detect '%%%' or '---' in markdown file" 1>&2; \
	fi && [ -e $@ ]

ifdef REFCACHEDIR
%.xml: .refcache
.refcache: $(REFCACHEDIR)
	ln -s $< $@
endif

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< | $(xml2rfc) --v2v3 /dev/stdin -o $@

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
	$(xsltproc) --novalid $(LIBDIR)/clean-for-DTD.xslt $< > $@

%.html: %.xml $(LIBDIR)/rfc2629.xslt $(LIBDIR)/style.css
	$(xsltproc) --novalid --stringparam xml2rfc-ext-css-contents "$$(cat $(LIBDIR)/style.css)" $(LIBDIR)/rfc2629.xslt $< > $@

%.txt: %.cleanxml
	$(xml2rfc) $< -o $@ --text

%.raw.txt: %.cleanxml
	$(xml2rfc) $< -o $@ --raw
else
%.html: %.xml $(LIBDIR)/v3.css
	$(xml2rfc) --css=$(LIBDIR)/v3.css --metadata-js-url=/dev/null $< -o $@ --html

%.txt: %.xml
	$(xml2rfc) $< -o $@ --text

%.raw.txt: %.xml
	$(xml2rfc) $< -o $@ --raw
endif

%.pdf: %.txt
	$(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

## Build copies of drafts for submission
.PHONY: submit
submit:: $(drafts_next_txt) $(drafts_next_xml)

## Check for validity
.PHONY: check idnits
check:: idnits
idnits:: $(drafts_next_txt)
	echo $^ | xargs -n 1 sh -c '$(idnits) $$0'

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

.PHONY: lint
lint::
	@err=0; for f in $(join $(drafts),$(draft_types)); do \
	  if [ "${f#draft-}" != "$f" ] && ! grep -q "$${f%.*}-latest" "$$f"; then \
	    echo "$$f does not include the string $${f%.*}-latest"; err=1; \
	  fi; \
	  if [  ! -z "$$(tail -c 1 "$$f")" ]; then \
	    echo "$$f has no newline on the last line"; err=1; \
	  fi; \
	  if grep -n $$' \r*$$' "$$f"; then \
	    echo "$$f contains trailing whitespace"; err=1; \
	  fi; \
	done; [ "$$err" -eq 0 ] || ! echo "Run 'make fix-lint' to automatically fix some errors" 1>&2

.PHONY: fix-lint
fix-lint::
	for f in $(join $(drafts),$(draft_types)); do \
	  [  -z "$$(tail -c 1 "$$f")" ] || echo >>"$$f"; \
	done
	sed -i~ -e 's/ *$$//' $(join $(drafts),$(draft_types))

## Cleanup
COMMA := ,
.PHONY: clean
clean::
	-rm -f .tags $(targets_file) issues.json \
	    $(addsuffix .{txt$(COMMA)raw.txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html \
	    $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)raw.txt$(COMMA)html$(COMMA)pdf},$(drafts)) \
	    $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts))) \
	    $(uploads) $(draft_diffs)
