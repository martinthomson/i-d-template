# What This Project Can Do

```sh
$ make
```

Turn internet-draft source into text and HTML.  This supports XML files using
[xml2rfc](https://xml2rfc.tools.ietf.org/), markdown files using either
[kramdown-rfc2629](https://github.com/cabo/kramdown-rfc2629) or
[mmark](https://github.com/miekg/mmark)

```sh
$ make yanglint
```

Check YANG modules and examples for errors and warnings (see [YANG](YANG.md)).  Also runs automatically during `make` if the `VALIDATE_YANG` environment variable is set.

```sh
$ make diff
```

Show changes since your last draft submission using
[rfcdiff](https://tools.ietf.org/tools/rfcdiff/).

```sh
$ make gh-pages
```

Update the `gh-pages` branch with the latest edits.  [GitHub
pages](https://pages.github.com/) make your changes available on the web.

This builds a HTML index that links to HTML and text copies of all drafts on all
branches, plus links for showing changes with the most recent draft submission.
Files for old branches are retained for one month after the branch is deleted,
then cleaned up the next time this process runs.

```sh
$ git tag -a draft-ietf-unicorn-protocol-02
$ make upload
```

Upload tagged changes to the IETF datatracker using the
[API](https://datatracker.ietf.org/api/submit).

```sh
$ make lint
$ make fix-lint
```

Check for common formatting errors like trailing whitespace and automatically
fix them.

The lint check and a check that drafts build correctly is installed as a git
hook so that it runs before each commit.

```sh
$ make idnits
```

Check for nits using the [idnits](https://tools.ietf.org/tools/idnits/) tool.

```sh
$ make issues
```

Download a copy of GitHub issues and pull requests.


## Setup a Repository

When you [setup a repository](REPO.md), this tool installs a stub `Makefile`.
It also creates the following files from a template: `.gitignore`,
`CONTRIBUTING.md`, `LICENSE.md`, `.travis.yml`, and `.circleci/config.yml`.


## With Continuous Integration Services

Using [circleci](http://circleci.com/) or [travis](https://travis-ci.org/)
[configured](REPO.md#automatic-update-for-editors-copy) you can:

* Check that commits and pull requests for errors.
* Automatically maintain your `gh-pages` branch.
* Automatically save a copy of GitHub issues and pull requests to the repository
  for offline access.  This includes a simple HTML viewer.
* Automatically submit tagged versions of drafts to the IETF datatracker.
