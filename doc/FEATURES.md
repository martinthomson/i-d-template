# What This Project Can Do

```sh
$ make
```

Turn internet-draft source into text and HTML.  This supports XML files using
[xml2rfc](https://xml2rfc.tools.ietf.org/), markdown files using either
[kramdown-rfc](https://github.com/cabo/kramdown-rfc) or
[mmark](https://github.com/miekg/mmark)

```sh
$ make diff
```

Show changes since your last draft submission using
[rfcdiff](https://www.ietf.org/rfcdiff).

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
[API](https://datatracker.ietf.org/api/submit).  This will also manage draft
renames by setting the "replaces" field.

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

Check for nits using the [idnits](https://www.ietf.org/tools/idnits) tool.

```sh
$ make issues
```

Download a copy of GitHub issues and pull requests.


## Setup a Repository

When you [setup a repository](REPO.md), this tool installs a stub `Makefile`.
It also creates the following files from a template: `README.md`, `.gitignore`,
`CONTRIBUTING.md`, `LICENSE.md`, files for GitHub pages, and GitHub Action configuration
under `.github/workflows/` (see below).


## Automation Features

Using [GitHub Actions](https://github.com/features/actions) you get automated
continuous integration that can:

* Check that commits and pull requests for errors.
* Automatically maintain a readable copy for display on GitHub Pages.
* Automatically save a copy of GitHub issues and pull requests to the repository
  for offline access.  This includes a simple HTML viewer.
* Automatically [submit tagged versions of drafts](./SUBMITTING.md) to the IETF datatracker.

Alternatively, you can also use [circleci](http://circleci.com/) or
[travis](https://travis-ci.org/) [as described
here](REPO.md#automatic-update-for-editors-copy).
