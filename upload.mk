draft_releases := $(shell git tag --list --points-at HEAD 'draft-*')

uploads := $(addprefix $(VERSIONED)/.,$(addsuffix .upload,$(draft_releases)))

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
	@set -e$(if $(filter-out false,$(VERBOSE)),x,); tag="$(notdir $(basename $<))"; \
	email="$$($(LIBDIR)/get-email.sh "$$tag" "$<")"; \
	[ -z "$$email" ] && exit 1; \
	replaces() { \
	  [ "$${1##*-}" = "00" ] || return; \
	  base="$${1%-[0-9][0-9]}"; \
	  file="$$(git ls-files "$${base}.*")"; \
	  for last in $$(git log --follow --name-only --format=format: -- "$$file" | \
		sed -e '/^$$/d' | grep -v draft-todo-yourname-protocol | cut -f 2 | uniq | tail +2); do \
	    [ "$${last%.*}" = "$$base" ] && continue; \
	    if [ -n "$$(git tag -l "$${last%.*}-[0-9][0-9]")" ]; then \
	      echo -F; echo "replaces=$${last%.*}"; break; \
	    fi; \
	  done; \
	}; \
	$(if $(TRACE_FILE),$(trace) $< -s upload-request )$(curl) -D "$@" \
	    -F "user=$$email" -F "xml=@$<" $$(replaces "$$tag") \
	    "$(DATATRACKER_UPLOAD_URL)" && echo && \
	  (head -1 "$@" | grep -q '^HTTP/\S\S* 20[01]\b' || { \
	   $(if $(and $(TRACE_FILE),$(shell which jq 2>/dev/null)), \
	       msg="$$(sed -ne '/^$/,$p' "$@" | jq -r '.error')"; \
	       echo "$<" upload "Datatracker error: $${msg:-(unknown)}" >>"$(TRACE_FILE)"; \
	       sed -ne '/^$/,$p' "$@" | jq -r '.messages[]' "$@" | while read -r line; do \
		 echo "$<" upload "$$line" >>"$(TRACE_FILE)"; \
	       done \
	     , cat "$@" 1>&2 \
	    ); false; })

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
