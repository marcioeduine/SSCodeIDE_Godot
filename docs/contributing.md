# Contributing

## Language

- Code, comments, tests, commit messages, README, and `docs/`: British English (en-GB).
- Identifiers stay ASCII English (`get_nvidia_api_key`, not localised names).

## Secrets

- Never commit API keys, `.env`, or tokens.
- Keep `.gitignore` entries for `.env` and `*.env` with `!.env.example`.
- If a secret is pushed, revoke it and treat Git history as compromised until rewritten.

## Changes

- Keep diffs scoped to the request.
- Match existing GDScript style (typed signatures, tabs).
- Add or update GUT tests when behaviour changes (especially credential lookup).
- Do not vendor exploit payloads or live credentials in fixtures.

## Git

Prefer Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`).

Remote (canonical): `git@github.com:marcioeduine/ss_code_ide_godot.git`.

If history was rewritten to remove a leaked key, collaborators must re-clone or hard-reset to the new `main`; a normal pull will not reconcile rewritten hashes.
