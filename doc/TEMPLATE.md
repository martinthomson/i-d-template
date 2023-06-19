# Using the Template Repository

For creating and managing an [Internet-Draft](https://authors.ietf.org/en/content-guidelines-overview) (I-D).

A separate [template
repository](https://github.com/martinthomson/internet-draft-template) exists to
help people get started with this tool.  With that repository, setup is a very
simple process.

1. [Create a new repository using the
   template](https://github.com/martinthomson/internet-draft-template/generate).
   Check "Include all branches", or you will need to enable GitHub Pages
   manually after step 2.
   
2. Allow GitHub Workflows to make changes to the repository.  Click the gear icon
   to open the settings for your repo, then select Actions > General in the list
   on the left.  Under "Workflow permissions", select "Read and write permissions".

3. Rename your I-D and add a title.  The newly created repository will contain
   a link to a page where you can do this using the GitHub editor.  Setup will
   automatically run.  Setup should be done in less than a minute.

Now you are set to work on the document, using whatever process you choose.
This uses all the same capabilities as the manual process, so contributors can
use command-line tools if that suits them.

To publish an I-D, [create a new
release](https://github.com/martinthomson/i-d-template/blob/main/doc/SUBMITTING.md#github-release)
and the draft will be submitted to the datatracker automatically.

Note: The newly created repository will run a few actions during this process
that might fail.  That's OK.  They will succeed once you edit the draft.  If it
bothers you, delete the runs in the UI.

<details>

It is not possible to update workflows (the files GitHub Actions use) from an
action unless you use custom personal access tokens.  Rather than complicate the
setup process by requiring a token, this template includes all the necessary
workflow files from the beginning, plus a special setup workflow.  Before the
repository is properly setup, the other workflows will fail immediately (and
safely).  The setup workflow removes itself once it is successful.

</details>
