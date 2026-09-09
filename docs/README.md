# SSCodeIDE documentation

Technical documentation for **SSCodeIDE**, a lightweight IDE written in native GDScript for **Godot Engine 4.x**.

## Contents

| Document | Topic |
| :--- | :--- |
| [architecture.md](architecture.md) | Modular controller layout, lazy node instantiation, theme caching, and data flow |
| [user-guide.md](user-guide.md) | Editor usage, shortcuts, Git, and AI chat |
| [development.md](development.md) | Local setup and export |
| [credentials-and-export.md](credentials-and-export.md) | First-use prompt, stored key, optional env / `.env` |
| [contributing.md](contributing.md) | Language rules, secrets, and pull-request hygiene |

## Repository map

| Path | Role |
| :--- | :--- |
| `project.godot` | Godot 4.7 project; main scene `res://scene/welcome.tscn` |
| `scripts/ui_editor.gd` | Shell orchestrator: tabs, menus, explorer, chat, shortcuts |
| `scripts/editor_chat_controller.gd` | Modular AI assistant controller, reasoning tokens, stream polling & markdown rendering |
| `scripts/editor_file_manager.gd` | Multi-tab editor controller, workspace file tree, search & replace operations |
| `scripts/editor_git_controller.gd` | Git & GitHub operations controller, status, smart commits, push/pull/sync, logs & diffs |
| `scripts/editor_theme_manager.gd` | Dark/Light mode theme controller, Kitty/Fish highlighters & XML theme importer |
| `scripts/editor_sidebar_builder.gd` | On-demand lazy sidebar panel builder (Search, Git, Themes, Config, Help) |
| `scripts/editor_dialog_controller.gd` | On-demand lazy modal overlay dialog & toast notification controller |
| `scripts/editor_input_handler.gd` | Global shortcut router, ESC focus release & CodeEdit key event interceptor |
| `scripts/theme_color_scheme.gd` | Dark and Light mode palettes |
| `scripts/theme_controller.gd` | Theme loading, application, config persistence, and palette table |
| `scripts/theme_resource_registry.gd` | Theme resource manager with cache reuse (`CACHE_MODE_REUSE`) |
| `scripts/file_kind.gd` | Workspace icon mapping with Lanczos 14px tab icon scaling |
| `scripts/ai_service.gd` | NVIDIA NIM HTTP client, candidate fallback logic, credential loader |
| `scripts/git_service.gd` | Git / GitHub CLI wrapper |
| `scripts/web_search_service.gd` | Real-time Internet search and documentation retrieval service |
| `scripts/agent_workspace_service.gd` | Agent Mode workspace file mutation service |
| `scripts/file_controller.gd` | File explorer and buffer management |
| `scene/ui_editor.tscn` | Lightweight main editor scene hierarchy |
| `scene/welcome.tscn` | Instant asynchronous welcome loader scene |
| `themes/` | `dark.theme`, `light.theme`, and `example_theme.xml` import template |
| `screenshots/` | UI screenshots for documentation and README |

## Quick start

1. Open this folder in Godot 4.7 or later.
2. Run the main scene (`res://scene/welcome.tscn` or `res://scene/ui_editor.tscn`).
3. Paste the NVIDIA NIM key when Chat or Smart Commit first asks (or use `.env` / the process environment).

See [development.md](development.md) and [credentials-and-export.md](credentials-and-export.md).
