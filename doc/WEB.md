# Using GitHub's Web Interface

You can use GitHub's Web Interface to accomplish most editing tasks.  This is
not always as efficient as the command line.

To make a change, you [create a pull request](#create), [review it](#review),
and [merge it](#merge).

This page walks through that process in some detail, in case you aren't familiar
with the process.  It also covers some [troubleshooting practices](#busted) for
when things (inevitably) go wrong.

If you are looking for how to submit a draft using the GitHub UI, see [the
instructions for draft submission](SUBMITTING.md#github-release).

<a id=create>

## Creating Pull Requests

This is the best way to manage the content of files, especially when you are
working with others.

Navigate to the draft you want to edit by first going to the
repository (`https://github.com/_$user_/_$repo_`) and selecting the draft
(`https://github.com/_$user_/_$repo_/blob/main/draft-_$name_.md`).

You will see, in the upper right, an edit button, often presented with a pencil
(✏️) icon:

![GitHub UI showing Edit button](images/edit.png)

If you don't have edit access to the repository, GitHub will automatically
create a copy of the repository in your personal space if you don't have one
already.  This allows you to make changes (or commits) without affecting the
main or authoritative copy.

Make your changes.

At the bottom of that page, there is a form where you commit your changes.
Enter some notes about the changes you made.  Make [the commit message
good](http://whatthecommit.com/).

If you have commit access, then you will be presented with an option to create a branch:

![GitHub UI showing a choice to create a new branch for changes](images/commit-branch.png)

Choose this option and maybe select a helpful name for the branch.

If you don't have commit access, then this option does not appear.  GitHub will
create a branch for you.  These are given useless names like `patch-1`,
`patch-2`, etc..., which isn't very descriptive, but that doesn't matter too
much.

Hit the "Propose changes" button.

If you don't have commit access, this first shows a page where it summarizes
your changes, with the following message:

![GitHub UI showing the pull request message](images/pr-interstitial.png)

Just hit the "Create pull request" button and move to the next step.

From here, you will have a form where you can create a pull request.  The form
will be pre-filled with any comments you already added.  Below this form will be
a view of the changes you made.

![GitHub UI pull request form](images/pr.png)

Review your comments and your changes, then hit the "Create pull request"
button.

The [GitHub
documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
contains more information on creating pull requests.

<a id=review>

## Reviewing Pull Requests

Editors of documents (those with commit access to the repository) can review and
merge pull requests.  Simply go to the pull requests on the repository
(`https://github.com/_$user_/_$repo_/pulls`) and select the pull request.  This
will initially present a page that shows the summary provided by the author of
the pull request and any discussion that has occurred.

Here you can add new comments, but the most useful information is the changes
that are being proposed.  To see these, look for the "Files changed" tab, shown
here:

![GitHub UI highlighting where the changed files are](images/pr-files.png)

Select this and you will see all the details of the files that have changed.
From this page, you can enter a review.

Leave comments on specific lines by selecting a change.  You can click on the
"+" icon that appears when you hover over each line to add a comment on that
line.

![GitHub UI showing a comment icon on a focused line](images/comment-line.png)

You can also drag the mouse to select more than one line, something you will
want to do if you are making suggestions.

Suggestions are great.  Suggestions make it a lot easier to act on comments. See
[GitHub
documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request)
for generating reviews, which explains how to make suggestions.

Add comments on any changes, then select the "Review changes" button (near the
top) where you can add some general comments about the changes and choose
between "Comment", "Approve" or "Request changes".

![GitHub UI showing the review summary panel](images/[pr-review.png)

Anyone can review a pull request this way, but reviews from editors that
"Approve" or "Request changes" will be displayed differently by GitHub.

<a id=update>

## Updating Pull Requests

During review, people might ask for small changes.

Requests for changes can be accompanied by suggestions.  This is a great
feature, so please [read about
it](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/incorporating-feedback-in-your-pull-request#applying-a-suggested-change)
and use it.  Authors of pull requests and (usually) editors of documents can
accept suggestions through the GitHub UI.  If you have multiple suggestions, try
adding them to a batch rather than merging them one by one.

If comments require changes that aren't in the form of suggestions, you can edit
the file by navigating to the "Files changed" tab and hitting the ellipsis
button for the changed file, this shows an option to edit the file.

![GitHub UI showing the choice to edit a file in a pull
request](images/pr-edit.png)

You will then be presented with the same edit interface as before.

After making changes to a pull request, do not create a new branch for the
changes, just commit directly to the branch.  (Well, you *can* but then you will
be creating a pull request against a pull request and that usually leads to
someone getting confused and bad things happening, so maybe avoid that.)

![GitHub UI showing the choice to commit directly to the pull request
branch](images/pr-update.png)

Use the "Commit changes" button to confirm any changes.

<a id=merge>

## Merging Pull Requests

Once a pull request is ready, it can be merged by an editor by hitting the
"Merge pull request" button.

![GitHub UI showing the merge option](images/pr-merge.png)

Then hit the "Confirm merge" button.

<a id=busted>

## Dealing with Problems

Sometimes this process doesn't go smoothly.


### Broken Builds

The previous examples showed a good change.  Occasionally, changes will result
in breaking the draft build.  Maybe the change included a missing reference.
This will show in the interface with a big X mark, something like this:

![GitHub UI showing a broken pull request](images/pr-broken.png)

This pull request should not be merged until the build problem is fixed, usually
by [updating the pull request](#update).


### Merge Conflicts

Sometimes two pull requests affect the same part of a file.  If one is merged,
GitHub might be unable to merge the other.  GitHub will offer the option to
"Resolve conflicts" as follows:

![GitHub UI showing a merge conflict](images/pr-conflict.png)

This leads to a page where you can edit the affected files.  This is similar to
the editing interface, but the conflicting lines of the file will be highlighted.

Control options are shown at the top, with the number of conflicts found, and
buttons that let you jump between them.

![GitHub UI showing merge conflict summary and controls](images/pr-resolve-controls.png)

The conflict will be displayed inline in the document, something like this:

```
<<<<<<< your-branch-name
lines
from
your
change
=======
lines
from
the
main
branch
>>>>>>> main
```

Replace all of this - including the "<<<" or ">>>" lines - with the content you
wish to include for each conflict.  Use the "Prev" and "Next" buttons to quickly
find multiple conflicts.

Usually this means understanding what has happened to make the two sets of lines
diverge, which can be tricky, so take some care.

Once you are done, hit the "Mark as resolved" button, then "Commit merge".


### Reverting Pull Requests

If a bad pull request is merged, perhaps because it makes the draft no longer
build correctly, it can be reverted.

![GitHub UI showing an option to revert a pull request](images/pr-revert.png)

The "Revert" button opens a page where you can create a pull request that
reverses the changes.  Create, review, and merge this pull request as normal.


## Linking to Issues

Any pull request can be linked to one or more issues.  When the pull request is
merged, those issues will be automatically closed.  This feature allows for
better tracking of the resolution of issues, as the change can then be traced to
the issue and the resolution can be traced from the issue.

By adding "closes #101" or "fixes #42" to the commit message or description of a
pull request, the link is created automatically.  Usually, this instruction is
put on a separate line so it is easy to notice; if a pull request closes
multiple issues, list each issue on a new line.

The "Development" option shown on the right hand side of an issue or pull
request page can be used to link issues and pull requests.  This can be used in
case the comments do not include the "Closes" or "Fixes" text.

Tip: A pull request can be linked to another pull request.  For example, if two
alternatives solutions are proposed, each might link to the other.  When one is
merged, the other is then closed.


## YOLO

Editors of a document (those with commit access to the repository) can edit
files directly.  From the page where you make changes, the option to "Commit
directly to the `main` branch" will be selected **by default**.

![GitHub UI showing an option to commit directly to the `main`
branch](images/commit-main.png)

Leave this option selected, then hit the "Commit changes" button.  This will
make the changes directly to the document.

Avoid this approach if you are working with other people, even if you are sole
editor for a working group document.  Also avoid doing this if you don't like
dealing with a document that is broken.
