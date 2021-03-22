# Setting up Github for an IETF WG

* The unit of Github is a repository.
* Repositories are owned by individuals or organizations
* The mapping to IETF concepts is:
    * repository <-> draft(s)
    * organization <-> WG
* There an [IETF organization](https://github.com/ietf), but it's just a shell that maintains pointers to WGs

The starting point for setting up a WG / I-D is here:
  https://github.com/martinthomson/i-d-template

# Prerequisites

* A web browser
* A Github account
* A git client.  Command-line is best, and we'll assume that below.  You can probably accomplish the same thing with a GUI git client, but it will be much harder.  You can get a client at <http://git-scm.com/downloads>
* Tools to "compile" your draft, for which there are instructions here: <https://github.com/martinthomson/i-d-template/blob/main/doc/SETUP.md>

# Setting up an organization

As that document linked above says, the first thing to do is to click the link and set up a new organization.  You will need to choose an organization name and provide a "billing" email (even though you'll use the free version).  The normal pattern for organization names is $WGNAME-wg, e.g., "rtcweb-wg".  For the billing email, it's simplest just to put in the email that goes with your Github account.

Then you'll be prompted to invite other people to the organization.  You should add your co-chair, and maybe the responsible AD.  We'll talk about authors further down, when we talk about repositories.  Click "Finish", and your organization will be created.

Once your organization has been created, you can access it under the "Organizations" section of your Github home page, or at <https://github.com/$ORGNAME>, for example <https://github.com/rtcweb-wg>.


# Setting up a repository for a document

If you go to your organization's page (i.e., the WG's page), then there's a big green button in the middle that says "New Repository".  Click it!

The repository name should be the draft name, without the "draft-ietf-wg" part; that's redundant with the rest of the URL.  So for example, if you were creating draft-ietf-unicorn-tears, the repository name would simply be "tears".  You can leave the "Description" field blank or fill in a brief description; it's just Github eye candy.  Choose "Public" for the visibility level (transparency!).  Finally, make sure that the "Initialize this repository with a README" check box is checked (this will simplify things down the road).

Click "Create Repository", and now you have a repo!


# Allowing people to contribute to a document

In order to keep things orderly, only certain people can commit to a document's repository (or "push" in the git lingo).  The owners of the organization have push privileges by default (that's the chairs and AD you added earlier).  You will need to set the permissions to allow the document author to push to the repository.

This is done by adding authors to a "team" that can push to this repository.  Back on your organization page, find the tab that says "Teams".  Hit the "New Team" button.  Choose a name, such as "$REPOSITORY_NAME editors" (this name is not publicly visible to anyone but you).  Select "Write Access" so that editors can push.  Then, find the search box that says "Add a person" (top right) and add the Github user ids of the editors of the draft.  This will send the authors an invitation that they will need to accept.

Protip: If you have regular contributors to the working group, it might pay to create another group with "Read Access" for those contributors.   This allows you to assign tasks to those people in the Github UI, and makes other user-related functions more accessible.


# Initializing the repository with a document

Since we're talking about a WG document here, we'll assume you've already got an XML or Markdown file that represents the draft.  We will set up the repo to contain that document, along with some tooling that makes it easy to "compile" the document into RFC format.

WARNING: THIS IS THE PART THAT REQUIRES A COMMAND LINE.

Full instructions for initializing the repository are [here](./REPO.md).

In essence, what you're doing is copying over the tooling from a template repository, and then creating the Internet-Draft either from your existing source file, or from a template.  Both XML and Markdown are supported as the draft source.  (There is also experimental support for the [outline2xml](https://github.com/martinthomson/i-d-template/pull/2) format, which has been used for netconf drafts.)

Once you've got your draft populated, just use "make" to create HTML- and TXT-formatted versions Internet-Draft.
