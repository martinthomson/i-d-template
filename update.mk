ifneq (true,$(CI))
ifndef SUBMODULE
UPDATE_COMMAND = echo Updating template && git -C $(LIBDIR) pull
else
UPDATE_COMMAND = echo Your template is old, please run `make update`
endif

LAST_UPDATE = $(shell stat $(if $(filter Darwin,$(shell uname -s)),-f '%m',-c '%Y') $(LIBDIR)/.git/FETCH_HEAD)
UPDATE_TIME = 1209600 # 2 weeks

.PHONY: update_check update
update_check:
	@[ $$(($(shell date '+%s') - $(LAST_UPDATE))) -gt $(UPDATE_TIME) ] && \
	  $(UPDATE_COMMAND) || true

update:
	git -C $(LIBDIR) pull

latest submit:: update_check
endif # CI
