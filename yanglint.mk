
CHECK_TARGETS = $(addsuffix .checkyang,$(drafts_source))
.PHONY: yanglint $(CHECK_TARGETS)

$(CHECK_TARGETS): %.checkyang: %
	@if grep -q -E '^\s*YANG-(MODULE|DATA|TREE)' $< ; then \
	  if ! $(LIBDIR)/yang-check.sh $< ; then \
	    echo "$(LIBDIR)/yang-check.sh $< failed" ; \
	    exit 1 ; \
	  fi ; \
	else \
		echo "(no yang imported in $<)" ; \
	fi

yanglint: $(CHECK_TARGETS)

