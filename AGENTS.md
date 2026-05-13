# Agent entrypoint

This repository contains Home Assistant add-ons. Keep this file short so agents can load only the context they need.

## Read first

1. [Repository overview](.agents/repository.md) - repo layout, ownership boundaries, and key files.
2. [Working agreement](.agents/working-agreement.md) - how agents should plan, edit, validate, and communicate.

## Task-specific guides

- [Home Assistant add-on guide](.agents/home-assistant-addons.md) - add-on manifests, Docker images, s6 services, translations, releases.
- [New Addon skill](.agents/skills/new-addon.md) - reusable process and boilerplate checklist for adding another add-on.
- [Validation checklist](.agents/validation.md) - checks to run before reporting completion.

## Context-loading rule

Start with this file and `.agents/repository.md`. Load task-specific files only when they are relevant to the requested change.
