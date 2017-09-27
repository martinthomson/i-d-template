# This only works for tags that are created with `git tag -a`.  Using an
# annotated tag associates an email address, which this uses in the upload.
ifneq (,$(CIRCLE_TAG)$(TRAVIS_TAG))
draft_releases := $(CIRCLE_TAG)$(TRAVIS_TAG)
else
draft_releases := $(shell git tag --list --points-at HEAD --format '%(tag),%(taggeremail)' | grep '^draft-.*,<.*>$$' | cut -f 1 -d , -)
endif
uploads := $(addprefix .,$(addsuffix .upload,$(draft_releases)))

# Ensure that we build the XML files needed for upload during the main build (needed for travis).
latest:: $(addsuffix .xml,$(draft_releases))

.PHONY: upload
upload: $(uploads)

.%.upload: %.xml
	$(curl) -f -F "user=$(shell git tag --list --format '%(taggeremail)' $(basename $<) | sed -e 's/^<//;s/>$$//')" -F "xml=@$<" "$(DATATRACKER_UPLOAD_URL)" > "$@" || (cat "$@" 1>&2; exit 1)
