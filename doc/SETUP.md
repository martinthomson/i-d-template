# Installation and Setup

At a minimum, you need `make` and `python3` with `pip`.


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
[`make`](https://www.gnu.org/software/make/) that fully supports all of the template
features.  Apple ships an old version of GNU make with XCode which can fail in
mysterious ways.  Some effort has been made to avoid this bustage, so most
features work fine, but no warranty is made if something breaks.

```sh
brew install make
```

Note that this installs as `gmake`.  Follow the instructions to add this as
`make` to your path.

Windows users will need to use [Cygwin](http://cygwin.org/) or [the Windows
Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
to get `make`.


## Python

All systems require [Python 3](https://www.python.org/). Be sure not to get
Python 2 or anything older than Python 3.6, which are no longer supported.

This tool uses [`pip`](https://pip.pypa.io/en/stable/installing/) and
[`venv`](https://pypi.org/project/virtualenv/).  These might be installed with
python, but they can be part of separate packages (look for `python3-pip` and
`python3-venv`).


## mmark

If you use mmark for markdown (i.e., files starting with `%%%`), you will need
to install it.

[`mmark`](https://github.com/mmarkdown/mmark) requires
[go](https://golang.org/), and that comes with its own complications.  This
assumes that you have Golang setup already.

```sh
$ go get github.com/mmarkdown/mmark
$ GOBIN=~/.local/bin go install github.com/mmarkdown/mmark
```

You might want to set aside a directory for your go code other than the default,
and find a directory that is on the path where you can install `mmark`.  For
these, I set `GOPATH=~/gocode`.

Make sure to update them regularly:

```sh
$ go get -u github.com/mmarkdown/mmark@latest
$ GOBIN=~/.local/bin go install github.com/mmarkdown/mmark@latest
```
