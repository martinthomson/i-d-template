ARG REGISTRY=ghcr.io
ARG VERSION=latest
FROM ${REGISTRY}/martinthomson/i-d-template-action:${VERSION}

RUN set -e; \
    apk add --no-cache --virtual .locale_build cmake musl-dev gcc gettext-dev; \
    tmp=$(mktemp -d /tmp/asciitex-XXXXX); \
    git clone --depth=1 https://github.com/larseggert/asciiTeX "$tmp"; \
    cd "$tmp"; \
    cmake -DCMAKE_BUILD_TYPE=Release -DDISABLE_TESTING=On -DCMAKE_INSTALL_PREFIX:PATH=/usr .; \
    make install; \
    cd /; \
    rm -rf "$tmp"; \
    apk del .locale_build

RUN apk add npm && npm install -g mathjax-node-cli
