# Submitting Drafts

Occasionally, you will want to submit versions of your draft to the official
IETF repository.  You can use GitHub Actions (or CircleCI) to manage the
process in a mostly automated fashion by [pushing a tag](#ci) or [creating a
release](#release).  You can [tag and publish from the command line](#cli)
or just [generate XML for the next version and submit manually](#manual).


<a name="ci"></a>
## Using Continuous Integration

If you have enabled continuous integration, the CI system can automatically
upload a draft to the datatracker.  All you have to do is tag the repository,
push the tag, and await an email with further instructions.

```sh
$ git push origin <branchname>
$ git tag -a draft-ietf-unicorn-protocol-00
$ git push origin draft-ietf-unicorn-protocol-00
```

The tag you use has to include the full name of the draft without any file
extension.  That name must include a revision number.  The tag also has to match
the name of the source file.  For the above example, the tag will submit a draft
named `draft-ietf-unicorn-protocol.md` or `draft-ietf-unicorn-protocol.xml`.

If you have multiple drafts that you are submitting together, tag them all then
push the tags at the same time.  Circle CI has a
[bug](https://support.circleci.com/hc/en-us/articles/115013854347-Jobs-builds-not-triggered-when-pushing-tag)
that prevents `git push --tags` from triggering builds if you have multiple
drafts, but pushing individual tags in quick succession will work.

For this feature to work best, use an annotated tag (that's the `-a` option
above).  Annotated tags require a comment (use `-m` to set this on the
command line).  An annotated tag associates your email address with the
submission.  Lightweight tags don't have an email address and the first author
listed in the draft will be attributed instead.

**Important**: Before you start, push the commit that you intend to tag. A CI
build will check that the draft can be built correctly so that you don't tag a
broken state.  Pushing the tag won't also push the commit it references and so
the build will not run, perhaps not ever.

**Note**: The email address you use for making this submission needs to match a
verified datatracker account email address ([create one
here](https://datatracker.ietf.org/accounts/create/)).  The email address that
git uses can be found by calling `git config --get user.email`, if you aren't
certain.

Once the CI system has built the draft, it will publish it automatically and you
will receive an email asking you to confirm the submission.  You don't need to
have a GitHub account token configured for this feature to be enabled.

If you have renamed a draft, this will also set the "replaces" field for you
automatically, based on the git history of the file.


<a name="release"></a>
## GitHub Release

Creating a GitHub release using the intended draft name is an easy way to submit
versions without using the command line.  Simply publish a new release that uses
a tag in the form `draft-<author>-<wg>-<name>-<vv>`.  GitHub Actions will take
care of generating XML and submitting it to the datatracker; see above.

This will attribute the submission to the first author listed in the draft, no
matter who generated the release, just like with a lightweight tag.


## Picking an Email

The IETF datatracker is quite picky about the email that is associated with a
submission.  To work around that, there are several ways email addresses are
chosen for a submission.

1. An email address can be set when manually running the GitHub action.
   This isn't a common way of requesting submission, but you might manually run
   the action if a build fails.

3. Setting a variable called `UPLOAD_EMAIL` in your Makefile.  Make sure to
   export the value:

```make
export UPLOAD_EMAIL ?= my@email.example
```

3. The email address you used to create the tag (annotated tags only).
   This will come from your git configuration.

4. Your GitHub account email address.

5. The email address of the first author in the draft.

You can tell datatracker about your email address(es)
[here](https://datatracker.ietf.org/accounts/profile/).  You might need to
ensure that the first email the above process finds is the primary address
known to the datatracker.


## If the Build Fails

Sometimes the build will fail.  Some errors can be worked around by retrying the
build.  Both GitHub Actions and CircleCI offer options to restart the build from
the status page.  If you think that an error isn't your fault, try running the
build again.

If you need to fix a problem in the draft, you can delete the tag:

```sh
$ git tag -d draft-ietf-unicorn-protocol-03
$ git push origin :draft-ietf-unicorn-protocol-03
```

Fix the draft, push the changes, let the CI check them, then you can reapply the
tag.


<a name="cli"></a>
## Semi-automated Process

You should only really do this if you don't have CI enabled or if the CI build
fails.  The `make publish` command can be used to upload a tagged draft to the
datatracker.

```sh
$ git tag -a draft-ietf-unicorn-protocol-03
$ make publish
```

This uses the same process that the CI system uses.  If you have multiple tags
pointing to the current HEAD, this will attempt to publish all of those drafts.

Push tags when you are happy with the submission.  If CI is enabled, it might
try to upload and fail, but that's OK.  Datatracker will safely reject duplicate
submissions.


<a name="manual"></a>
## Manual Process

If you don't want to use automation, you can make a submission version of your
draft and upload it yourself.  Or, in rare circumstances, you might have to
email a draft for submission.  You can generate the next numbered version of a
draft using this process, or you can generate any previously tagged version of
a draft.  Numbered drafts will be created in a directory named `versioned`.

This uses git tags to work out what versions exist already, so always use tags.
`make next` will calculate the next version number based on what is tagged. When
there are no tags, it starts at `-00`.

```sh
$ make next
```

If you already have a tag in place or want to build a specific tag, you can
identify the specific XML file directly.  This works for any version you have
submitted.

```sh
$ make versioned/draft-ietf-unicorn-protocol-05.xml
```

**Note**: For older versions of `make`, you might have to run `make extra`
before these targets become available.

[Submit the .xml file](https://datatracker.ietf.org/submit/).  Please don't
submit a `.txt` file.

If you submit manually, tag your repository and upload the tags so that the next
version can be generated correctly.  The tag you should use is the full draft
name including a revision number.

```sh
$ git tag -a draft-ietf-unicorn-protocol-05
$ git push origin draft-ietf-unicorn-protocol-05
```

Don't worry if you have CI enabled.  CI might try to build and publish the
draft.  This will fail as datatracker safely rejects duplicate submissions.
