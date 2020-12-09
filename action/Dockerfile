FROM ubuntu:20.04
LABEL maintainer="Martin Thomson <mt@lowentropy.net>"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    coreutils \
    curl \
    git \
    libxml2-utils \
    locales \
    make \
    python-is-python3 \
    python3-certifi \
    python3-chardet \
    python3-dateutil \
    python3-idna \
    python3-intervaltree \
    python3-lxml \
    python3-magic \
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

RUN sed -i -e '/en_US.UTF-8/s/^# *//g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV SHELL /bin/bash

RUN set -e; tool_install() { \
      tool="$1";version="$2";sha="$3"; tmp=$(mktemp -t "${tool}XXXXX.tgz"); \
      curl -sSLf "https://tools.ietf.org/tools/${tool}/${tool}-${version}".tgz -o "$tmp"; \
      [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
      target="/usr/local/bin/${tool}"; \
      tar xzfO "$tmp" "${tool}-${version}/${tool}" >"$target"; rm -f "$tmp"; \
      chmod 755 "$target"; }; \
    tool_install idnits 2.16.05 \
      9f30827e0cf7cf02245e248266ece9557886d33ec7a90cc704b450e70f2cead5 && \
    tool_install rfcdiff 1.48 \
      80c886e76803b889c444cd44781f8fa34cb23943a28f18cac0ea8a1458dca265

RUN set -e; v="2.2.9"; sha="b8c501be4118f79a294b658d963ec8c91595e94aea69c8efd0ea8788c7466c4f"; \
    tmp=$(mktemp -t "mmarkXXXXXX.tgz"); target="${BINDIR:-/usr/local/bin}/mmark"; \
    curl -sSLf "https://github.com/mmarkdown/mmark/releases/download/v${v}/mmark_${v}_linux_amd64.tgz" -o "$tmp"; \
    [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
    tar xzfO "$tmp" mmark >"$target"; \
    rm -f "$tmp"; \
    chmod 755 "$target"

RUN pip3 install --compile xml2rfc
RUN gem install --no-doc kramdown-rfc2629

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
