# Submitting Drafts

Occasionally, you will want to submit versions of your draft to the official
IETF repository.  The automated process is recommended.


## Automated Process

If you have enabled continuous integration, the CI system can automatically
upload a draft to the datatracker.  All you have to do is tag the repository,
push the tag, and await an email with further instructions.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin draft-ietf-unicorn-protocol-03
```

This tag has to include the full name of the draft without any file extension.
That name has to include a revision number.  The tag also has to match the name
of the source file.  For the above example, the source for the draft needs to
be either `draft-ietf-unicorn-protocol.md` or
`draft-ietf-unicorn-protocol.xml`.

For this feature to work you also need to use an annotated tag (that's the `-a`
option above).  Annotated tags require a comment (use `-m` to set this on the
command line).  Annotated tags associate your email address with then
submission.  Lightweight tags don't have an email address and will be ignored
by the CI build.

**Note**: The email address you use for making this submission needs to match a
valid datatracker account email address.  (The email address that git uses can
be found by calling `git config --get user.email`, if you aren't certain.)

Once the CI system has built the draft, it will upload it automatically and you
will receive an email asking you to confirm submission.  You don't need to have
a GitHub account token configured for this feature to be enabled.


## Semi-automated Process

Rather than rely on the CI system, the `make upload` command can be used to
upload to the datatracker.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin draft-ietf-unicorn-protocol-03
$ make upload
```

This uses the same process as the CI system.  Note that if you have multiple
tags pointing to the current HEAD, this will attempt to upload all of those
drafts.


## Manual Process

Make a submission version of your draft.  The makefile uses git tags to work out
what version to create.  It looks for the last version number you have tagged
the draft with and calculates the next version.  When there are no tags, it
generates a `-00` version.

```sh
$ make submit
```

If you already have a tag in place or want to build a specific tag, you can
identify the specific XML file directly.

```sh
$ make draft-ietf-unicorn-protocol-03.xml
```

[Submit the .xml file](https://datatracker.ietf.org/submit/).

Then you can tag your repository and upload the tags.  The tag you should
use is the full draft name including a revision number.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ git push origin draft-ietf-unicorn-protocol-03
```
