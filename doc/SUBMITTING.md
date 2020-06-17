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
submission.  Lightweight tags don't have an email address and will be ignored
by the CI build.

**Important**: Push the commit that you intend to tag before you push the tag
to check that the draft can be built correctly.  Pushing the tag won't also
push the commit it references and so the build will not run. Circle (and maybe
Travis) will then refuse to build that tag ever again.

**Note**: The email address you use for making this submission needs to match a
valid datatracker account email address ([create one
here](https://datatracker.ietf.org/accounts/create/)).  The email address must
also match one of the author addresses (this condition [might be
temporary](https://trac.tools.ietf.org/tools/ietfdb/ticket/2390)).  The email
address that git uses can be found by calling `git config --get user.email`, if
you aren't certain.

**Note**: Existing users will need to update their configuration to take
advantage of this feature.  For Circle CI users, adding
[.circleci/config.yml](https://github.com/martinthomson/i-d-template/blob/main/template/.circleci/config.yml)
to your repository and removing any existing `circle.yml` file is recommended.
[Travis
support](https://github.com/martinthomson/i-d-template/blob/main/template/.travis.yml)
is less well-tested (and slower).  Updating the
[Makefile](https://github.com/martinthomson/i-d-template/blob/main/template/Makefile)
provides a small additional speed improvement.

**Bug**: Circle CI has a [bug](https://support.circleci.com/hc/en-us/articles/115013854347-Jobs-builds-not-triggered-when-pushing-tag)
that prevents `git push --tags` from triggering builds if you have multiple drafts.
Tag every draft, then push each tag individually.  (Tagging all drafts first means
that cross references will work.)

Once the CI system has built the draft, it will upload it automatically and you
will receive an email asking you to confirm submission.  You don't need to have
a GitHub account token configured for this feature to be enabled.


## Semi-automated Process

Rather than rely on the CI system, the `make upload` command can be used to
upload a tagged draft to the datatracker.

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
