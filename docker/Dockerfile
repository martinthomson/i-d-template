FROM ubuntu:18.04
LABEL maintainer="Martin Thomson <mt@lowentropy.net>"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates coreutils curl git make ssh libxml2-utils xsltproc \
    python3-minimal python3-lxml python3-pip python3-setuptools python3-wheel \
    python3-dateutil mmark ruby \
 && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
 && apt-get autoremove -y && apt-get clean -y

ENV USER idci
ENV LOGNAME $USER
ENV HOSTNAME $USER
ENV HOME /home/$USER
ENV SHELL /bin/bash

RUN useradd -d "$HOME" -s "$SHELL" -m "$USER"
WORKDIR $HOME
USER $USER

ENV BINDIR $HOME/bin
RUN mkdir -p $BINDIR
ENV PATH $BINDIR:/usr/local/bin:/usr/bin:/bin

RUN set -e; tool_install() { \
      tool="$1";version="$2";sha="$3"; tmp=$(mktemp -t "${tool}XXXXX.tgz"); \
      curl -sSLf "https://tools.ietf.org/tools/${tool}/${tool}-${version}".tgz -o "$tmp"; \
      [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
      target="${BINDIR:-~/.local/bin}/${tool}"; \
      tar xzfO "$tmp" "${tool}-${version}/${tool}" >"$target"; rm -f "$tmp"; \
      chmod 755 "$target"; }; \
    tool_install idnits 2.16.02 \
    e9a501fc1f3a4584dda854067398eaebba29f128fb09f80048a760e950c35c49 && \
    tool_install rfcdiff 1.47 \
    75a9e83869885836c024a94f35128eaf292c6b9de3fd9d3361fbc62d46ec9f16

RUN pip3 install --user --compile xml2rfc && \
    ln -s $HOME/.local/bin/xml2rfc $BINDIR
RUN gem install --no-doc --user-install --bindir $BINDIR \
    certified kramdown-rfc2629 && \
    certified-update

ENV KRAMDOWN_REFCACHEDIR=$HOME/.cache/xml2rfc
RUN mkdir -p $KRAMDOWN_REFCACHEDIR

RUN mkdir -p $HOME/.ssh && \
    echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' >> ~/.ssh/known_hosts

RUN GIT_REFERENCE=$HOME/git-reference; \
    git init $GIT_REFERENCE; \
    git -C $GIT_REFERENCE remote add i-d-template https://github.com/martinthomson/i-d-template; \
    git -C $GIT_REFERENCE remote add rfc2629xslt https://github.com/reschke/xml2rfc; \
    git -C $GIT_REFERENCE fetch --all
