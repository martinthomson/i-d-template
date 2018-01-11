ifneq (true,$(CI))
ifndef SUBMODULE
UPDATE_COMMAND = echo Updating template && git -C $(LIBDIR) pull && \
                 ([ ! -d $(XSLTDIR) ] || git -C $(XSLTDIR) pull)
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

.PHONY: auto_update
.SILENT: auto_update
.IGNORE: auto_update
auto_update:
	$(UPDATE_COMMAND)

.PHONY: update
update:  auto_update
	@[ ! -r circle.yml ] || \
		echo circle.yml has been replaced by .circleci/config.yml. Please update from $(LIBDIR)/template.
	@for i in Makefile .travis.yml .circleci/config.yml; do \
	  [ -z "$(comm -13 $$i $(LIBDIR)/template/$$i)" ] || \
	    echo $$i is out of date, check against $(LIBDIR)/template/$$i for changes.; \
	done
	@dotgit=$$(git rev-parse --git-dir); \
	  [ -L "$$dotgit"/hooks/pre-commit ] || \
	  ln -s ../../$(LIBDIR)/pre-commit.sh "$$dotgit"/hooks/pre-commit

endif # CI
