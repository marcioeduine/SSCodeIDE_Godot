# SSCodeIDE documentation

Technical documentation for **SSCodeIDE**, a lightweight IDE written in native GDScript for **Godot Engine 4.x**.

## Contents

| Document | Topic |
| :--- | :--- |
| [architecture.md](architecture.md) | Layout, scripts, scenes, and data flow |
| [user-guide.md](user-guide.md) | Editor usage, shortcuts, Git, and AI chat |
| [development.md](development.md) | Local setup, tests, and export |
| [credentials-and-export.md](credentials-and-export.md) | First-use prompt, stored key, optional env / `.env` |
| [contributing.md](contributing.md) | Language rules, secrets, and pull-request hygiene |

## Repository map

| Path | Role |
| :--- | :--- |
| `project.godot` | Godot 4.7 project; main scene `res://scene/ui_editor.tscn` |
| `scripts/ui_editor.gd` | Shell: tabs, menus, explorer, chat, shortcuts |
| `scripts/ai_service.gd` | NVIDIA NIM HTTP client, models, credential loader |
| `scripts/git_service.gd` | Git / GitHub CLI wrapper |
| `scripts/file_kind.gd` | Workspace icon mapping by extension |
| `scene/ui_editor.tscn` | Editor UI scene |
| `test/unit/` | GUT unit tests |
| `addons/gut/` | Godot Unit Test |
| `addons/at-icons/` | Icon set used by the file tree |
| `.env.example` | Template for `NVIDIA_NIM_API_KEY` (never commit `.env`) |

## Quick start

1. Open this folder in Godot 4.7 or later.
2. Run the main scene `scene/ui_editor.tscn`. Paste the NVIDIA NIM key when Chat or Smart Commit first asks (or use `.env` / the process environment).

See [development.md](development.md) and [credentials-and-export.md](credentials-and-export.md).
