# Build Addon Images Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On push to `main`, automatically build and push to `ghcr.io` the Docker image for any addon whose files changed in that push — but only for addons flagged as safe to build in this repo, skipping addons (like `otter`) whose image is built externally.

**Architecture:** `nix/config.nix` gains a `buildInRepo` boolean per addon (single source of truth, already consumed by Nix package/build tooling). `flake.nix` exposes a `buildableAddons` output projecting that list to `{name, relPath, image}`. A new two-job GitHub Actions workflow: `plan` (installs Nix, reads `buildableAddons`, diffs the push against its `before` SHA, intersects the two lists into a JSON matrix) → `build` (matrix job per changed+buildable addon; reuses the existing `nix run .#build-<name>-docker` recipe instead of re-deriving the `docker build` invocation, tags `:<version>` + `:latest`, pushes to GHCR).

**Tech Stack:** Nix flakes (existing), GitHub Actions, Docker, `jq`.

**Context:** No CI in this repo currently builds/pushes Docker images. `otter`'s Dockerfile `COPY`s `frontend/`/`backend/` source that is intentionally not vendored here (its image is built and pushed by the separate `kamilczerw/otter` source repo on release; this repo only tracks its version pointer). `forgejo`'s Dockerfile is self-contained and was confirmed (via a dedicated investigation, see below) to genuinely need a custom-built image — its `ENTRYPOINT` runs `set-ingress-root-url.sh`, which resolves Home Assistant's dynamic, per-install Ingress token path via the Supervisor API and injects it as Forgejo's `ROOT_URL` before Forgejo starts. That's what makes the Ingress sidebar work with correct asset/CSS links, and it cannot be done via `config.yaml` options/environment alone or by pointing `image:` straight at the upstream `codeberg.org/forgejo/forgejo` image, since (a) the Ingress path is assigned at runtime per install, not a static value, and (b) Home Assistant's external-image-only addon shape has no hook to override `ENTRYPOINT`/run a pre-start command.

---

### Task 1: Flag which addons are safe to build in this repo

**Files:**
- Modify: `nix/config.nix`

- [ ] **Step 1: Add `buildInRepo` to each addon entry**

Replace the file contents with:

```nix
{ lib }:
{
  # Register Home Assistant add-ons here. Keep relPath stable because it is used
  # by Nix package names, validation checks, and local Docker build helpers.
  #
  # buildInRepo: true when the Dockerfile's build context is fully self-contained
  # in this repo (CI may build/push it here); false when the image is built and
  # pushed by an external source repo and this repo only tracks its version.
  addons = [
    {
      name = "otter";
      relPath = "otter";
      path = ../otter;
      image = "ghcr.io/kamilczerw/otter";
      supportedArchitectures = [ "amd64" ];
      buildInRepo = false;
    }
    {
      name = "forgejo";
      relPath = "forgejo";
      path = ../forgejo;
      image = "ghcr.io/kamilczerw/forgejo";
      supportedArchitectures = [ "amd64" ];
      buildInRepo = true;
    }
  ];
}
```

- [ ] **Step 2: Verify it still evaluates**

Run: `nix flake check`
Expected: passes (same as before — this only adds a field, doesn't remove any consumed by existing checks/packages).

- [ ] **Step 3: Commit**

```bash
git add nix/config.nix
git commit -m "nix: flag which addons are safe to build in this repo"
```

---

### Task 2: Expose the buildable-addon list as a flake output

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Add `buildableAddons` to the returned attrset**

In `flake.nix`, change:

```nix
      {
        inherit packages checks devShells;
      }
```

to:

```nix
      {
        inherit packages checks devShells;
        buildableAddons = map (a: { inherit (a) name relPath image; }) (
          builtins.filter (a: a.buildInRepo) config.addons
        );
      }
```

- [ ] **Step 2: Verify the output**

Run: `nix eval --json .#buildableAddons.x86_64-linux`
Expected: `[{"image":"ghcr.io/kamilczerw/forgejo","name":"forgejo","relPath":"forgejo"}]`

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "nix: expose buildable-addon list as a flake output"
```

---

### Task 3: Document the new field for future addons

**Files:**
- Modify: `.agents/skills/new-addon.md:47-55`

- [ ] **Step 1: Update the registration snippet**

Replace:

```nix
{
  name = "<slug>";
  relPath = "<slug>";
  path = ../<slug>;
  image = "ghcr.io/kamilczerw/<slug>";
  supportedArchitectures = [ "amd64" ];
}
```

with:

```nix
{
  name = "<slug>";
  relPath = "<slug>";
  path = ../<slug>;
  image = "ghcr.io/kamilczerw/<slug>";
  supportedArchitectures = [ "amd64" ];
  buildInRepo = true; # false if the Dockerfile needs source not vendored in this repo
}
```

- [ ] **Step 2: Commit**

```bash
git add .agents/skills/new-addon.md
git commit -m "docs: document buildInRepo in addon registration"
```

---

### Task 4: Add the build-on-push workflow

**Files:**
- Create: `.github/workflows/build-addon-images.yaml`

- [ ] **Step 1: Write the workflow**

```yaml
name: Build Addon Images

on:
  push:
    branches: [main]

permissions:
  contents: read
  packages: write

jobs:
  plan:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.filter.outputs.matrix }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@main

      - name: Compute buildable + changed addons
        id: filter
        run: |
          set -euo pipefail

          BUILDABLE=$(nix eval --json .#buildableAddons.x86_64-linux)

          BEFORE="${{ github.event.before }}"
          ZERO_SHA="0000000000000000000000000000000000000000"
          if [ "$BEFORE" = "$ZERO_SHA" ]; then
            # New branch/history edge case: fail safe and consider everything changed
            # rather than silently building nothing.
            FAILSAFE=true
            CHANGED_FILES=""
          else
            FAILSAFE=false
            CHANGED_FILES=$(git diff --name-only "$BEFORE" "${{ github.sha }}")
          fi

          MATRIX=$(jq -nc \
            --argjson buildable "$BUILDABLE" \
            --arg failsafe "$FAILSAFE" \
            --arg changed "$CHANGED_FILES" '
              ($changed | split("\n")) as $files
              | $buildable
              | map(select(
                  ($failsafe == "true")
                  or (any($files[]; startswith(.relPath + "/")))
                ))
            ')

          echo "matrix=$MATRIX" >> "$GITHUB_OUTPUT"
          echo "Buildable addons: $BUILDABLE"
          echo "Changed+buildable matrix: $MATRIX"

  build:
    needs: plan
    if: needs.plan.outputs.matrix != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        addon: ${{ fromJson(needs.plan.outputs.matrix) }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@main

      - name: Read addon version
        id: version
        run: |
          set -euo pipefail
          VERSION=$(grep '^version:' "${{ matrix.addon.relPath }}/config.yaml" | sed 's/version: *"\(.*\)"/\1/')
          echo "version=${VERSION}" >> "$GITHUB_OUTPUT"

      - name: Build image
        run: |
          set -euo pipefail
          nix run ".#build-${{ matrix.addon.name }}-docker" -- "${{ matrix.addon.image }}:${{ steps.version.outputs.version }}"
          docker tag "${{ matrix.addon.image }}:${{ steps.version.outputs.version }}" "${{ matrix.addon.image }}:latest"

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push image
        run: |
          set -euo pipefail
          docker push "${{ matrix.addon.image }}:${{ steps.version.outputs.version }}"
          docker push "${{ matrix.addon.image }}:latest"
```

- [ ] **Step 2: Validate the YAML and the jq filter locally**

Run:
```bash
python - <<'PY'
import yaml
yaml.safe_load(open(".github/workflows/build-addon-images.yaml"))
print("YAML OK")
PY

echo '[{"name":"forgejo","relPath":"forgejo","image":"ghcr.io/kamilczerw/forgejo"},{"name":"otter","relPath":"otter","image":"ghcr.io/kamilczerw/otter"}]' > /tmp/buildable.json
jq -nc --argjson buildable "$(cat /tmp/buildable.json)" --arg failsafe "false" --arg changed $'forgejo/config.yaml\nforgejo/CHANGELOG.md' '
  ($changed | split("\n")) as $files
  | $buildable
  | map(. as $addon | select(($failsafe == "true") or (any($files[]; startswith($addon.relPath + "/")))))
'
```
Expected: YAML parses OK, and the jq filter outputs only the `forgejo` entry (confirms an `otter`-only change would filter to `[]`).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build-addon-images.yaml
git commit -m "ci: build and push addon images on push to main"
```

---

### Task 5: End-to-end verification

- [ ] **Step 1: Confirm the reused Docker build recipe still works standalone**

Run: `nix run .#build-forgejo-docker -- ghcr.io/kamilczerw/forgejo:local-test`
Expected: image builds successfully (this is the exact command the `build` job runs in CI).

- [ ] **Step 2: Confirm otter is excluded**

Run: `nix eval --json .#buildableAddons.x86_64-linux | jq 'map(.name)'`
Expected: `["forgejo"]` — `otter` must not appear.

- [ ] **Step 3: Push a real no-op change under `forgejo/` on a test branch, temporarily retarget the workflow's `branches:` to that branch, push, and watch GitHub Actions**

Expected: `plan` job matrix contains exactly the `forgejo` entry; `build` job builds and pushes `ghcr.io/kamilczerw/forgejo:16.0.2` and `:latest`. Revert the temporary branch retarget before merging to `main`.

- [ ] **Step 4: Push a change touching only `otter/` on the same test branch**

Expected: `plan` job computes an empty matrix (`[]`); `build` job is skipped (shows as skipped, not failed, in the Actions UI).

---

## Skipped (say so if you want it)

- Multi-arch builds (`buildx`/QEMU) — both addons only declare `amd64` today. Add when an addon's `supportedArchitectures` grows beyond `amd64`.
- `workflow_dispatch` manual re-run trigger — push-triggered only for now. Add an optional `addon` input if you want to force a rebuild without a code change.
- Build layer caching — plain `docker build` (via the Nix script) each run. Add `cache-from`/registry cache if build times become a problem.
- GHCR package visibility — first push creates the package under the token owner, likely private by default. That's a one-time manual toggle in GitHub package settings, not something CI should do.
