# Installation and Setup

At a minimum, you need `make` and `xml2rfc`.

Occasionally, you will want to [Update](#update) these tools.


## PATH

These instructions assume that you want to install to `~/.local/bin` and that
that directory is on `$PATH`.  You can replace this path with your preferred
binary location throughout.

To put this directory on your path, modify `~/.profile` as follows:

```
$ mkdir -p ~/.local/bin
$ echo 'export PATH="${PATH}:~/.local/bin"' >> ~/.profile
```

Note that most of these tools default to installing for all users, which you are
free to do, but a user-based install is easier to manage without invoking
`sudo` and the like.


## make

Mac users might need to install [Homebrew](https://brew.sh) to get a version of
[`make`](https://www.gnu.org/software/make/) that works properly (the version
shipped with XCode is subtly broken).

```sh
brew install make
```

Note that this installs as `gmake`.  Follow the instructions to add this as
`make` to your path.

Windows users will need to use [Cygwin](http://cygwin.org/) or [the Windows
Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
to get `make`.


## xml2rfc

All systems require [xml2rfc](http://xml2rfc.tools.ietf.org/).  This
requires [Python 3](https://www.python.org/).  Be sure not to get Python 2,
which is no longer supported.  The easiest way to get `xml2rfc` is with
[pip](https://pip.pypa.io/en/stable/installing/), which is either installed with
python, or part of the `python3-pip` (sometimes `python-pip`) package on most
distributions.

On some systems, you might need to install `pip` the hard way:

```sh
$ curl https://bootstrap.pypa.io/get-pip.py | python
```

Once pip is installed, you can install xml2rfc.


```sh
$ pip3 install --user xml2rfc
```

xml2rfc might need development versions of [libxml2](http://xmlsoft.org/) and
[libxslt](http://xmlsoft.org/XSLT).  These packages are named `libxml2-dev` and
`libxslt1-dev` (Debian, Ubuntu); `libxml2-devel` and `libxslt1-devel` (RedHat,
Fedora); `libxml2-devel` and `libxslt-devel` (Cygwin); or `libxml2` and
`libxslt` (Mac Homebrew).


## Archive-Repo

The archive-repo script is used by CI jobs and `make archive` to create an
archival copy of GitHub issues and pull requests.  It is not needed for most
local authoring.

If you need it, it can be installed with pip, as above.

```sh
$ pip3 install --user archive-repo
```


## Markdown

If you use markdown, you will also need to install `kramdown-rfc2629` or `mmark`.

The template stuff tries to work out which of these you are working with based
on the first line of the file:

* `kramdown-rfc2629` files must start with '---'

* `mmark` files must start with '%%%'


### kramdown-rfc2629

[`kramdown-rfc2629`](https://github.com/cabo/kramdown-rfc2629) requires
[Ruby](https://www.ruby-lang.org/) and can be installed using the Ruby package
manager, `gem`:

```sh
$ gem install --user-install -N -n ~/.local/bin kramdown-rfc2629 net-http-persistent
```

Note: Installing net-http-persistent makes this a lot faster.


### mmark

[`mmark`](https://github.com/mmarkdown/mmark) requires
[go](https://golang.org/), and that comes with its own complications.  This
assumes that you have Golang setup already.

```sh
$ GOBIN=~/.local/bin go install github.com/mmarkdown/mmark@latest
```

You might want to set aside a directory for your go code other than the default,
and find a directory that is on the path where you can install `mmark`.  For
these, I set `GOPATH=~/gocode`.


## Other tools

Some other helpful tools are listed in `config.mk`.


# Update

Once you have these tools installed, it's worth updating occasionally.  Here's a
quick set of shortcuts for these tools.

```sh
$ pip3 install --user --upgrade xml2rfc archive-repo
$ gem uninstall --user-install -n ~/.local/bin kramdown-rfc2629 net-http-persistent
$ gem install --user-install -N -n ~/.local/bin kramdown-rfc2629 net-http-persistent
$ GOBIN=~/.local/bin go install github.com/mmarkdown/mmark@latest
```
