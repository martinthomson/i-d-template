.PHONY: latest
latest:: txt html

LIBDIR ?= lib
include $(LIBDIR)/config.mk
include $(LIBDIR)/id.mk
include $(LIBDIR)/ghpages.mk
include $(LIBDIR)/update.mk
include $(LIBDIR)/issues.mk

## Basic Targets
.PHONY: txt html pdf
txt:: $(drafts_txt)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))

NOT_CURRENT = $(filter-out $(basename $<),$(drafts))
ifneq (,$(MD_PREPROCESSOR))
MD_PREPROCESSOR := | $(MD_PREPROCESSOR)
endif
ifneq (1,$(words $(drafts)))
REMOVE_LATEST = | sed -e '$(join $(addprefix s/,$(addsuffix -latest/,$(NOT_CURRENT))), \
		$(addsuffix /g;,$(NOT_CURRENT)))'
else
REMOVE_LATEST =
endif
export XML_RESOURCE_ORG_PREFIX

%.xml: %.md
	@h=$$(head -1 $< | cut -c 1-3 -); set -o pipefail; \
	if [ "$$h" = '---' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PREPROCESSOR) $(REMOVE_LATEST) | $(kramdown-rfc2629) > $@)'; \
	  cat $< $(MD_PREPROCESSOR) $(REMOVE_LATEST) | $(kramdown-rfc2629) > $@; \
	elif [ "$$h" = '%%%' ]; then \
	  echo '$(subst ','"'"',cat $< $(MD_PREPROCESSOR) $(REMOVE_LATEST) | $(mmark) -xml2 -page > $@)'; \
	  cat $< $(MD_PREPROCESSOR) $(REMOVE_LATEST) | $(mmark) -xml2 -page > $@; \
	else \
	  ! echo "Unable to detect '%%%' or '---' in markdown file" 1>&2; \
	fi

ifdef REFCACHEDIR
%.xml: .refcache
.refcache: $(REFCACHEDIR)
	ln -s $< $@
endif

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< > $@

%.txt: %.xml
	$(xml2rfc) $< -o $@ --text

ifeq (true,$(USE_XSLT))
XSLTDIR ?= $(LIBDIR)/rfc2629xslt
$(LIBDIR)/rfc2629.xslt:	$(XSLTDIR)/rfc2629.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(LIBDIR)/clean-for-DTD.xslt: $(LIBDIR)/rfc2629xslt/clean-for-DTD.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(XSLTDIR)/clean-for-DTD.xslt $(XSLTDIR)/rfc2629.xslt: $(XSLTDIR)
$(XSLTDIR):
	git clone --depth 10 -b master https://github.com/reschke/xml2rfc $@

%.cleanxml: %.xml $(LIBDIR)/clean-for-DTD.xslt $(LIBDIR)/rfc2629.xslt
	$(xsltproc) --novalid $(LIBDIR)/clean-for-DTD.xslt $< > $@

%.htmltmp: %.xml $(LIBDIR)/rfc2629.xslt
	$(xsltproc) --novalid $(LIBDIR)/rfc2629.xslt $< > $@
else
%.htmltmp: %.xml
	$(xml2rfc) $< -o $@ --html
endif

%.html: %.htmltmp $(LIBDIR)/addstyle.sed $(LIBDIR)/style.css
ifeq (,$(CI_REPO_FULL))
	sed -f $(LIBDIR)/addstyle.sed $< > $@
else
	sed -f $(LIBDIR)/addstyle.sed -f $(LIBDIR)/addribbon.sed $< | \
	  sed -e 's~{SLUG}~$(CI_REPO_FULL)~' > $@
endif

%.pdf: %.txt
	$(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

## Build copies of drafts for submission
.PHONY: submit
submit:: $(drafts_next_txt) $(drafts_next_xml)

ifeq (true,$(USE_XSLT))
NEXT_XML_SOURCE_EXT := cleanxml
else
NEXT_XML_SOURCE_EXT := xml
endif

include .targets.mk
.targets.mk: $(LIBDIR)/main.mk
	@echo > $@
# Submit targets
	@for f in $(drafts_next_xml); do \
	    echo "$$f: $${f%-[0-9][0-9].xml}.$(NEXT_XML_SOURCE_EXT)" >> $@; \
	    echo -e "\tsed -e '\$$(join \$$(addprefix s/,\$$(addsuffix -latest/,\$$(drafts))), \$$(addsuffix /g;,\$$(drafts_next)))' \$$< > \$$@" >> $@; \
	done
# Diff targets
	@p=($(drafts_prev_txt)); n=($(drafts_txt)); i=$${#p[@]}; \
	while [ $$i -gt 0 ]; do i=$$(($$i-1)); \
	    echo "diff-$${p[$$i]%-[0-9][0-9].txt}.html: $${p[$$i]} $${n[$$i]}" >> $@; \
	    echo -e "\t-\$$(rfcdiff) --html --stdout \$$^ > \$$@" >> $@; \
	done
# Pre-requisite files for diff
	@for t in $$(git tag); do \
	    b=$${t%-[0-9][0-9]}; f=$$(git ls-tree --name-only $$t | grep $$b | head -1); \
	    echo ".INTERMEDIATE: $$t.$${f##*.}" >> $@; \
	    echo "$$t.$${f##*.}:" >> $@; \
	    echo -e "\t git show $$t:$$f | sed -e 's/$$b-latest/$$t/' > \$$@" >> $@; \
	done

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
.PHONY: report
report: $(TEST_REPORT)
$(TEST_REPORT): $(drafts_html) $(drafts_txt)
	@echo build_report $^
	@mkdir -p $(dir $@)
	@echo '<?xml version="1.0" encoding="UTF-8"?>' >$@
	@passed=();failed=();for i in $^; do \
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

## Cleanup
COMMA := ,
.PHONY: clean
clean::
	-rm -f .targets.mk issues.json \
	    $(addsuffix .{txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html \
	    $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)html$(COMMA)pdf},$(drafts)) \
	    $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts))) \
	    $(draft_diffs)
