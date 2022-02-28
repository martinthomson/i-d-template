# Updating

Over time, this project will be improved by adding features or fixing bugs.

Get a new copy of this code by running:

```sh
$ make update
```

This will pull an updated copy of this repository and ensure that its
dependencies are also updated.

This will also install [git
hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) that catch some
common mistakes.

If you run `make`, then `make update` will run automatically every 2 weeks.

## Automatically Generated Files

The files that this repository generates sometimes get out of sync.  This might
be because of changes external to the repository (such as CI system updates) or
changes to the draft (a new filename, author, or title).

These files can be updated by running:

```sh
$ make update-files
```

This updates all of the files below, plus `.gitignore`, `Makefile`, and
`.note.xml` (if needed).

This erases any customizations that have been made to those files.

The `make update-files` rule can be manually run using the "Update Generated
Files" GitHub Action.

Special targets can be run individually:

* `make update-readme` regenerates `README.md` (and `CONTRIBUTING.md`)
* `make update-codeowners` regenerates `.github/CODEOWNERS`
* `make update-venue` regenerates the `venue` section in a
  [kramdown-rfc](https://github.com/cabo/kramdown-rfc) draft

