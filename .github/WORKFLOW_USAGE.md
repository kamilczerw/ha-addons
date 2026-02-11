# Addon Version Update Workflow

This document explains how to use the `update-addon-version.yml` workflow to automatically update addon versions in this repository.

## Overview

The workflow can be triggered in two ways:
1. **Manually** via workflow_dispatch (useful for testing)
2. **Automatically** via repository_dispatch from the source addon repository

## Triggering from Source Repository

To trigger this workflow from your addon's source repository (e.g., `kamilczerw/otter`), add the following step to your release workflow:

### Example: Trigger from Source Repo

Add this to your source repository's release workflow (e.g., `.github/workflows/release.yml`):

```yaml
- name: Trigger HA Addon Update
  if: github.event_name == 'release'
  run: |
    curl -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token ${{ secrets.HA_ADDONS_TRIGGER_TOKEN }}" \
      https://api.github.com/repos/kamilczerw/ha-addons/dispatches \
      -d '{
        "event_type": "update-addon-version",
        "client_payload": {
          "addon_name": "otter",
          "source_repo": "kamilczerw/otter"
        }
      }'
```

### Setup Requirements

1. **Create a Personal Access Token (PAT)**:
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate a new token with `repo` scope
   - Copy the token

2. **Add Secret to Source Repository**:
   - Go to your source repo (e.g., `kamilczerw/otter`)
   - Settings → Secrets and variables → Actions
   - Add a new repository secret named `HA_ADDONS_TRIGGER_TOKEN`
   - Paste your PAT as the value

## Manual Trigger (for testing)

You can also manually trigger the workflow:

1. Go to the Actions tab in this repository
2. Select "Update Addon Version" workflow
3. Click "Run workflow"
4. Enter:
   - **addon_name**: The directory name (e.g., `otter`)
   - **source_repo**: The source repository (e.g., `kamilczerw/otter`)

## What the Workflow Does

1. ✅ Fetches the latest release from the source repository
2. ✅ Checks the current version in `<addon-name>/config.yaml`
3. ✅ If versions differ:
   - Updates the `version` field in `config.yaml`
   - Prepends the release notes to `CHANGELOG.md`
   - Commits and pushes the changes
4. ✅ If versions match, exits without making changes

## Workflow Outputs

The workflow provides a summary at the end:
- If updated: Shows old and new version
- If already up-to-date: Confirms no action was needed

## File Structure

The workflow expects this structure:
```
repository-root/
├── <addon-name>/
│   ├── config.yaml          # Version field will be updated
│   ├── CHANGELOG.md         # Release notes will be prepended
│   ├── Dockerfile
│   └── ...
└── .github/
    └── workflows/
        └── update-addon-version.yml
```

## Example config.yaml

```yaml
name: Otter Budget Tracker
version: "1.0.2"  # This line will be updated
slug: otter
# ... rest of config
```

## Example CHANGELOG.md Format

The workflow will maintain this format:

```markdown
# Changelog

## 1.0.3

- New feature added
- Bug fix

## 1.0.2

- Previous release notes
- ...
```
