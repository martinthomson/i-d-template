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
ifeq (,$(MAKE_TRACE))
upload: $(uploads)
else
upload:
endif
	@[ -n "$(uploads)" ] || ! echo "error: No files to upload.  Did you use \`git tag -a\`?"
ifneq (,$(MAKE_TRACE))
	@$(call MAKE_TRACE,$(uploads))
endif

.%.upload: %.xml
	set -ex; email="$(shell git tag --list --format '%(taggeremail)' $(basename $<) | \
	  sed -e 's/^<//;s/>$$//')"; \
	[ -z "$$email" ] && email=$$(xmllint --xpath '/rfc/front/author[1]/address/email/text()' $< 2>/dev/null); \
	[ -z "$$email" ] && ! echo "Unable to find email to use for submission." 1>&2; \
	$(if $(TRACE_FILE),$(trace) $< -s upload-request )$(curl) -D "$@" \
	  -F "user=$$email" -F "xml=@$<" "$(DATATRACKER_UPLOAD_URL)" && echo && \
	  (head -1 "$@" | grep -q '^HTTP/\S\S* 200\b' || $(trace) $< -s upload-result ! cat "$@" 1>&2)

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
