# Working Group Setup

Make a [new organization](https://github.com/organizations/new) for your working
group.  This guide will use the name `unicorn-wg` for your working group.

There is a [more detailed
guide](https://github.com/martinthomson/i-d-template/blob/main/doc/WG-SETUP.md)
for working groups.

# New Draft Setup

If you are more familiar with git and GitHub, try the [fast setup](#fast-setup).

[Make a new repository](https://github.com/new).  This guide will use the
name `unicorn-protocol` in examples.

When prompted, select the option to initialize the repository with a README.

Clone that repository:
```sh
$ git clone https://github.com/unicorn-wg/unicorn-protocol.git
$ cd unicorn-protocol
```

Choose whether you want to use markdown, outline, or xml as your input format.
If you already have a draft, then that decision is already made for you.

Make a draft file in the root of the repo.  The name of the file is important; make
it match the name of your draft. Don't include a version number in the name.  Our
example would be `draft-ietf-unicorn-protocol.md` in markdown.

You can copy of one of the examples files
([markdown](https://github.com/martinthomson/i-d-template/blob/main/example/draft-todo-yourname-protocol.md) or
[XML](https://github.com/martinthomson/i-d-template/blob/main/example/draft-todo-yourname-protocol.xml))
if you are starting from scratch.

Rename the draft.  These tools rely on the draft being in the form
`draft-$source-$name.{xml|md|...}`.  The [official Internet-Draft naming
guide](https://www.ietf.org/standards/ids/guidelines/#7) describes how the IETF
(and related groups) name drafts.  Here, you drop the trailing version number
from the draft name and include an extension indicating the type of file.  You
will be using the same source file to produce multiple versions of the draft.

You also need to include the name of your draft *inside* the document.  This
usually includes the version number, but in this tool, replace that the '-00' or
'-07' with '-latest' instead.  This allows the tool to generate a version number
automatically.

A complete draft isn't necessary at this point.  In XML, you should have at
least:
```xml
<rfc docName="draft-ietf-unicorn-protocol-latest">
  <front>
    <title>The Unicorn Protocol</title>
```

Markdown is similar:
```yaml
---
docname: draft-ietf-unicorn-protocol-latest
title: The Unicorn Protocol
---
```
_(If using `mmark`, replace `---` by `%%%`.)_

Add the draft, commit and push your changes:
```sh
$ git add draft-ietf-unicorn-protocol.md
$ git commit draft-ietf-unicorn-protocol.md
$ git push
```

Clone a copy of this repository into place:

```sh
$ git clone https://github.com/martinthomson/i-d-template lib
```

*Option:* If you prefer a stable version of this code, you can use `git submodule`
instead.

Run the setup command:

```sh
$ make -f lib/setup.mk
```

*Option:* If you prefer to use [Julian Reschke's
XSLT](https://github.com/reschke/xml2rfc) for generating HTML, add
`USE_XSLT=true` to the setup command line.

The setup removes adds some files, updates `README.md` with the details of
your draft, sets up a `gh-pages` branch for your editor's copy.  This pushes
the `gh-pages` branch to `origin`.  If you don't want that, run `make -f
lib/setup.mk setup-default-branch` instead.

Finally, push:

```sh
$ git push
```

*Note:* The `gh-pages` branch will only contain empty files until you (or CI)
updates the files there.


# Fast Setup

For the brave, or those who are more familiar with git.  This is the process I
follow.  Make a new repository on GitHub, but don't initialize it with a
README.  Then:

```sh
$ git init unicorn-protocol
$ cd unicorn-protocol
$ git checkout --orphan main
$ git remote add origin https://github.com/unicorn-wg/unicorn-protocol
# Copy a template in place, change the filename and title.
$ git add draft-*.{md,xml}
$ git commit -m "Initial version blah blah blah"
$ git push -u origin main
$ git clone https://github.com/martinthomson/i-d-template lib
$ make -f lib/setup.mk
$ git push
```


# Updating The Editor's Copy

GitHub serves any HTML you check in on the `gh-pages` branch by default.  This
can be useful for ensuring that the latest version of your draft is available in
a usable form.

You can maintain `gh-pages` manually by running the following command
occasionally.

```sh
$ make ghpages
```

When you do that, you will need to push the `gh-pages` branch yourself.

The default template includes files that will enable [GitHub
Actions](https://github.com/features/actions).  These will result in
automatically enabling builds that update the editor's copy, publish tagged
drafts to datatracker, and periodically save an archive of issues and pull
requests.

Or, you can disable GitHub Actions by deleting files under `.github/workflows`
and use Circle CI, as described in the next section.


# Automatic Update for Editor's Copy with Circle CI

This requires that you sign in with [Circle](https://circleci.com/).

First enable builds for the new repository in the [Circle
Dashboard](https://app.circleci.com/).

Then, you need to get yourself a [new GitHub application
token](https://github.com/settings/tokens/new).  The application token only
needs the `public_repo` privilege.  This will let it push updates to your
`gh-pages` branch.

You can add environment variables using the Circle interface.  Make a variable
with the name `GH_TOKEN` and the value of your newly-created application token.

**WARNING**: You might want to use a dummy account for application tokens to
minimize the consequences of accidental leaks of your key.

Once you enable pushes, be very careful merging pull requests that alter
`.circleci/config.yml` or `Makefile`.  Changes to those files can cause the
value of the token to be published for all to see.  You don't want that to
happen.  Even though tokens can be revoked easily, discovering a leak might take
some time.  Only pushes to the main repository will be able to see the token, so
there is no need to worry about running CI on malicious pull requests (just
don't merge them).

Circle will now check pull requests for errors, letting you know if things
didn't work out so that you don't merge anything suspect.

A `.travis.yml` file exists
([here](https://github.com/martinthomson/i-d-template/blob/main/template/.travis.yml))
that can be used to setup [Travis](https://travis-ci.org).  However, that
process is less well supported.


# Regenerating README.md

When you change things in the repository, it can help if you are able to use
automatic regeneration for files.  `README.md` is typically the file that needs
this sort of updating as files are added, renamed, or removed fairly often.

As long as your input files are newer than `README.md` (use `touch` if this
isn't the case), then it can be rebuilt using `setup.mk` as follows:

```sh
make -f lib/setup.mk README.md
git commit -m "Update README" README.md
```

This will erase any customization you have added.
