# Architecture

SSCodeIDE is a single-window Godot application. There is no separate language server or Electron shell: the editor, file tree, Git, and AI chat run inside one Godot process.

## Runtime

- **Engine:** Godot 4.x (`config/features` includes `4.7`).
- **Language:** GDScript only for application code.
- **Entry:** `run/main_scene` = `res://scene/ui_editor.tscn`.
- **Viewport:** 1600×900, maximised, `canvas_items` stretch with `expand` aspect.

## Layers

```
ui_editor.tscn  →  ui_editor.gd (primary orchestrator)
                      ├── AppBrandButton         (brand menu button with Light/Dark/About/Close)
                      ├── ThemeController        (palette selection, persistence, XML import)
                      ├── ThemeColorScheme       (colour palettes: 9 dark, 7 light variants)
                      ├── ThemeResourceRegistry  (builds & compiles .theme resources)
                      ├── FileController         (file tree and buffer management)
                      ├── FileKind               (icons / extension map)
                      ├── GitService             (OS.execute git)
                      ├── AIService              (HTTPRequest → NVIDIA NIM)
                      ├── CodeEditorTools        (code completion & editor utilities)
                      ├── ChatMarkdownRenderer   (chat markdown & GFM table rendering)
                      └── MarkdownPreviewRenderer(markdown document preview rendering)
```

### `ui_editor.gd`

Owns:

- Multi-tab `CodeEdit` buffers and dirty state
- Workspace `Tree` (`FileTree`)
- Top navigation bar with `AppBrand` (`SS` button) and `MenuBar` (File, Edit, Git, Config, Themes, Help)
- Status bar (branch indicator, dirty count, language, cursor position, AI status)
- AI side panel (input, markdown preview, slash commands)
- Keyboard routing (`_unhandled_input`)
- Theme orchestration delegating to `ThemeController`, `ThemeColorScheme`, and `ThemeResourceRegistry`

It never embeds an API key. Chat and Smart Commit call `AIService.get_nvidia_api_key()` and send `Authorization: Bearer …`.

### `ai_service.gd` (`class_name AIService`)

- Endpoint: `https://integrate.api.nvidia.com/v1/chat/completions`
- Env name: `NVIDIA_NIM_API_KEY`
- Cached key: static `_cached_api_key`
- Lookup: process environment, then `user://ai_secrets.cfg`, then `.env` candidates (see [credentials-and-export.md](credentials-and-export.md))
- Persist: `set_stored_nvidia_api_key()`; UI prompt on first Chat / Smart Commit
- Provider keys: `nemotron`, `nemotron_lightning`, `kimi_k3`, `deepseek_v4`, `laguna`
- Fallback arrays per provider for transient HTTP failures

### `git_service.gd`

Wraps the system `git` binary (`OS.execute`). Used for status, diff, log, commit, push, pull, fetch, sync, branch, checkout, remote, config, clone, and GitHub URL parsing.

### `file_kind.gd`

Maps extensions (`.gd`, `.py`, `.js`, `.ts`, `.cpp`, `.rs`, `.go`, `.tscn`, `.json`, images, audio, archives, …) to SVG icons in `icons/`.

## Packed resources vs host files

After export, `res://` is the `.pck`. A project-root `.env` is **not** inside the pack unless you explicitly include it (do not). Credentials must come from:

1. The process environment, or
2. A sidecar `.env` next to the executable (or next to the `.app` on macOS), or
3. `user://.env` in Godot’s user data directory.

## Tests

GUT scripts under `test/unit/` cover `AIService` (including env preference), `FileKind`, `GitService`, and script-level checks on `ui_editor.gd`.
