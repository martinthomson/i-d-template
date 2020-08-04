# Installation and Setup

At a minimum, you need `make` and `xml2rfc`.


## make

Mac users might need to install [Homebrew](https://brew.sh) to get a version of
[`make`](https://www.gnu.org/software/make/) that works properly (the version
shipped in XCode is subtly broken).

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
python, or part of the `python-pip` or `python3-pip` package on most
distributions.

On Cygwin, you'll need to install `pip` directly:

```sh
$ curl https://bootstrap.pypa.io/get-pip.py | python
```

Once pip is installed, you can install xml2rfc.

Using a `virtualenv`:

```sh
$ virtualenv venv
# remember also to activate the virtualenv before any 'make' run
$ source venv/bin/activate
$ pip3 install xml2rfc
```

To your local user account:

```sh
$ pip3 install --user xml2rfc
```

Or globally (not advisable):

```sh
$ sudo pip3 install xml2rfc
```

xml2rfc might need development versions of [libxml2](http://xmlsoft.org/) and
[libxslt1](http://xmlsoft.org/XSLT).  These packages are named `libxml2-dev` and
`libxslt1-dev` (Debian, Ubuntu); `libxml2-devel` and `libxslt1-devel` (RedHat,
Fedora); or `libxml2-devel` and `libxslt-devel` (Cygwin).


## Markdown

If you use markdown, you will also need to install `kramdown-rfc2629` or `mmark`.

The template stuff tries to work out which of these you are working with based
on the first line of the file:

* `kramdown-rfc2629` files must start with '---'

* `mmark` files must start with '%%%'

## kramdown-rfc2629

[`kramdown-rfc2629`](https://github.com/cabo/kramdown-rfc2629) requires
[Ruby](https://www.ruby-lang.org/) and can be installed using the Ruby package
manager, `gem`:

```sh
$ gem install kramdown-rfc2629
```


## mmark

[`mmark`](https://github.com/miekg/mmark) requires [go](https://golang.org/), and that comes with its
own complications.

```sh
cd ~/bin
go get github.com/miekg/mmark/mmark
go build github.com/miekg/mmark/mmark
```

You might want to set aside a directory for your go code other than the default,
and find a directory that is on the path where you can install `mmark`.  For
these, I set `GOPATH=~/gocode`.


## Other tools

Some other helpful tools are listed in `config.mk`.
