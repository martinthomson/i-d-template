.PHONY: latest
latest:: txt html

include lib/compat.mk
include lib/config.mk
include lib/id.mk
include lib/ghpages.mk

## Basic Targets
.PHONY: txt html pdf
txt:: $(drafts_txt)
html:: $(drafts_html)
pdf:: $(addsuffix .pdf,$(drafts))

## Basic Recipes
.INTERMEDIATE: $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))
%.xml: %.md
	XML_RESOURCE_ORG_PREFIX=$(XML_RESOURCE_ORG_PREFIX) \
	  $(kramdown-rfc2629) $< > $@

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< > $@

%.txt: %.xml
	$(xml2rfc) $< -o $@ --text

%.htmltmp: %.xml
	$(xml2rfc) $< -o $@ --html
%.html: %.htmltmp lib/addstyle.sed lib/style.css
ifeq (,$(CI_REPO_FULL))
	sed -f lib/addstyle.sed $< > $@
else
	sed -f lib/addstyle.sed -f lib/addribbon.sed $< | \
	  sed -e 's~{SLUG}~$(CI_REPO_FULL)~' > $@
endif

%.pdf: %.txt
	$(enscript) --margins 76::76: -B -q -p - $< | $(ps2pdf) - $@

## Build copies of drafts for submission
.PHONY: submit
submit:: $(drafts_next_txt) $(drafts_next_xml)

define makerule_submit_xml =
$(1)
	sed -e"s/$$(basename $$<)-latest/$$(basename $$@)/" $$< > $$@
endef
submit_deps := $(join $(addsuffix :,$(drafts_next_xml)),$(drafts_xml))
$(foreach rule,$(submit_deps),$(eval $(call makerule_submit_xml,$(rule))))

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
$$(call arg,1,$(1)): $$(call arg,2,$(1)) $$(call arg,3,$(1))
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
issues::
	curl https://api.github.com/repos/$(GITHUB_REPO_FULL)/issues?state=open > $@.json

## Cleanup
COMMA := ,
.PHONY: clean
clean::
	-rm -f $(addsuffix .{txt$(COMMA)html$(COMMA)pdf},$(drafts)) index.html
	-rm -f $(addsuffix -[0-9][0-9].{xml$(COMMA)md$(COMMA)org$(COMMA)txt$(COMMA)html$(COMMA)pdf},$(drafts))
	-rm -f $(draft_diffs)
	-rm -f  $(filter-out $(join $(drafts),$(draft_types)),$(addsuffix .xml,$(drafts)))
