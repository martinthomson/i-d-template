# Installation and Setup

At a minimum, you need `make` and `xml2rfc`.

## make

Mac users will need to install [Homebrew](https://brew.sh) to get a version of
`make` that works properly (the version shipped in XCode is subtly broken).

```sh
brew tap homebrew/dupes && brew install homebrew/dupes/make
```

Add an alias to your `.profile` so that typing 'make' uses `gmake`:

```sh
alias make=gmake
```

Windows users will need to use [Cygwin](http://cygwin.org/) to get `make`.
The fearless can use [bash](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide).

## xml2rfc

All systems require [xml2rfc](http://xml2rfc.ietf.org/).  This
requires [Python](https://www.python.org/).  The easiest way to get
`xml2rfc` is with [pip](https://pip.pypa.io/en/stable/installing/), which
is either installed with python, or part of the `python-pip` package
on most distributions.

On Cygwin, you'll need to install `pip` directly:

```sh
$ curl https://bootstrap.pypa.io/get-pip.py | python
```

Once pip is installed, you can install xml2rfc.

Using a `virtualenv`:

```sh
$ virtualenv --no-site-packages venv
# remember also to activate the virtualenv before any 'make' run
$ source venv/bin/activate
$ pip install xml2rfc
```

To your local user account:

```sh
$ pip install --user xml2rfc
```

Or globally:

```sh
$ sudo pip install xml2rfc
```

xml2rfc depends on development versions of [libxml2](http://xmlsoft.org/) and
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

`kramdown-rfc2629` requires Ruby and can be installed using the Ruby package
manager, `gem`:

```sh
$ gem install kramdown-rfc2629
```


## mmark

`mmark` requires go, and that comes with its own complications.  You will need
to set aside a directory for your go code, and find a directory that is on the
path where you can install `mmark`.  For these, I use `~/gocode` and `~/bin`
respectively:

```sh
export GOPATH=~/gocode
cd ~/bin
go get github.com/miekg/mmark/mmark
go build github.com/miekg/mmark/mmark
```

## Other tools

Some other helpful tools are listed in `config.mk`.
