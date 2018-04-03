LIBDIR := lib
include $(LIBDIR)/main.mk

ifneq (,$(wildcard .gitmodules))
ifneq (,$(shell grep "path = $(LIBDIR)" .gitmodules))
SUBMODULE = true
endif
endif

$(LIBDIR)/main.mk:
ifeq (true,$(SUBMODULE))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b master https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
