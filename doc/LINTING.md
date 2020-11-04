# Adding Linters

So you have some custom process that you want to run on your code.  For
instance, you want to validate some example code.

To run a lint automatically, you can extend the `lint` make target with your
own.  Just add something like this to your `Makefile`:

```make
# The wc lint validates that the source doesn't exceed 10000 lines.
.PHONY: wc
wc: $(drafts_source)
	[ $(wc -l $^) -lt 10000 ]

lint:: wc
```

You can add multiple linters as you like.

## Installing Dependencies for CI

Many linters are external software, which means that you probably won't have
access to those in the minimal CI environment.  Unfortunately, without forking
the GitHub Action or using a new Docker image, it isn't possible to get
additional packages installed in the default environment.

So you will need to install dependencies yourself.

For instance, if you are using
[sf-rfc-validate](https://pypi.org/project/sf-rfc-validate/), you might do this:

```make
sf-rfc-validate ?= sf-rfc-validate
.PHONY: sf-lint
sf-lint: $(drafts_xml) sf-lint-install
	$(sf-rfc-validate) $(filter-out sf-lint-install,$^)

lint:: sf-lint

.PHONY: sf-lint-install
sf-lint-install:
	@hash sf-rfc-validate.py 2>/dev/null || pip3 install --user sf-rfc-validate
```

Note that for things like python, the location that the file is installed to
might not be on the path, so you will need to ensure that you modify the path
when running in CI.

One way to do this is to ensure that the binary is identified when running
`make`.  Modifying `.github/workflows/*.yml` or `.circleci/config.yml` to
include additional arguments to make should do this.  The following is a
modified target in `.github/workflows/ghpages.yml` and
`.github/workflows/publish.yml`:

```yaml
    - name: "Build Drafts"
      uses: martinthomson/i-d-template@v1
      with:
        make: latest sf-rfc-validate=/root/.local/bin/sf-rfc-validate
```

Alternatively, you can attempt to detect that you are running in CI and adjust
the installation process accordingly.  Then the target will be run
automatically.

```make
sf-lint-install:
        @if [ "$CI" = true -a "$CIRCLECI" != true ]; then user=; else user=--user; fi; \
	  hash sf-rfc-validate.py 2>/dev/null || pip3 install "$user" sf-rfc-validate
```

Note that CircleCI builds don't run as root.
