FROM ubuntu:18.04
LABEL maintainer="Martin Thomson <mt@lowentropy.net>"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    coreutils \
    curl \
    git \
    libxml2-utils \
    make \
    mmark \
    python3-certifi \
    python3-chardet \
    python3-dateutil \
    python3-idna \
    python3-intervaltree \
    python3-lxml \
    python3-minimal \
    python3-pip \
    python3-pycountry \
    python3-pyflakes \
    python3-requests \
    python3-setuptools \
    python3-sortedcontainers \
    python3-urllib3 \
    python3-webencodings \
    python3-wheel \
    ruby \
    ssh \
    xsltproc \
 && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
 && apt-get autoremove -y && apt-get clean -y

ENV SHELL /bin/bash

RUN set -e; tool_install() { \
      tool="$1";version="$2";sha="$3"; tmp=$(mktemp -t "${tool}XXXXX.tgz"); \
      curl -sSLf "https://tools.ietf.org/tools/${tool}/${tool}-${version}".tgz -o "$tmp"; \
      [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
      target="/usr/local/bin/${tool}"; \
      tar xzfO "$tmp" "${tool}-${version}/${tool}" >"$target"; rm -f "$tmp"; \
      chmod 755 "$target"; }; \
    tool_install idnits 2.16.04 \
      1eef34b131d9c0b45090192f972db0b5dae15047271a7962959c8019dd8cc06b && \
    tool_install rfcdiff 1.47 \
      75a9e83869885836c024a94f35128eaf292c6b9de3fd9d3361fbc62d46ec9f16

RUN pip3 install --compile xml2rfc
RUN gem install --no-doc kramdown-rfc2629

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
