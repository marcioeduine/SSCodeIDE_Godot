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
| `scripts/ui_editor.gd` | Shell orchestrator: tabs, menus, explorer, chat, shortcuts |
| `scripts/theme_controller.gd` | Theme application, persistence, and XML import controller |
| `scripts/theme_color_scheme.gd` | Centralised color schemes (JetBrains / VS Code palettes) |
| `scripts/theme_resource_registry.gd` | Compiles dynamic `.theme` binary resources |
| `scripts/app_brand_button.gd` | AppBrand menu button (Dark/Light toggle, About, Close) |
| `scripts/file_controller.gd` | File tree inspection and buffer handling |
| `scripts/ai_service.gd` | NVIDIA NIM HTTP client, models, credential loader |
| `scripts/git_service.gd` | Git / GitHub CLI wrapper |
| `scripts/file_kind.gd` | Workspace icon mapping by extension |
| `scene/ui_editor.tscn` | Editor UI scene hierarchy |
| `themes/` | Binary `.theme` resources and XML theme templates |
| `test/unit/` | GUT unit tests |
| `addons/gut/` | Godot Unit Test framework |
| `addons/at-icons/` | Icon set used by the file tree |
| `.env.example` | Template for `NVIDIA_NIM_API_KEY` (never commit `.env`) |

## Quick start

1. Open this folder in Godot 4.7 or later.
2. Run the main scene `scene/ui_editor.tscn`. Paste the NVIDIA NIM key when Chat or Smart Commit first asks (or use `.env` / the process environment).

See [development.md](development.md) and [credentials-and-export.md](credentials-and-export.md).
