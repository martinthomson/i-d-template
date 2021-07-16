# Submitting Drafts

Occasionally, you will want to submit versions of your draft to the official
IETF repository.  The automated process is recommended.


## Automated Process

If you have enabled continuous integration, the CI system can automatically
upload a draft to the datatracker.  All you have to do is tag the repository,
push the tag, and await an email with further instructions.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin <branchname>
$ git push origin draft-ietf-unicorn-protocol-03
```

This tag has to include the full name of the draft without any file extension.
That name has to include a revision number.  The tag also has to match the name
of the source file.  For the above example, the source for the draft needs to
be either `draft-ietf-unicorn-protocol.md` or
`draft-ietf-unicorn-protocol.xml`.

For this feature to work you also need to use an annotated tag (that's the `-a`
option above).  Annotated tags require a comment (use `-m` to set this on the
command line).  An annotated tag associates your email address with the
submission.  Lightweight tags don't have an email address and the first author
listed in the draft will be attributed instead.

**Important**: Push the commit that you intend to tag before you push the tag
to check that the draft can be built correctly.  Pushing the tag won't also
push the commit it references and so the build will not run. Circle (and maybe
Travis) will then refuse to build that tag ever again.

**Note**: The email address you use for making this submission needs to match a
verified datatracker account email address ([create one
here](https://datatracker.ietf.org/accounts/create/)).  The email address that
git uses can be found by calling `git config --get user.email`, if you aren't
certain.

**Bug**: Circle CI has a [bug](https://support.circleci.com/hc/en-us/articles/115013854347-Jobs-builds-not-triggered-when-pushing-tag)
that prevents `git push --tags` from triggering builds if you have multiple drafts.
Tag every draft, then push each tag individually.  (Tagging all drafts first means
that cross references will work.)

Once the CI system has built the draft, it will publish it automatically and you
will receive an email asking you to confirm submission.  You don't need to have
a GitHub account token configured for this feature to be enabled.


## GitHub Release

Creating a GitHub release using the intended draft name is an easy way to submit
versions without using the command line.  Simply publish a new release that uses
a tag in the form `draft-<author>-<wg>-<name>-<vv>`.  GitHub Actions will take
care of generating XML and submitting it to the datatracker.

This will attribute the submission to the first author listed in the draft, no
matter who generated the release.  Only annotated tags result in proper
attribution.

Whomever is attributed must have a datatracker account with that email address;
see above.


## Semi-automated Process

You should only really do this if you don't have CI enabled or if the CI build
fails.  The `make publish` command can be used to upload a tagged draft to the
datatracker.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin draft-ietf-unicorn-protocol-03
$ make publish
```

This uses the same process that the CI system uses.  If you have multiple tags
pointing to the current HEAD, this will attempt to publish all of those drafts.


## Manual Process

Again, if you don't have CI enabled, you can make a submission version of your
draft and upload it yourself.  You can also submit a version manually before
pushing tags, in which case the CI build will fail safely when you push the
tags.  Datatracker will safely reject the second, automated submission.

The makefile still needs git tags to work out what version to create.  Always
use tags.  The tool looks for the last version number you have tagged the draft
with and calculates the next version.  When there are no tags, it generates a
`-00` version.

```sh
$ make next
```

If you already have a tag in place or want to build a specific tag, you can
identify the specific XML file directly.  This works for any version you have
submitted.

```sh
$ make draft-ietf-unicorn-protocol-03.xml
```

[Submit the .xml file](https://datatracker.ietf.org/submit/).  Don't submit the
`.txt` file.

Then tag your repository (if you haven't already) and upload the tags.  The tag
you should use is the full draft name including a revision number.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin draft-ietf-unicorn-protocol-03
```

Don't worry if you have CI enabled.  CI might try to build and publish the
draft.  This will fail, but that's OK.
