.PHONY: update auto_update update-deps
.SILENT: auto_update
.IGNORE: auto_update

ifneq (true,$(CI))
ifndef SUBMODULE
UPDATE_COMMAND = echo Updating template && git -C $(LIBDIR) pull && \
		 ([ ! -d $(XSLTDIR) ] || git -C $(XSLTDIR) pull)
FETCH_HEAD = $(wildcard $(LIBDIR)/.git/FETCH_HEAD)
else
UPDATE_COMMAND = echo Your template is old, please run `make update`
FETCH_HEAD = $(wildcard .git/modules/$(LIBDIR)/FETCH_HEAD)
endif

NOW = $$(date '+%s')
ifeq (,$(FETCH_HEAD))
UPDATE_NEEDED = false
else
UPDATE_INTERVAL := 1209600 # 2 weeks
UPDATE_NEEDED = $(shell [ $$(($(NOW) - $(call last_modified,$(FETCH_HEAD)))) -gt $(UPDATE_INTERVAL) ] && echo true)
endif

ifeq (true,$(UPDATE_NEEDED))
latest next:: auto_update
endif

auto_update:
	$(UPDATE_COMMAND)
	$(MAKE) update-deps

update:  auto_update
	@for i in Makefile $(addprefix .github/workflows/,archive.yml ghpages.yml publish.yml update.yml); do \
	  [ -f "$$i" -a -z "$$(comm -13 $$i $(LIBDIR)/template/$$i 2>/dev/null)" ] || \
	    echo "warning: $$i is out of date, run \`make update-files\` to update it."; \
	done
	@sed -i~ -e 's,-b master https://github.com/martinthomson/i-d-template,-b main https://github.com/martinthomson/i-d-template,' Makefile && \
	  [ `git status --porcelain Makefile | grep '^[A-Z]' | wc -l` -eq 0 ] || git $(CI_AUTHOR) commit -m "Update Makefile" Makefile
	@dotgit=$$(git rev-parse --git-dir); \
	  [ -L "$$dotgit"/hooks/pre-commit ] || \
	    ln -s ../../$(LIBDIR)/pre-commit.sh "$$dotgit"/hooks/pre-commit; \
	  [ -L "$$dotgit"/hooks/pre-push ] || \
	    ln -s ../../$(LIBDIR)/pre-push.sh "$$dotgit"/hooks/pre-push

else
# In CI, do nothing when asked to update.
auto_update:
update:
endif # CI

define regenerate
@set -ex; \
for f in $(1); do \
  if [ -n "$$(git ls-tree -r @ --name-only "$$f")" ]; then \
    amend=--amend; orig=@~; \
    git rm -f "$$f" && \
    git $(CI_AUTHOR) commit -m "Remove old "$$f""; \
  else \
    amend=; orig=@; \
  fi; \
  $(MAKE) -f $(LIBDIR)/setup.mk CHECK_BRANCH=false "$$f"; \
  git add "$$f"; \
  if ! git diff --quiet --cached "$$orig"; then \
    echo "Updating $$f"; \
    git $(CI_AUTHOR) commit $$amend -m "Automatic update of $$f"; \
  elif [ -n "$$amend" ]; then \
    git reset "$$orig" --hard; \
  fi; \
done
endef

.PHONY: update-readme update-codeowners update-makefile update-gitignore update-files update-venue update-ci update-workflows

# Re-run setup for .gitignore.
# This should be an ordering prerequisite for any rule that might create files.
update-gitignore:
	$(MAKE) -f $(LIBDIR)/setup.mk CHECK_BRANCH=false setup-gitignore
	@if ! git diff --quiet @ .gitignore; then \
	  git add .gitignore; \
	  git $(CI_AUTHOR) commit -m "Automatic update of .gitignore"; \
	fi

update-readme: auto_update | update-gitignore
	$(call regenerate,README.md)

update-codeowners: | update-gitignore
	$(call regenerate,.github/CODEOWNERS)

# We only need to copy over the rules that include and setup main.mk.
# This keeps anything above the include where it is and moves everything else below these two things.
# There is a tricky part in suppressing any blank line after `include <...>/main.mk`
# when preserving existing lines.
# This uses 'x' and 'n' to get the next line, then conditionally prints a non-blank line.
update-makefile: Makefile $(LIBDIR)/template/Makefile | update-gitignore
	@x=$$(mktemp);y=$$(mktemp); mv $< "$$x"; \
	sed -n -e '1,/^include.*main\.mk$$/{/^include.*main\.mk$$/{x;n;/^$$/!p;};d;};/main\.mk:$$/,/^$$/d;p' "$$x" > "$$y"; \
	sed -n -e '1,/^include.*main\.mk$$/{x;1d;p;}' "$$x" > $<; \
	sed -n -e '/^include.*main\.mk$$/,/^$$/p;/main\.mk:$$/,/^$$/p' $(LIBDIR)/template/Makefile >> $<; \
	[ $$(cat "$$y" | wc -l) -gt 0 ] && echo >> $<; cat "$$y" >> $<; \
	rm -f "$$x" "$$y"
	@if ! git diff --quiet @ $<; then \
	  git add $<; \
	  git $(CI_AUTHOR) commit -m "Automatic update of $<"; \
	fi


ifneq (true,$(CI))
UPDATE_CI := update-ci
else
UPDATE_CI :=
endif
update-files: auto_update update-gitignore update-makefile $(UPDATE_CI)
	$(call regenerate,README.md .github/CODEOWNERS)

update-venue: auto_update $(drafts_source)
	./$(LIBDIR)/update-venue.sh $(GITHUB_USER) $(GITHUB_REPO) $(drafts_source)
	@if ! git diff --quiet @ $(filter-out auto_update,$^); then \
	  git add $(filter-out auto_update,$^); \
	  git $(CI_AUTHOR) commit -m "Automatic update of venue information"; \
	fi

update-workflows: update-ci
update-ci: auto_update | update-gitignore
	$(call regenerate,$(addprefix .github/workflows/,ghpages.yml publish.yml archive.yml update.yml))
