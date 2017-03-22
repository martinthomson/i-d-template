## When Creating Pull Requests on Another Repository

Make the `origin` remote point to two different places.  Pull from the "main"
repository, and push to your own fork.  Like this:

```sh
$ git clone https://github.com/tlswg/tls13-spec tls13
$ cd quic
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


## When Using kramdown-rfc2629

Set `KRAMDOWN_REFCACHEDIR` in your environment to `~/.cache/xml2rfc`.  If you
have multiple repositories, this means that you only have a single global
cache.  You will download the references for RFC 2119 far less often.  Also,
this is where `xml2rfc` caches references, so both tools will prime the cache
for the other.
