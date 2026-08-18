#!/bin/sh
# ==============================================================================
# Entrypoint shim: point Forgejo's ROOT_URL at this add-on's Ingress path.
#
# Why this exists
# ----------------
# Home Assistant's Ingress reverse proxy forwards browser requests to this
# container with the per-add-on token path (e.g. /api/hassio_ingress/<token>)
# stripped off, so from the container's point of view every request looks
# like a normal request to "/". But Forgejo is not Ingress-aware: it does not
# read any "here's your path prefix" header per request. Instead, like
# upstream Gitea, it bakes one static ROOT_URL into every link, redirect,
# and asset path it generates and serves that back to the browser as-is.
#
# The browser, however, IS sitting on the token-prefixed URL. If Forgejo's
# ROOT_URL doesn't include that prefix, every asset/link Forgejo hands back
# resolves to the wrong place in the browser and Ingress access breaks (404s
# on CSS/JS, broken redirects, etc.) — even though the proxy itself is
# working correctly.
#
# The fix: before Forgejo starts, ask Supervisor's own API "what is my
# Ingress path?" and set GITEA__server__ROOT_URL to that path. Forgejo reads
# config from GITEA__<section>__<KEY> environment variables on every start,
# so this is enough — no app.ini editing required.
#
# Known tradeoff (not fixable from inside this script): once ROOT_URL is
# pinned to the Ingress path, browsing Forgejo directly via its published
# port (bypassing Ingress) may show broken asset links, because that access
# path does NOT have the token prefix Forgejo now expects. Actual git
# clone/push over that direct port keeps working regardless, since Git's
# smart-HTTP endpoints don't depend on ROOT_URL-driven asset links, and SSH
# clone is unaffected entirely (no HTTP/ROOT_URL involved). See DOCS.md.
#
# Fails safe: if SUPERVISOR_TOKEN isn't set, or the Supervisor API call
# fails or returns nothing useful (e.g. running this image standalone with
# plain `docker run`, outside Home Assistant), we simply skip setting
# ROOT_URL and fall through to Forgejo's normal auto-detected default. The
# add-on must start successfully either way — this script only ever adds an
# env var, it never blocks or fails startup.
# ==============================================================================
set -eu

if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
  # "self" is a special add-on slug Supervisor resolves to "whichever add-on
  # is making this request", based on the SUPERVISOR_TOKEN presented.
  ingress_entry="$(curl -sf -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    http://supervisor/apps/self/info 2>/dev/null |
    jq -r '.data.ingress_entry // empty' 2>/dev/null || true)"

  if [ -n "${ingress_entry:-}" ]; then
    export GITEA__server__ROOT_URL="${ingress_entry}/"
  fi
fi

# Hand off to the image's real, unmodified startup sequence.
exec /usr/bin/entrypoint "$@"
