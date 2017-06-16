# Adopting a Draft

When a working group adopts an individual draft that was created with this
template, the obvious ways of migrating a repository to a different organization
are often not great.

Firstly, **do not create a fork**.  There are better options.

If you are an owner of both the source and target organization, you can move the
repository.  That brings all the pull requests and issues with it.  That's nice
if you can do that, but it's not often the case that people are comfortable with
giving away temporary ownership privileges.

## Recommended Procedure

Make a new repository.  Make sure that it is empty when you make it (don't
create a README when github asks).  Then make a new repository locally:

```sh
$ git init new-repo
$ cd new-repo
$ git remote add origin https://github.com/new-owner/new-repo
```

Then pull the contents of the old repo in:

```sh
$ git pull https://github.com/old-owner/old-repo master
$ git push
```

You then need to setup the `gh-pages` and `gh-issues` branches:

```sh
$ make
$ make -f lib/setup.mk setup-ghpages setup-ghissues
```

You might also want to redo the README:

```sh
$ git rm README.md
$ git commit -m "Remove old README"
$ make -f lib/setup.mk README.md
$ git commit --amend -m "Update README" README.md
```