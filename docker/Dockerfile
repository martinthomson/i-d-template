FROM ubuntu:16.04
LABEL maintainer="Martin Thomson <martin.thomson@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates coreutils curl git golang-go locales make \
    python3 python3-lxml python3-pip python3-setuptools python3-wheel \
    ruby \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get autoremove -y && apt-get clean -y

RUN ["pip3", "install", "--compile", "xml2rfc"]
RUN ["gem", "install", "--no-doc", "--no-user-install", "kramdown-rfc2629"]
RUN ["certified-update"]

ADD ["tool_install.sh", "/tmp/tool_install.sh"]
RUN ["bash", "/tmp/tool_install.sh", "idnits", "2.15.00"]
RUN ["bash", "/tmp/tool_install.sh", "rfcdiff", "1.45"]
RUN ["rm", "-f", "/tmp/tool_install.sh"]

RUN ["mkdir", "-p", "/usr/local/bin"]
RUN tmp=$(mktemp -d); export GOPATH="$tmp"; trap 'rm -rf "$tmp"' EXIT; \
    go get github.com/miekg/mmark/mmark && \
    go build -o /usr/local/bin/mmark github.com/miekg/mmark/mmark

ENV USER idci
ENV LOGNAME $USER
ENV HOSTNAME $USER
ENV HOME /home/$USER
ENV SHELL /bin/bash

RUN useradd -d "$HOME" -s "$SHELL" -m "$USER"

WORKDIR $HOME
USER $USER

ENV KRAMDOWN_REFCACHEDIR=$HOME/.cache/xml2rfc
