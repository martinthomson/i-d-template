# Using the Template Repository

A separate [template
repository](https://github.com/martinthomson/internet-draft-template) exists to
help people get started with this tool.  With that repository, setup is a very
simple process.

1. [Create a new repository using the
   template](https://github.com/martinthomson/internet-draft-template/generate).

2. Rename your draft and add a title.  The newly created repository will contain
   a link to a page where you can do this using the GitHub editor.

3. Enable GitHub Pages in the settings for the repository:<br>![choose the gh-pages
   branch and / (root), then hit "Save"](enable-gh-pages.png)

4. Edit the draft using whatever process you like.

5. [Create a new
   release](https://github.com/martinthomson/i-d-template/blob/main/doc/SUBMITTING.md#github-release)
   to submit a new draft to the IETF datatracker.

This uses all the same capabilities as the manual process, so contributors can
still choose to use command-line tools if that suits them.

Note: The newly created repository will run a few actions during this process
that fail.  That's OK.  They will eventually start succeeding.  If it bothers
you, delete the runs in the UI.

<details>

It is not possible to update workflows (the files GitHub Actions use) from an
action unless you use custom personal access tokens.  Rather than complicate the
setup process by requiring a token, this template includes all the necessary
workflow files from the beginning, plus a special setup workflow.  Before the
repository is properly setup, the other workflows will fail immediately (and
safely).  The setup workflow removes itself once it is successful.

</details>
