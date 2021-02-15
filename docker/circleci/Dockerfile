ARG REGISTRY=ghcr.io
ARG VERSION=latest
FROM ${REGISTRY}/martinthomson/i-d-template-action:${VERSION}

ENV USER=idci \
    LOGNAME=idci \
    HOSTNAME=idci \
    HOME=/home/idci

RUN apk add --no-cache shadow && useradd -d "$HOME" -s "$SHELL" -m "$USER"
WORKDIR $HOME
USER $USER

ENV KRAMDOWN_REFCACHEDIR=$HOME/.cache/xml2rfc
RUN mkdir -p $KRAMDOWN_REFCACHEDIR

RUN mkdir -p $HOME/.ssh && \
    echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' >> ~/.ssh/known_hosts

RUN GIT_REFERENCE=$HOME/git-reference; \
    git init -q $GIT_REFERENCE; \
    git -C $GIT_REFERENCE remote add i-d-template https://github.com/martinthomson/i-d-template; \
    git -C $GIT_REFERENCE remote add rfc2629xslt https://github.com/reschke/xml2rfc; \
    git -C $GIT_REFERENCE fetch --all

# Unset the entrypoint from the base image
ENTRYPOINT []
