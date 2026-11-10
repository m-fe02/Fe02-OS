ARG FEDORA_MAJOR_VERSION
ARG BASE_IMAGE_NAME

FROM scratch AS ctx
COPY files /
COPY cosign.pub /

FROM ${BASE_IMAGE_NAME}:${FEDORA_MAJOR_VERSION}

ARG DESKTOP_ENV
ARG GAMING=false

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    bash /ctx/scripts/00-setup.sh
