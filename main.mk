.PHONY: latest
latest:: txt html

LIBDIR ?= lib
include $(LIBDIR)/compat.mk
include $(LIBDIR)/config.mk
include $(LIBDIR)/id.mk
include $(LIBDIR)/ghpages.mk
include $(LIBDIR)/update.mk

## Basic Targets
.PHONY: txt html pdf
txt:: $(drafts_txt)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))

ifdef MD_PREPROCESSOR
.INTERMEDIATE: $(addsuffix .mdtmp,$(drafts))
%.mdtmp: %.md
	$(MD_PREPROCESSOR) < $< > $@

%.xml: %.mdtmp
else
%.xml: %.md
endif
	@h=$$(head -1 $< | cut -c 1-3 -); \
	if [ "$$h" = '---' ]; then \
	  echo XML_RESOURCE_ORG_PREFIX=$(XML_RESOURCE_ORG_PREFIX) \
	    $(kramdown-rfc2629) $< > $@; \
	  XML_RESOURCE_ORG_PREFIX=$(XML_RESOURCE_ORG_PREFIX) \
	    $(kramdown-rfc2629) $< > $@; \
	elif [ "$$h" = '%%%' ]; then \
	  echo $(mmark) -xml2 -page $< $@; \
	  $(mmark) -xml2 -page $< $@; \
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

ifeq (1,$(USE_XSLT))
XSLTDIR ?= $(LIBDIR)/rfc2629xslt
$(LIBDIR)/rfc2629.xslt:	$(XSLTDIR)/rfc2629.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(LIBDIR)/clean-for-DTD.xslt: $(LIBDIR)/rfc2629xslt/clean-for-DTD.xslt
	$(xsltproc) $(XSLTDIR)/to-1.0-xslt.xslt $< > $@

$(XSLTDIR)/clean-for-DTD.xslt $(XSLTDIR)/rfc2629.xslt: $(XSLTDIR)
$(XSLTDIR):
	git clone --depth 10 -b master https://github.com/reschke/xml2rfc $@

%.cleanxml: %.xml $(LIBDIR)/clean-for-DTD.xslt
	$(xsltproc) --novalid $(LIBDIR)/clean-for-DTD.xslt $< > $@

%.htmltmp: %.cleanxml $(LIBDIR)/rfc2629.xslt
	$(xsltproc) --novalid $(LIBDIR)/rfc2629.xslt $< > $@
else
%.htmltmp: %.xml
	$(xml2rfc) $< -o $@ --html
endif

%.html: %.htmltmp $(LIBDIR)/addstyle.sed $(LIBDIR)/style.css
ifeq (,$(CI_REPO_FULL))
	sed -f $(LIBDIR)/addstyle.sed $< > $@
else
	sed -f $(LIBDIR)/addstyle.sed -f $(LIBDIR)/addribbon.sed \
	  -e 's~{SLUG}~$(CI_REPO_FULL)~' $< > $@
endif

%.pdf: %.txt
	$(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

## Build copies of drafts for submission
.PHONY: submit
submit:: $(drafts_next_txt) $(drafts_next_xml)

include .targets
.targets: $(LIBDIR)/main.mk
	@echo > $@
	@for f in $(drafts_next_xml); do \
	    echo "$$f: $${f%-[0-9][0-9].xml}.xml" >> $@; \
	    echo -e "\tsed -e 's/$${f%-[0-9][0-9].xml}-latest/$${f%.xml}/' \$$< > \$$@" >> $@; \
	done

## Check for validity
.PHONY: check idnits
check:: idnits
idnits:: $(drafts_next_txt)
	echo $^ | xargs -n 1 sh -c '$(idnits) $$0'

## Build diffs between the current draft versions and any previous version
# This is makefile magic that requires Make 4.0

draft_diffs := $(addprefix diff-,$(addsuffix .html,$(drafts)))
.PHONY: diff
diff: $(draft_diffs)

arg = $(word $(1),$(subst ~, ,$(2)))
argcat = $(join $(1),$(addprefix ~,$(2)))
argcat3 = $(call argcat,$(1),$(call argcat,$(2),$(3)))
argcat5 = $(call argcat3,$(1),$(2),$(call argcat3,$(3),$(4),$(5)))

.INTERMEDIATE: $(join $(drafts_prev),$(draft_types))
define makerule_diff =
$$(call arg,1,$(1)): $$(call arg,3,$(1)) $$(call arg,2,$(1))
	-$(rfcdiff) --html --stdout $$^ > $$@
endef
diff_deps := $(call argcat3,$(draft_diffs),$(drafts_next_txt),$(drafts_prev_txt))
$(foreach rule,$(diff_deps),$(eval $(call makerule_diff,$(rule))))

define makerule_prev =
.INTERMEDIATE: $$(call arg,1,$(1)) $$(call arg,4,$(1)) $$(call arg,5,$(1))
$$(call arg,1,$(1)):
	git show $$(call arg,2,$(1)):$$(call arg,3,$(1)) > $$@
endef
drafts_prev_out := $(join $(drafts_prev),$(draft_types))
drafts_prev_in := $(join $(drafts),$(draft_types))
drafts_prev_xml := $(addsuffix .xml,$(drafts_prev))
prev_versions_args := $(call argcat5,$(drafts_prev_out),$(drafts_prev),$(drafts_prev_in),$(drafts_prev_txt),$(drafts_prev_xml))
$(foreach args,$(prev_versions_args),$(eval $(call makerule_prev,$(args))))

## Store a copy of any github issues
.PHONY: issues
issues:: issues.json
issues.json:
	curl https://api.github.com/repos/$(GITHUB_REPO_FULL)/issues?state=open > $@

## Cleanup
COMMA := ,
.PHONY: clean
clean::
	-rm -f .targets
	-rm -f $(addsuffix .{txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html
	-rm -f $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)html$(COMMA)pdf},$(drafts))
	-rm -f $(draft_diffs)
	-rm -f  $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))
