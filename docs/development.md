# Development

## Prerequisites

- Godot 4.7 or compatible 4.x editor
- Git
- Optional: NVIDIA NIM API key for chat and Smart Commit

## Open the project

Open the directory that contains `project.godot`. Run `scene/welcome.tscn` (or `scene/ui_editor.tscn`).

## Layout conventions

- Scripts: `scripts/*.gd` — British English identifiers and comments
- Scenes: `scene/*.tscn`
- Docs: `docs/*.md` (British English)
- Secrets: never in source; the editor stores the key in `user://ai_secrets.cfg`. Optional: `.env` (gitignored) or the OS environment

## Credentials in the editor

Run the editor and send a chat message (or Smart Commit). Paste the NVIDIA NIM key when prompted. It is stored in `user://ai_secrets.cfg`.

Optional for CI — copy `.env.example` to `.env` next to `project.godot`, or set `NVIDIA_NIM_API_KEY` in the process environment. A `.desktop` Applications-menu launch does not inherit a shell `export`; the in-app prompt is the intended path.

## Export

1. Project → Export (Linux, Windows, macOS).
2. Do **not** pack `.env` into the PCK.
3. Place a sidecar `.env` as described in [credentials-and-export.md](credentials-and-export.md).

## Language policy

- Source, README, and `docs/`: **en-GB** technical English.
- User-facing assistant replies outside the repo may use European Portuguese (pre-2012 orthography); that does not apply to committed files.
