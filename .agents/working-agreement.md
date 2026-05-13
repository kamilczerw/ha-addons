# Working agreement for coding agents

## Default workflow

1. Read `AGENTS.md`, then `.agents/repository.md`.
2. Identify the add-on or repository-level files affected by the request.
3. Make the smallest maintainable change that solves the problem.
4. Update related metadata, docs, translations, and changelog when behavior or user-visible configuration changes.
5. Validate the change using `.agents/validation.md`.
6. Summarize what changed, what was validated, and any follow-up risks.

## Keep context small

- Load only the detailed guide needed for the task.
- Prefer targeted file reads over loading entire directories.
- When adding new guidance, keep `AGENTS.md` as an index and put details in `.agents/*.md`.

## Editing principles

- Preserve Home Assistant add-on conventions and schema compatibility.
- Keep configuration defaults explicit and documented.
- Avoid changing persistent storage paths unless the task explicitly requires migration work.
- Avoid changing add-on slugs, image names, ingress ports, or option names casually because users may already depend on them.
- Keep comments useful and up to date. Remove misleading comments rather than adding contradictory ones.

## Communication

- State assumptions when the repository does not contain enough context.
- Call out changes that require external release steps, image publishing, or Home Assistant repository refreshes.
- Do not claim runtime validation unless it was actually performed.

## Git hygiene

- Check the working tree before committing.
- Commit only files changed for the task.
- Use clear commit messages, for example `docs: add agent guidance` or `otter: update add-on metadata`.
