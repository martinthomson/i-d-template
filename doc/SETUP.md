# Installation and Setup

At a minimum, you need a POSIX environment with:

* `make`
* `python3` with `pip` and `venv`
* `ruby` with `gem` and `bundler`

Optionally, you might also want `mmark` or NodeJS and `npm`.

When running locally, a python virtual environment is created under `lib/` and
necessary tools are installed there.  Similarly, ruby installations are created
under `lib/`.  The tools that are used can be updated with `make update-deps`.


## General

These tools work well natively on Linux and Mac.

Windows users should use [the Windows Subsystem for
Linux](https://docs.microsoft.com/en-us/windows/wsl/install) with a Linux
distribution like Ubuntu (`wsl --install -d Ubuntu` from an administrator
prompt).

From within Ubuntu, you can install the dependencies for this repository:

```sh
sudo apt-get install -y git make python3-pip python3-venv
```

You can also add recommended packages, as follows:

```sh
sudo apt-get install -y ruby-bundler npm libxml2-utils
```

It is also possible to use [cygwin](https://cygwin.org/) or an
[MSYS2](https://www.msys2.org/)-based system (like
[Mozilla-Build](https://wiki.mozilla.org/MozillaBuild)), but these can be more
difficult to setup and use.


## make

Mac users might need to install [Homebrew](https://brew.sh) to get a version of
[`make`](https://www.gnu.org/software/make/) that fully supports all of the template
features.  Apple ships an old version of GNU make with XCode which can fail in
mysterious ways.  Some effort has been made to avoid this bustage, so most
features work fine, but no warranty is made if something breaks.

```sh
brew install make
```

Note that this might install as `gmake`.  Follow the instructions to add this as
`make` to your path.


## Python

You need to provide [Python 3](https://www.python.org/). Be sure not to get
Python 2 or anything older than Python 3.6, which are no longer supported.

[`pip`](https://pip.pypa.io/en/stable/installing/) and
[`venv`](https://docs.python.org/3/library/venv.html) are used to install
packages into a temporary virtual environment.  These are sometimes installed
with python, but some Linux distributions can put these in separate packages
(look for `python3-pip` and `python3-venv`).


## Ruby

By default, [Ruby](https://www.ruby-lang.org/) is used to install
[kramdown-rfc](https://github.com/cabo/kramdown-rfc).  This is installed using
the Ruby [bundler](https://bundler.io/), which also requires the Ruby package
tool, [`gem`](https://rubygems.org/).

The `gem` tool is often installed alongside Ruby, but you might need to install
bundler separately (look for `ruby-bundler`).

You can pass `NO_RUBY=true` as an argument to `make` or export an environment
variable with that value to disable this feature.


## mmark

If you use `mmark` for markdown (i.e., files starting with `%%%`), you will need
to install and manage an `mmark` installation.

Binaries for [`mmark`](https://github.com/mmarkdown/mmark) is available from
their [releases](https://github.com/mmarkdown/mmark/releases) and Mac users can
use homebrew (`brew install mmark`).


## npm

If you use dependencies such as [aasvg](https://github.com/martinthomson/aasvg),
you need to have NodeJS and npm installed.

If `npm` is installed and your project has a `package.json`, then running `make`
will automatically call npm to install the dependencies.

You can create the `package.json` by running `npm`, for example:

```sh
$ npm i -save aasvg
$ git add package.json
$ git commit
```
