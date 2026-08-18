# Forgejo

A self-hosted, lightweight Git forge (Forgejo, a Gitea fork), wrapped as a Home Assistant add-on. This add-on ships no configuration options — you configure Forgejo itself through its own first-run web install wizard.

## Getting started

1. Start the add-on.
2. Open it from the Home Assistant sidebar (Ingress). You'll land on Forgejo's first-run install wizard automatically — no manual setup is required to get there.
3. Complete the wizard to create the initial admin account. All settings from that point on are managed inside Forgejo itself, the same as any standalone Forgejo instance.

## Access methods

This add-on exposes Forgejo three ways, because Home Assistant's Ingress only proxies authenticated browser sessions — it can't carry raw `git` protocol traffic:

| Method | Use for | Notes |
| --- | --- | --- |
| Sidebar / Ingress | Browsing the web UI, the install wizard | Recommended for everyday web UI use. |
| Direct port `3000` | `git clone`/`push` over HTTP(S), API access | Web UI browsing through this port directly may show broken asset links — see caveat below. Git operations are unaffected. |
| Direct port `22` (mapped to host `2222` by default) | `git clone`/`push` over SSH | Not affected by anything below; SSH doesn't use ROOT_URL/HTTP routing at all. |

### Why direct-port web browsing may look broken

Forgejo bakes a single fixed "Root URL" into every link and asset path it generates. This add-on points that Root URL at the Ingress path automatically (see `set-ingress-root-url.sh` in the add-on image), so Ingress access works out of the box with no setup. The tradeoff is that this same Root URL is then not correct for the *direct* port — a single value can't describe two different URL shapes at once. If you browse to the direct port's web UI, you may see missing styles or broken links. `git` operations over that same port (clone, push, pull, the HTTP API) are unaffected, since they don't depend on the asset links the Root URL controls.

If you need the direct port's web UI to render correctly too, you can override this by setting Forgejo's Root URL manually in **Site Administration → Configuration** after setup — but doing so will then break Ingress access instead, for the same reason in reverse.

### SSH port

If you remap the SSH host port in the add-on's Network settings away from the default `2222`, also update the SSH port Forgejo displays in its own **Site Administration → Configuration** (or `app.ini`) to match. Otherwise the `git clone`/`push` URLs Forgejo shows you will reference the wrong port.

## Data storage

Forgejo's repositories, database, and SSH host keys are stored under `/data`, Home Assistant's persistent add-on storage. Your data is preserved across add-on restarts and updates.
