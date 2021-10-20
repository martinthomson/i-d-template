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
      nodejs \
      npm \
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
      py3-wheel \
      py3-yaml \
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
    LC_ALL=en_US.UTF-8 \
    KRAMDOWN_PERSISTENT=t \
    KRAMDOWN_REFCACHEDIR=/root/.cache/xml2rfc

RUN set -e; \
    install() { \
       file="$1"; url="$2"; sha="$3"; \
       target="/usr/local/bin/$(basename "$file")"; \
       tmp=$(mktemp -t "${tool}XXXXX.tgz"); \
       curl -sSLf "$url" -o "$tmp"; \
       [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
       tar xzfO "$tmp" "$file" >"$target"; chmod 755 "$target"; \
       rm -f "$tmp"; \
    }; \
    tool_install() { \
      tool="$1"; version="$2"; sha="$3"; \
      # install "${tool}-${version}/${tool}" \
      #  "https://tools.ietf.org/tools/${tool}/${tool}-${version}.tgz" \
      #  "$sha" "${tool}-${version}/${tool}"; \
    }; \
    tool_install idnits 2.16.05 \
      9f30827e0cf7cf02245e248266ece9557886d33ec7a90cc704b450e70f2cead5; \
    tool_install rfcdiff 1.48 \
      80c886e76803b889c444cd44781f8fa34cb23943a28f18cac0ea8a1458dca265; \
    mmark="2.2.10"; \
    install mmark \
      "https://github.com/mmarkdown/mmark/releases/download/v${mmark}/mmark_${mmark}_linux_amd64.tgz" \
      54ce59da52c59bcc810132ef395f523beeb46bdf9df9b1e3f9be882860934cff; \
    npm install -g aasvg; \
    pip3 install --compile --no-cache-dir \
      archive-repo \
      pyang \
      svgcheck \
      xml2rfc \
      ; \
   gem install --no-doc \
      kramdown-rfc2629 \
      net-http-persistent \
      ; \
    certified-update; \
    mkdir -p $KRAMDOWN_REFCACHEDIR; \
    kramdown-rfc-cache-subseries-bibxml || echo 'rfc-editor.org is down again'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
