# Adopting a Draft

When a working group adopts an individual draft that was created with this
template, the obvious ways of migrating a repository to a different organization
are often not great.

Firstly, **do not create a fork**.  There are better options.


## Best Option - Transfer the Repository

If you are an owner of the source repository and part of the target organization,
you can transfer the repository.  That brings all the pull requests and issues
with it.  That's nice if you can do that.

To do this, make the current author/editor part of the working group organization.
Then they can go to the settings tab for the repository and transfer.  This can
be found at the very bottom of the page, in the "Danger Zone".

**Note:** I don't know what the precise set of privileges need to be given to
allow this to happen.  More testing is needed.


## Alternative - Copying History

In case you can't transfer, you can copy the history of the old repository into
a new repository.  For this, you don't need any special roles, just the ability
to push to the new repository.

Make a new repository.  Make sure that it is empty when you make it (don't
create a README when GitHub asks).  Then make a new repository locally:

```sh
$ git init new-repo
$ cd new-repo
$ git remote add origin https://github.com/new-owner/new-repo
```

Then pull the contents of the old repo in:

```sh
$ git pull https://github.com/old-owner/old-repo master
$ git push
```

You then need to setup the `gh-pages` and `gh-issues` 
branches:

```sh
$ make
$ make -f lib/setup.mk setup-ghpages setup-ghissues
```


## Cleanup

After transfering or copying rebuild the README:

```sh
$ make -f lib/setup.mk README.md
$ git commit -m "Update README" README.md
```

 If you have made changes to this from the template, you can just update the
 intro text and the links.
 
 You might also need to redo and CI setup.
