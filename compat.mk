ifeq (false,$(CI))
ifeq (3,$(word 1,$(subst ., ,$(MAKE_VERSION))))
$(warning =================================================)
$(warning GNU Make version $(MAKE_VERSION) isn't supported)
$(warning You should upgrade to version 4)
ifeq (Darwin,$(shell uname -s))
$(warning -- OS X:)
$(warning With homebrew (https://brew.sh) type:)
$(warning $$ brew tap homebrew/dupes)
$(warning $$ brew install homebrew/dupes/make)
$(warning Note: This installs make as `gmake`)
endif
$(warning =================================================)
endif
else
ifndef GH_TOKEN
$(warning =================================================)
$(warning No GH_TOKEN value set, github pages won't be updated)
$(warning =================================================)
endif
endif
