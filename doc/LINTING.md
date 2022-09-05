# Additional Tools

You have some custom process that you want to run to validate code, generate
examples, or process content.  You might use some specialized tools for this.


## Linting Tools

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

So you will need to ensure that dependencies are available.

You can list dependencies in a `requirements.txt`, `Gemfile`, or `package.json`
as [described here](https://github.com/martinthomson/i-d-template/blob/main/deps.mk).

For python, create and add a file called
[`requirements.txt`](https://pip.pypa.io/en/stable/reference/requirements-file-format/).

For ruby, create and add a file called 
[`Gemfile`](https://bundler.io/man/gemfile.5.html).  Note that `Gemfile.lock`
should be added to your `.gitignore`.

For nodejs, create and add a file called
[`package.json`](https://docs.npmjs.com/cli/v8/configuring-npm/package-json)
or just run `npm add --save <package>` then add the file.  Note that
`package-lock.json` should be added to your `.gitignore`.


## Manually Installing Dependencies

Say you have a custom command that checks some input files.

```make
checker-tool ?= checker-tool
# Use a hidden marker file to indicate that the tool is installed.
checker-marker ?= .checker-tool-installed.txt
.PHONY: run-checker
run-checker: $(drafts_xml) $(checker-marker)
	$(checker-tool) $(filter-out $(checker-marker),$^)

lint:: run-checker

$(checker-marker):
	magically install checker-tool as $(checker-tool)
	@touch $@
```

Note that you might need to specify a full path to the installed file if the
installer puts the file in a place that isn't on your `$PATH`. Extra care is
needed here when running in CI.

One way to do this is to ensure that the binary is identified when running
`make`.  You can modify `.github/workflows/*.yml` or `.circleci/config.yml`
to include additional arguments to make should do this.  The following is a
modified target in `.github/workflows/ghpages.yml` and
`.github/workflows/publish.yml`:

```yaml
    - name: "Build Drafts"
      uses: martinthomson/i-d-template@v1
      with:
        make: latest checker-tool=/root/.local/bin/checker-tool
```

Alternatively, you can attempt to detect that you are running in CI and adjust
the installation process accordingly.  Then the target will be run
automatically.

```make
$(checker-marker):
        @if [ "$CI" = true -a "$CIRCLECI" != true ]; then user=root; else user=user; fi; \
	  hash $(notdir $(checker-tool)) 2>/dev/null || \
	  magically install checker-tool for $$user as $(checker-tool)
	@touch $@
```

Note that GitHub Actions builds run as root, but CircleCI builds use a special user.


## Using the Mega/Math image in GitHub Actions

For GitHub Actions, the `martinthomson/i-d-template@v1m` tag identifies an
alternative action that uses [a different Docker
image](https://github.com/martinthomson/i-d-template/pkgs/container/i-d-template-math)
than the default.  This image includes additional tools, as shown in its
[Dockerfile](https://github.com/martinthomson/i-d-template/blob/main/docker/math/Dockerfile).

If you want to use the tools included in this image, use the
`martinthomson/i-d-template@v1m` action.  If you want to add tools to this
image, please send a pull request that modifies this Dockerfile.  Unlike the
[core
image](https://github.com/martinthomson/i-d-template/blob/main/docker/action/Dockerfile),
which is kept deliberately lean, most requests to add content to this image will
be accepted.  The cost is that CI runs using this image will take quite a bit
longer as fetching the image takes more time.
