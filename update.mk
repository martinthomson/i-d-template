ifneq (true,$(CI))
ifndef SUBMODULE
UPDATE_COMMAND = echo Updating template && git -C $(LIBDIR) pull
FETCH_HEAD = $(wildcard $(LIBDIR)/.git/FETCH_HEAD)
else
UPDATE_COMMAND = echo Your template is old, please run `make update`
FETCH_HEAD = $(wildcard .git/modules/$(LIBDIR)/FETCH_HEAD)
endif

NOW = $$(date '+%s')
ifeq (,$(FETCH_HEAD))
UPDATE_NEEDED = false
else
UPDATE_TIME = $$(stat $$([ $$(uname -s) = Darwin ] && echo -f '%m' || echo -c '%Y') $(FETCH_HEAD))
UPDATE_INTERVAL = 1209600 # 2 weeks
UPDATE_NEEDED = $(shell [ $$(($(NOW) - $(UPDATE_TIME))) -gt $(UPDATE_INTERVAL) ] && echo true)
endif

ifeq (true, $(UPDATE_NEEDED))
latest submit:: auto_update
endif

auto_update:
	@-$(UPDATE_COMMAND)

.PHONY: update
update:
	git -C $(LIBDIR) pull
	@for i in Makefile .travis.yml circle.yml; do \
	  diff -q $$i $(LIBDIR)/template/$$i >/dev/null || \
	    echo $$i is out of date, run '``'cp -f $(LIBDIR)/template/$$i $$i"''" to update.; \
	done

endif # CI
