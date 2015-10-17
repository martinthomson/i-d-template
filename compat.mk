ifeq (3,$(word 1,$(subst ., ,$(MAKE_VERSION))))
$(warning =======================)
$(warning GNU Make version $(MAKE_VERSION) isn't supported)
$(warning You should upgrade to version 4)
ifeq (Darwin,$(shell uname -s))
$(warning With homebrew (https://brew.sh) type:)
$(warning $$ brew tap homebrew/dupes)
$(warning $$ brew install homebrew/dupes/make)
$(warning This installs `gmake`)
endif
$(warning =======================)
endif
