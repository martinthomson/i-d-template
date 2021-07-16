ifneq (,$(CIRCLE_TAG)$(TRAVIS_TAG))
draft_releases := $(CIRCLE_TAG)$(TRAVIS_TAG)
else
draft_releases := $(shell git tag --list --points-at HEAD 'draft-*')
endif

uploads := $(addprefix .,$(addsuffix .upload,$(draft_releases)))

ifneq (,$(TRAVIS))
# Ensure that we build the XML files needed for upload during the main build.
latest:: $(addsuffix .xml,$(draft_releases))
endif

.PHONY: upload publish
publish: upload
upload: $(uploads)
	@[ -n "$^" ] || ! echo "error: No files to upload.  Did you use \`git tag -a\`?"

.%.upload: %.xml
	set -ex; email="$(shell git tag --list --format '%(taggeremail)' $(basename $<) | \
	  sed -e 's/^<//;s/>$$//')"; \
	[ -z "$$email" ] && email=$$(xmllint --xpath '/rfc/front/author[1]/address/email/text()' $< 2>/dev/null); \
	[ -z "$$email" ] && ! echo "Unable to find email to use for submission." 1>&2; \
	$(curl) -D $@ -F "user=$$email" -F "xml=@$<" "$(DATATRACKER_UPLOAD_URL)" && echo && \
	  (grep -q ' 200 OK' $@ >/dev/null 2>&1 || ! cat $@ 1>&2)

# This ignomonious hack ensures that we can catch missing files properly.
.%.upload:
	@if $(MAKE) "$*".xml; then \
	  $(MAKE) "$@"; \
	else \
	  echo "============================================================================"; \
	  echo "Warning: A source file for '$*' does not exist."; \
	  echo; \
	  echo "If you applied this tag in error, remove it before adding another tag:"; \
	  echo "    git tag -d '$*'"; \
	  echo "    git push -f $(GIT_REMOTE) ':$*'"; \
	  echo "============================================================================"; \
	  false; \
	fi
