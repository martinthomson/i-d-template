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
      musl-locales \
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
      py3-toml \
      py3-wheel \
      py3-yaml \
      python3 \
      ruby \
      ruby-bundler \
      sed

ENV SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    KRAMDOWN_PERSISTENT=t \
    PIP_BREAK_SYSTEM_PACKAGES=true

COPY ["entrypoint.sh", "requirements.txt", "Gemfile", "/i-d-template/"]
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
      curl -SSLf -o "/usr/local/bin/${tool}" \
        "https://raw.githubusercontent.com/ietf-tools/${tool}-mirror/${version}/${tool}"; \
      [ $(sha256sum -b "/usr/local/bin/${tool}" | cut -d ' ' -f 1 -) = "$sha" ]; \
    }; \
    set -x; \
    tool_install idnits bfda9518d5b4e8a682f2e6f34a449c2d3ea74539 \
      0ea07cdc982645a85622ccc2636a4d21cde54137269f0e8a204e1bc519b48818; \
    mmark="2.2.40"; \
    install mmark \
      "https://github.com/mmarkdown/mmark/releases/download/v${mmark}/mmark_${mmark}_linux_amd64.tgz" \
      720f8cccd5c38a2a333d0a6af4146df1dd798f4cfcb5e83419fc518348bdf7ad; \
    npm install -g aasvg; \
    pip3 install --no-cache-dir --disable-pip-version-check \
      -r /i-d-template/requirements.txt; \
    bundle install --system --gemfile=/i-d-template/Gemfile

ENTRYPOINT ["/i-d-template/entrypoint.sh"]
