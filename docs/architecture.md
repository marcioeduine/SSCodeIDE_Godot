# Architecture

SSCodeIDE is a single-window Godot application. There is no separate language server or Electron shell: the editor, file tree, Git, and AI chat run inside one Godot process.

## Runtime

- **Engine:** Godot 4.x (`config/features` includes `4.7`).
- **Language:** GDScript only for application code.
- **Entry:** `run/main_scene` = `res://scene/welcome.tscn` (or `res://scene/ui_editor.tscn`).
- **Viewport:** 1600×900, maximised, `canvas_items` stretch with `expand` aspect.

## Layers & Modular Architecture

```
ui_editor.tscn  →  ui_editor.gd (primary orchestrator & public state holder)
                      ├── EditorChatController   (AI chat, reasoning tokens, stream polling, BBCode sanitisation)
                      ├── EditorFileManager      (multi-tab buffers, file tree, workspace search & replace)
                      ├── EditorGitController     (Git status, smart commits, push/pull/sync, logs & diffs)
                      ├── EditorThemeManager     (Dark/Light application, Kitty/Fish highlighters, XML import)
                      ├── EditorSidebarBuilder   (Lazy on-demand sidebar panel creation for Search, Git, Themes, Config, Help)
                      ├── EditorDialogController  (Lazy on-demand modal overlay dialogs, input prompts, toasts)
                      ├── EditorInputHandler     (Keyboard shortcuts routing, ESC focus release, CodeEdit input hooks)
                      ├── ThemeController        (theme loading, application, config persistence, palette table)
                      ├── ThemeColorScheme       (Dark and Light mode palettes)
                      ├── ThemeResourceRegistry  (theme resource compiler with CACHE_MODE_REUSE)
                      ├── FileKind               (icon mapping & 14px Lanczos texture scaling)
                      ├── FileController         (file explorer and buffer management)
                      ├── GitService             (OS.execute git)
                      ├── AIService              (HTTPRequest → NVIDIA NIM API)
                      ├── AgentWorkspaceService  (Agent Mode workspace file mutation)
                      ├── WebSearchService       (live web search retrieval & context injection)
                      └── ChatMarkdownRenderer   (chat Markdown & GFM table renderer)
```

### Modular Controller Components

- **`ui_editor.gd`**: Primary orchestrator owning the public UI node references and state variables. Delegates feature execution to dedicated sub-controller instances (`chat`, `files`, `git`, `themes`, `sidebar`, `dialog`, `input_handler`).
- **`editor_sidebar_builder.gd`**: Implements lazy on-demand panel construction (`ensure_search_panel()`, `ensure_git_panel()`, etc.), instantiating secondary UI panels only when their NavRail tabs are clicked.
- **`editor_dialog_controller.gd`**: Implements lazy modal overlay creation (`ensure_overlay_dialog()`), building dialog panels programmatically when needed rather than cluttering the initial Scene Tree.
- **`theme_resource_registry.gd`**: Loads built-in and custom theme resources using `CACHE_MODE_REUSE` by default, eliminating disk I/O re-parsing latency during transition.

### `web_search_service.gd` (`class_name WebSearchService`)

Provides real-time Internet search and documentation lookup capabilities:
- Integrates with search engines and Wikipedia API to retrieve real-time search snippets, URLs, and summaries.
- Formats search results as BBCode for interactive chat display (`/search <query>`, `/web <query>`).
- Generates structured temporal and web context blocks injected into AI prompt payloads for up-to-date responses.

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

### `agent_workspace_service.gd` (`class_name AgentWorkspaceService`)

Provides **Agent Mode** workspace file mutation. Parses `<sscode-write path="...">…</sscode-write>` and `<sscode-delete path="..."/>` markup emitted by the AI in its reply, validates paths against the active workspace root, and safely creates, updates, or deletes files. Paths outside the workspace are silently rejected.

### `file_kind.gd`

Maps extensions (`.gd`, `.py`, `.js`, `.ts`, `.cpp`, `.rs`, `.go`, `.tscn`, `.json`, images, audio, archives, …) to SVG icons in `icons/` and generates scaled 14px Lanczos vector textures for tab bars.

### `theme_controller.gd` (`class_name ThemeController`)

Encapsulates theme loading, application, configuration persistence (`user://ui_config.cfg`), and the built-in palette table. Delegates visual resource construction to `ThemeResourceRegistry`. Exposes `request_theme_change()` and emits `theme_changed` signal.

## Packed resources vs host files

After export, `res://` is the `.pck`. A project-root `.env` is **not** inside the pack unless you explicitly include it (do not). Credentials must come from:

1. The process environment, or
2. A sidecar `.env` next to the executable (or next to the `.app` on macOS), or
3. `user://.env` in Godot’s user data directory.


