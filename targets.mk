targets_file := .targets.mk
targets_drafts := \# $(drafts)
targets_tags := \# $(drafts_tags)
$(targets_file): $(LIBDIR)/build-targets.sh
	@echo "$(targets_drafts)" >$@
	@echo "$(targets_tags)" >>$@
	VERSIONED="$(VERSIONED)" $< $(drafts) >>$@
.PHONY: extra
extra: $(targets_file)

ifneq (,$(wildcard $(targets_file)))
EXTRA_TARGETS ?= true
endif

ifeq (true,$(EXTRA_TARGETS))
# Rough check for when .targets.mk is out of date.
# Note that $(shell ) folds multiple lines into one, which is OK here.
ifneq ($(targets_drafts) $(targets_tags),$(shell head -2 $(targets_file) 2>/dev/null))
# Force an update of .targets.mk by marking the file as phony.
.PHONY: $(targets_file)
endif

include $(targets_file)
else
# Backup rule for building files when we don't find the rule.
diff-% $(VERSIONED)/%::
	@$(MAKE) $(targets_file)
	@$(MAKE) EXTRA_TARGETS=true $@
endif
