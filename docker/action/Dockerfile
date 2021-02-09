FROM alpine:latest
LABEL maintainer="Martin Thomson <mt@lowentropy.net>"

RUN set -e; \
    echo > /etc/apk/repositories; \
    echo http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main >> /etc/apk/repositories; \
    echo http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community >> /etc/apk/repositories; \
    apk add --no-cache \
      bash \
      ca-certificates \
      coreutils \
      curl \
      findutils \
      git \
      grep \
      libintl \
      libxml2-utils \
      libxslt \
      make \
      openssh \
      py3-appdirs \
      py3-configargparse \
      py3-html5lib \
      py3-jinja2 \
      py3-lxml \
      py3-magic \
      py3-pip \
      py3-pycountry \
      py3-pyflakes \
      py3-requests \
      py3-setuptools \
      py3-six \
      python3 \
      ruby \
      sed

# See <https://github.com/Auswaschbar/alpine-localized-docker/blob/master/Dockerfile>
ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"
RUN set -e; \
    apk add --no-cache --virtual .locale_build cmake musl-dev gcc gettext-dev; \
    tmp=$(mktemp -d /tmp/musl-locales-XXXXX); \
    git clone https://gitlab.com/rilian-la-te/musl-locales "$tmp"; \
    cd "$tmp"; \
    cmake -DCMAKE_BUILD_TYPE=Release -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr .; \
    make; \
    make install; \
    cd /; \
    rm -rf "$tmp"; \
    apk del .locale_build

ENV SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

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
RUN set -e; \
    gem install --no-doc kramdown-rfc2629; \
    certified-update

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
