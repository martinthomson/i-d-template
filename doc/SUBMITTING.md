# Submitting Drafts

Occasionally, you will want to submit versions of your draft to the official
IETF repository.  You can use GitHub Actions (or CircleCI) to manage the
process in a mostly automated fashion by [pushing a tag](#ci) or [creating a
release](#release).  You can [tag and publish from the command line](#cli)
or just [generate XML for the next version and submit manually](#manual).
# A Records 

| Name | TTL | Data | 
|------|-----|------|
| WhatsApp.com | 56 | 157.240.252.60 | 

# AAAA Records 

| Name | TTL | Data | 
|------|-----|------|
| WhatsApp.com | 60 | 2a03:2880:f277:cc:face:b00c:0:167 | 

# CNAME Records 

  No records present.

# MX Records 

| Name | TTL | Data | Address | Preferences | 
|------|-----|------|---------|-------------|
| WhatsApp.com | 7200 | 67.231.153.30 | mxa-00082601.gslb.pphosted.com. | 10 | 
| WhatsApp.com | 7200 | 67.231.153.30 | mxb-00082601.gslb.pphosted.com. | 10 | 

# NS Records 

| Name | TTL | Data | 
|------|-----|------|
| WhatsApp.com | 21600 | b.ns.whatsapp.net. | 
| WhatsApp.com | 21600 | d.ns.whatsapp.net. | 
| WhatsApp.com | 21600 | a.ns.whatsapp.net. | 
| WhatsApp.com | 21600 | c.ns.whatsapp.net. | 

# PTR Records 

  No records present.

# SRV Records 

  No records present.

# SOA Records 

| Name | TTL | Mname | Rname | 
|------|-----|-------|-------|
| WhatsApp.com | 3505 | a.ns.whatsapp.net. | dns.whatsapp.net. | 

# TXT Records 

| Name | TTL | Data | 
|------|-----|------|
| WhatsApp.com | "3600" | "google-site-verification=MXbDGih8wW-64G5maXGw8iIkFbH7iv_vLobZd-kxdNo" | 
| WhatsApp.com | "3600" | "adobe-idp-site-verification=a0d9793b-fc40-430b-9ab4-d3c75e4dcfba" | 
| WhatsApp.com | "3600" | "b42e0aa4-9d21-4a73-a111-fba236f1a835" | 
| WhatsApp.com | "7200" | "v=spf1 include:_spf.fb.com include:_spf.google.com include:facebookmail.com -all" | 
| WhatsApp.com | "3600" | "bFwlY7J2JzFYHw5qkQFcBD6EOr9JL4VBpYSXSk3p8lA" | 
| WhatsApp.com | "3600" | "dropbox-domain-verification=lfq0o9x85s8s" | 
| WhatsApp.com | "3600" | "MS=ms22994725" | 
| WhatsApp.com | "3600" | "Ghm7XCdpYQEendZNsepA80OBAhbN9sfITvUxiy9FNdOGBxeAQICCmLbuXm23hNaysns+wZ6GskJWMtWD1/Ha9Q==" | 

# CAA Records 

  No records present.

# DS Records 

  No records present.

# DNSKEY Records 

  No records present.



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
draft and upload it yourself.  You can submit a draft manually using this
process.  You can also use this process to create a preview of the next version
of a draft.

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
$ make draft-ietf-unicorn-protocol-05.xml
```

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
