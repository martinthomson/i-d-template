ifneq (,$(CIRCLE_TAG)$(TRAVIS_TAG))
draft_releases := $(CIRCLE_TAG)$(TRAVIS_TAG)
else
draft_releases := $(shell git tag --list --points-at HEAD 'draft-*')
endif

uploads := $(addprefix $(VERSIONED)/.,$(addsuffix .upload,$(draft_releases)))

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
	set -ex; tag="$(notdir $(basename $<))"; \
	email="$$(git tag --list --format '%(taggeremail)' "$$tag" | sed -e 's/^<//;s/>$$//')"; \
	[ -z "$$email" ] && email=$$(xmllint --xpath '/rfc/front/author[1]/address/email/text()' $< 2>/dev/null); \
	[ -z "$$email" ] && ! echo "Unable to find email to use for submission." 1>&2; \
	replaces() { \
	  last=($$(git log --follow --name-only --format=format: -- "$$1" | \
		   sed -e '/^$$/d' | grep -v draft-todo-yourname-protocol | cut -f 2 | uniq | tail +2 | head -1)); \
	  [ -z "$$last" ] && return; \
	  echo -F; echo "replaces=$${last%.*}"; \
	}; \
	$(if $(TRACE_FILE),$(trace) $< -s upload-request )$(curl) -D "$@" \
	    -F "user=$$email" -F "xml=@$<" $$(replaces "$$(git ls-files "$${tag%-[0-9][0-9]}"'.*')") \
	    "$(DATATRACKER_UPLOAD_URL)" && echo && \
	  (head -1 "$@" | grep -q '^HTTP/\S\S* 20[01]\b' || $(trace) $< -s upload-result ! cat "$@" 1>&2)

# This ignomonious hack ensures that we can catch missing files properly.
.%.upload:
	@if $(MAKE) "$*".xml; then \
	  $(MAKE) "$@"; \
	else \
	  t="$*"; t="$${t##*/}"; \
	  echo "============================================================================"; \
	  echo "Warning: A source file for '$$t' does not exist."; \
	  echo; \
	  if [ $(words $(drafts)) -eq 1 ]; then \
	    echo "  Maybe you meant to name the label '$(drafts)-$${t##*-}' instead."; \
	  else \
	    echo "  Maybe you meant one of the following instead:"; \
	    for d in $(drafts_source); do \
	      echo "    $${d%.*}-$${t##*-} (from $$d)"; \
	    done; \
	  fi; \
	  echo; \
	  echo "If you applied this tag in error, remove it before adding another tag:"; \
	  echo "    git tag -d '$$t'"; \
	  echo "    git push -f $(GIT_REMOTE) ':$$t'"; \
	  echo; \
	  echo "============================================================================"; \
	  false; \
	fi
