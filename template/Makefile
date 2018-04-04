LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules >/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init -- $(LIBDIR)
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b master https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
