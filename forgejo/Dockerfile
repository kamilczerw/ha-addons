# ==============================================================================
# Home Assistant Add-on Dockerfile for Forgejo
# Wraps the upstream Forgejo image unchanged; the only addition is an
# entrypoint shim that points Forgejo's ROOT_URL at this add-on's own
# Ingress path before handing off to the image's real startup sequence.
# See rootfs/set-ingress-root-url.sh for why this is needed.
# ==============================================================================

ARG BUILD_FROM=codeberg.org/forgejo/forgejo:16.0.2
FROM ${BUILD_FROM}

# curl+jq: only needed to query the Supervisor API for our own Ingress path.
RUN apk add --no-cache curl jq

COPY forgejo/rootfs/set-ingress-root-url.sh /set-ingress-root-url.sh
RUN chmod +x /set-ingress-root-url.sh

# CMD is inherited unchanged from the base image (s6-svscan). We only
# override ENTRYPOINT so our shim can run first and exec into the base
# image's own entrypoint (/usr/bin/entrypoint) afterwards.
ENTRYPOINT ["/set-ingress-root-url.sh"]
