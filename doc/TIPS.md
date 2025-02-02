## When Something Goes Wrong

Sometimes, something breaks.  There are a few things you can try to reset and
continue.

Cleaning temporary files might help.

```sh
$ make clean
```

You can also update the template (`update`),
the tools that are automatically installed (`update-deps`), or
the files that are copied to your repository (`update-files`).

```sh
$ make update
$ make update-deps
$ make update-files
```

Sometimes, it can help to blow away the `lib` directory:

```sh
$ rm -rf lib
```


## Save Space

The `lib` directory can get pretty big, because it contains copies of all
of the tools that your draft needs.  If you have multiple drafts, you can
point all those drafts to the same checkout with a symlink, as long as you
aren't using `git submodules`:

```sh
$ rm -rf lib
$ ln -s ../some-other-draft/lib lib
```

An advantage of this is that updates to `xml2rfc` and other tools that
are triggered from one repository will be available to all others.

This largely works even if you have different configurations for each
repository. For instance, if you have a `Gemfile` or `requirements.txt`,
any tool that one repository installs will be available to all others.
You do need to remember to list tools in one of these files if you use
them, or builds will fail in CI or for other people.

Set `ID_TEMPLATE_HOME` in your environment to a common location
(such as a checkout of this repository) and the `Makefile` will create
a symlink for you[^old].

```sh
$ git clone https://github.com/martinthomson/i-d-template i-d-template
$ echo 'export ID_TEMPLATE_HOME="'"$(pwd)"'/i-d-template"' >> ~/.profile
```

[^old]: Old versions of the `Makefile` don't, so you might need to update.


## When Creating Pull Requests on Another Repository

Make the `origin` remote point to two different places.  Pull from the "main"
repository, and push to your own fork.  Like this:

```sh
$ git clone https://github.com/tlswg/tls13-spec tls13
$ cd tls13
$ git remote set-url --push origin https://github.com/martinthomson/tls13-spec
$ git remote -v
origin  https://github.com/tlswg/tls13-spec (fetch)
origin  https://github.com/martinthomson/tls13-spec (push)
```

Now when you pull, you will pull from the "main" repository, but pushes go to
your private branch.

If you work on multiple machines and use push and pull to synchronize, you can
setup another remote for your fork, or just pull or fetch directly by
specifying the full remote name:

```sh
$ git pull https://github.com/martinthomson/tls13-spec main
$ git fetch https://github.com/martinthomson/tls13-spec
```


## Cleaning Old Branches

If you work on many pull requests over time, you will create many branches.
Even if you delete the branch on GitHub, your local repository can have lots
of dead branches.  The following creates a command, `git trim` that prunes
branches that have been merged.

```sh
$ git config --global alias.trim '!f() { git branch --merged @ | sed -e '"'"'/^\*/d;s/^  //;/^\('"'"'$(git config --get trim.savebranch | sed -e '"'"'s/[, ]/\\|/g'"'"')'"'"'\)$/d'"'"' | xargs -r git branch -d; }; f'
$ git config --global trim.savebranch main,gh-pages,gh-issues
```

The `trim.savebranch` config item includes the names of branches that you
want to keep always.


## No Unnecessary Merges on Pull

When you pull, git can decide to merge for you if your branch has diverged.
This can be annoying to recover from.  Setting the following configuration
ensures that you don't create merge commits when you pull:

```sh
$ git config --global pull.ff only
```

Now when you pull, your local changes will be rebased onto remote changes.


## When Using kramdown-rfc

Set `KRAMDOWN_REFCACHEDIR` in your environment to `~/.cache/xml2rfc`.  If you
have multiple repositories, this means that you only have a single global
cache.  You will download the references for RFC 2119 far less often.  Also,
this is where `xml2rfc` caches references, so both tools will prime the cache
for the other.

Always include the following in the YAML header of the markdown file:

```yaml
v: 3
```
