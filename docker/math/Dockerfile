ARG REGISTRY=ghcr.io
ARG VERSION=latest
FROM ${REGISTRY}/martinthomson/i-d-template-action:${VERSION}

RUN set -e; \
    apk add --no-cache --virtual .locale_build cmake musl-dev gcc gettext-dev bmake autoconf automake libtool; \
    tmp=$(mktemp -d /tmp/utftex-XXXXX); \
    git clone --depth=1 https://github.com/bartp5/libtexprintf "$tmp"; \
    cd "$tmp"; \
    ./autogen.sh; \
    ./configure; \
    make install; \
    cd /; \
    rm -rf "$tmp"; \
    tmp=$(mktemp -d /tmp/kgt-XXXXX); \
    git clone --recursive https://github.com/katef/kgt.git "$tmp"; \
    cd "$tmp"; \
    bmake -r install; \
    cd /; \
    rm -rf "$tmp"; \
    apk del .locale_build

RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    yarn && \
    npm install -g cabo/mathjax-node-cli
