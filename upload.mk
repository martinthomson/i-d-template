# This only works for tags that are created with `git tag -a`.  Using an
# annotated tag associates an email address, which this uses in the upload.
ifneq (,$(CIRCLE_TAG)$(TRAVIS_TAG))
draft_releases := $(CIRCLE_TAG)$(TRAVIS_TAG)
else
draft_releases := $(shell git tag --list --points-at HEAD --format '%(tag),%(taggeremail)' | grep '^draft-.*,<.*>$$' | cut -f 1 -d , -)
endif

ifneq ($(foreach tag,$(draft_releases),$(shell git tag --list --format='%(tag)' $(tag))),$(draft_releases))
$(warning Attempting upload for a lightweight tag: $(draft_releases))
$(error Only annotated tags \(created with `git tag -a`\) are supported)
endif

uploads := $(addprefix .,$(addsuffix .upload,$(draft_releases)))

ifneq (,$(TRAVIS))
# Ensure that we build the XML files needed for upload during the main build.
latest:: $(addsuffix .xml,$(draft_releases))
endif

.PHONY: upload publish
publish: upload
upload: $(uploads)

.%.upload: %.xml
	$(curl) -D $@ -F "user=$(shell git tag --list --format '%(taggeremail)' $(basename $<) | \
				 sed -e 's/^<//;s/>$$//')" -F "xml=@$<" \
		"$(DATATRACKER_UPLOAD_URL)" && echo && \
	  (grep -q ' 200 OK' $@ >/dev/null 2>&1 || ! cat $@ 1>&2)
