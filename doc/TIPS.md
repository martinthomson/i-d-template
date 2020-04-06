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
$ git pull https://github.com/martinthomson/tls13-spec master
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


## When Using kramdown-rfc2629

Set `KRAMDOWN_REFCACHEDIR` in your environment to `~/.cache/xml2rfc`.  If you
have multiple repositories, this means that you only have a single global
cache.  You will download the references for RFC 2119 far less often.  Also,
this is where `xml2rfc` caches references, so both tools will prime the cache
for the other.
