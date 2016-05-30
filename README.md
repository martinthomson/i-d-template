# Internet Draft Template Repository

The contents of this repository can be used to get started with a new internet
draft.

# Getting Started

You need a [GitHub account](https://github.com/join).

Make your you have the [necessary software installed](https://github.com/martinthomson/i-d-template/blob/master/doc/SETUP.md).

## Working Group Setup

Make a [new organization](https://github.com/organizations/new) for your working
group.  This guide will use the name `unicorn-wg` for your working group.

See the [more detailed guide](https://github.com/martinthomson/i-d-template/blob/master/doc/WG-SETUP.md).

## New Draft Setup

[Make a new repository](https://github.com/new).  This guide will use the
name name `unicorn-protocol` here.

When prompted, select the option to initialize the repository with a README.

Clone that repository:
```sh
$ git clone https://github.com/unicorn-wg/unicorn-protocol.git
$ cd unicorn-protocol
```

Choose whether you want to use markdown, outline, or xml as your input form.
If you already have a draft, then that decision is already made for you.

Make a draft file.  The name of the file is important, make it match the name of
your draft.  You can take a copy of the [example](https://github.com/martinthomson/i-d-template/blob/master/doc/example.md) [files](https://github.com/martinthomson/i-d-template/blob/master/doc/example.xml) if you are starting from
scratch.

Edit the draft so that it has both a title and the correct name.  These tools
uses the `-latest` suffix in place of the usual number ('-00', or '-08').  The
number is generated automatically when you use `make submit`.

In XML, you should have something like:
```xml
<rfc docName="draft-ietf-unicorn-protocol-latest"
     ... other attributes ...>
  <front>
    <title abbrev="Unicorns!!!">The Unicorn Protocol</title>
```

Markdown is similar:
```yaml
docname: draft-ietf-unicorn-protocol-latest
title: The Unicorn Protocol
```

Commit and push your changes:
```sh
$ git commit -a
$ git push
```

Clone a copy of this respository into place and run the setup:

```sh
$ git clone https://github.com/martinthomson/i-d-template lib
$ make -f lib/setup.mk
```

If you prefer a stable version of this code, you can use `git submodule`
instead.

The setup removes adds some files, updates `README.md` with the details of
your draft, sets up a `gh-pages` branch for your editor's copy.

Finally, push:
```sh
$ git push
```


## Updating The Editor's Copy

You can maintain `gh-pages` manually by running the following command
occasionally.

```sh
$ make ghpages
```

Or, you can setup an automatic commit hook using Travis or Circle CI.


## Automatic Update for Editor's Copy

This requires that you sign in with [Travis](https://travis-ci.org/) or
[Circle](https://circleci.com/).

First enable builds for the new repository:
[Travis](https://travis-ci.org/profile),
[Circle](https://circleci.com/add-projects).  Travis might need to be refreshed
before you can see your repository.

Then, you need to get yourself a [new GitHub application
token](https://github.com/settings/tokens/new).  The application token only
needs the `public_repo` privilege.  This will let it push updates to your
`gh-pages` branch.

You can add environment variables using the Travis or Circle interface.  Include
a variable with the name `GH_TOKEN` and the value of your newly-created
application token.  On Travis, make sure to leave the value of "Display value in
build log" disabled, or you will be making your token public.

**WARNING**: You might want to use a dummy account for application tokens to
minimize the consequences of accidental leaks of your key.

Once you enable pushes, be very careful merging pull requests that alter
`.travis.yml`, `circle.yml` or `Makefile`.  Those files can cause the value of
the token to be published for all to see.  You don't want that to happen.  Even
though tokens can be revoked easily, discovering a leak might take some time.
Only pushes to the main repository will be able to see the token, so don't worry
about pull requests.

Travis and Circle will now also check pull requests for errors, letting you
know if things didn't work out so that you don't merge anything suspect.


# Submitting Drafts

See the [submission guide](https://github.com/martinthomson/i-d-template/blob/master/doc/SUBMITTING.md).
