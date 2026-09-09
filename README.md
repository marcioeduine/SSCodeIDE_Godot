# SSCodeIDE

<p align="center">
  <strong>A lightweight, modern Integrated Development Environment (IDE) built entirely in native GDScript for Godot Engine 4.x.</strong>
</p>

<p align="center">
  <img src="icon.svg" alt="SSCodeIDE Logo" width="128" height="128">
</p>

---

Full technical documentation lives in [`docs/`](docs/README.md).

## Overview

**SSCodeIDE** is a dedicated code editor and development environment engineered entirely with **Godot Engine 4.x** and **GDScript** with a modern JetBrains / VS Code inspired UI/UX. Featuring Dark and Light modes, clean flat TabBar styling with accent indicators, full typographic support with *FiraCode Nerd Font*, a hierarchical workspace file explorer, and a native AI coding assistant with automated candidate fallback, SSCodeIDE provides a streamlined coding experience without external runtime dependencies or mandatory login requirements.

---

## Key Functional Features

- **Minimal Collapsible Sidebar Navigation & Styling**:
  - Slim vertical activity navigation rail (`NavRail`) featuring quick access to Explorer, Edit, Git, Themes, AI Chat, Settings, and Help.
  - Dynamic **Theme Toggle** button in the navigation rail for instant Light and Dark mode switching.
  - Interactive **AppBrand** (`favicon.svg`) providing About dialogue and exit (`Ctrl+Q`).
  - Collapsible side drawer (`ExplorerPane`) with workspace switcher (`Switch Workspace…`), file tree, and zero-distraction collapse (`Ctrl+B`).
  - Streamlined tab bar (`TabBar`) featuring flat active tabs with bottom accent indicator bars and comfortable padding.
  - Built-in **Dark** and **Light** modes, plus runtime XML theme importing from the Themes menu.

- **Multi-Tab Code Editor (`CodeEdit`)**:
  - Multi-tab management with active file tracking and modification state indicators.
  - Line numbers, syntax highlighting, and dynamic auto-indentation.
  - Built-in Find & Replace panel (`Ctrl+F` / `Ctrl+H`) with match navigation and replace-all.
  - Fast line operations: duplication (<kbd>Ctrl</kbd>+<kbd>D</kbd>), upward/downward line shifting (<kbd>Alt</kbd>+<kbd>↑</kbd> / <kbd>Alt</kbd>+<kbd>↓</kbd>), and comment toggling (<kbd>Ctrl</kbd>+<kbd>/</kbd>).

- **Workspace File Explorer (`FileTree`)**:
  - Hierarchical directory inspection and real-time workspace tree updates.
  - Automatic file kind recognition and dedicated visual iconography (`at-icons`) across scripts (`.gd`, `.py`, `.js`, `.ts`, `.cpp`, `.rs`, `.go`), scenes (`.tscn`, `.scn`), configurations (`.json`, `.cfg`, `.toml`, `.yaml`), images, audio, video, documents, and archives.

- **Native Git & GitHub Integration (`GitService`)**:
  - Dedicated **Git** Menu Bar with status, commits, push, pull, fetch, sync, branch management, diffs, log history, and configuration.
  - Interactive Status Bar branch indicator (`main`) with real-time modified file counters and status modal.
  - Full GitHub remote synchronisation (`git push`, `git pull`, `git fetch`, `git sync`) and GitHub URL parsing (SSH and HTTPS).
  - Built-in slash commands in AI Chat: `/git status`, `/git diff`, `/git log`, `/git commit`, `/git push`, `/git pull`, `/git sync`, `/git branch`, `/git checkout`, `/git remote`, `/git config`, `/git clone`, `/github`.
  - Automated Smart Commit generation adhering to Conventional Commits.

- **Integrated AI Assistant Panel with Live Web Search & Agent Capabilities**:
  - Dedicated side-panel chat interface for code assistance, live debugging, documentation, and queries.
  - **Live Internet & Web Search (`WebSearchService`)**: Real-time web querying (`/search <query>`, `/web <query>`) for up-to-date documentation, release notes, and real-time knowledge.
  - **Intimate Pair-Programming Persona ('Tu')**: Friendly, warm, supportive, and intimate tone in European Portuguese (pt-PT) with British English (en-GB) code standards.
  - Direct asynchronous HTTP client communicating with **NVIDIA NIM API**, supporting:
	- `NVIDIA Nemotron` (`nvidia/nemotron-3-nano-omni-30b-a3b-reasoning`, `nvidia/nemotron-3.5-lightning-30b-a3b`)
	- `Moonshot Kimi K3` (`moonshotai/kimi-k3`)
	- `DeepSeek V4` (`deepseek-ai/deepseek-v4-pro-0813`)
	- `Laguna Code` (`poolside/laguna-xs-2.1`)
  - Intelligent multi-model candidate fallback mechanism to mitigate transient service errors.
  - On first Chat or Smart Commit use the editor asks for an NVIDIA NIM API key and stores it in Godot user data (`user://ai_secrets.cfg`). Change it under Config. Optional override: `NVIDIA_NIM_API_KEY` or a sidecar `.env` (see `.env.example`). Never commit real keys.
  - Non-blocking asynchronous requests with cancellation support (<kbd>Esc</kbd>) and animated toast notifications.

- **Automated Test Suite**:
  - Unit test coverage powered by **GUT (Godot Unit Test)**.

---

## Keyboard Shortcuts

### File Operations
| Shortcut | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>N</kbd> | Create new untitled file |
| <kbd>Ctrl</kbd> + <kbd>O</kbd> | Open file dialogue |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>O</kbd> | Open workspace directory |
| <kbd>Ctrl</kbd> + <kbd>S</kbd> | Save active file |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Save active file as... |
| <kbd>Ctrl</kbd> + <kbd>W</kbd> | Close active tab |
| <kbd>Ctrl</kbd> + <kbd>Tab</kbd> | Switch to next tab |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Switch to previous tab |
| <kbd>Ctrl</kbd> + <kbd>Q</kbd> | Quit application |

### Git & GitHub Operations
| Shortcut | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>G</kbd> | Open Git Status & Changes dialogue |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> | Generate Smart Git Commit & Stage All |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>U</kbd> | Push local commits to GitHub repository |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Pull latest changes from GitHub repository |

### Editor Operations
| Shortcut | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Z</kbd> / <kbd>Ctrl</kbd> + <kbd>Y</kbd> | Undo / Redo |
| <kbd>Ctrl</kbd> + <kbd>X</kbd> / <kbd>Ctrl</kbd> + <kbd>C</kbd> / <kbd>Ctrl</kbd> + <kbd>V</kbd> | Cut / Copy / Paste |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> | Select all |
| <kbd>Ctrl</kbd> + <kbd>F</kbd> | Open search panel |
| <kbd>Ctrl</kbd> + <kbd>/</kbd> | Toggle line comment |
| <kbd>Ctrl</kbd> + <kbd>D</kbd> | Duplicate current line |
| <kbd>Alt</kbd> + <kbd>↑</kbd> / <kbd>Alt</kbd> + <kbd>↓</kbd> | Move current line up / down |

### IDE & Navigation
| Shortcut | Action |
| :--- | :--- |
| <kbd>F1</kbd> | Display Help and keyboard shortcuts |
| <kbd>Ctrl</kbd> + <kbd>,</kbd> | Display Configuration dialogue |
| <kbd>Ctrl</kbd> + <kbd>P</kbd> | Focus File Explorer |
| <kbd>Ctrl</kbd> + <kbd>B</kbd> | Toggle file explorer sidebar |
| <kbd>Ctrl</kbd> + <kbd>J</kbd> / <kbd>K</kbd> / <kbd>`</kbd> | Focus AI chat input |
| <kbd>Esc</kbd> | Cancel ongoing AI generation / dismiss dialogue |

---

## Repository Structure

```text
.
├── addons/                         # Godot addons (at-icons, gut test framework)
├── docs/                           # Comprehensive technical documentation
├── fonts/                          # Typography (FiraCode Nerd Font)
├── icons/                          # SVG icons and visual assets
├── scene/                          # Godot scenes
│   ├── ui_editor.tscn              # Main IDE scene
│   └── welcome.tscn                # Instant asynchronous welcome loader scene
├── scripts/                        # Modular GDScript controllers & services
│   ├── agent_workspace_service.gd  # Workspace file mutation service
│   ├── ai_service.gd               # NVIDIA NIM API integration and fallback logic
│   ├── app_brand_button.gd         # AppBrand menu button controller
│   ├── chat_markdown_renderer.gd   # Markdown & GFM renderer for chat
│   ├── code_editor_service.gd      # Code completion & editor utilities
│   ├── editor_chat_controller.gd   # AI assistant, reasoning tokens & streaming controller
│   ├── editor_dialog_controller.gd # Lazy modal overlay dialog & toast controller
│   ├── editor_file_manager.gd      # Multi-tab buffers, file tree & workspace search
│   ├── editor_git_controller.gd   # Git status, smart commits, push/pull/sync & diffs
│   ├── editor_input_handler.gd     # Global keyboard shortcuts & CodeEdit input router
│   ├── editor_sidebar_builder.gd   # Lazy on-demand sidebar panel generator
│   ├── editor_theme_manager.gd     # Theme manager, Kitty/Fish highlighters & XML importer
│   ├── file_controller.gd          # File explorer and buffer management
│   ├── file_kind.gd                # File type categorisation & 14px Lanczos icon scaling
│   ├── git_service.gd              # Native Git & GitHub version control service
│   ├── markdown_preview_renderer.gd# Markdown tab preview renderer
│   ├── theme_color_scheme.gd       # Theme palette schema & definitions
│   ├── theme_controller.gd         # Theme application and config controller
│   ├── theme_resource_registry.gd  # Theme resource manager with cache reuse (CACHE_MODE_REUSE)
│   ├── ui_editor.gd                # Primary IDE orchestrator
│   └── web_search_service.gd       # Real-time Internet and web search service
├── test/                           # Automated unit tests (GUT)
│   └── unit/
│       ├── test_ai_service.gd
│       ├── test_file_kind.gd
│       ├── test_git_service.gd
│       ├── test_ui_editor_script.gd
│       └── test_web_search_service.gd
├── themes/                         # dark.theme, light.theme, and example XML import template
├── project.godot                   # Godot project settings and engine configuration
├── .gutconfig.json                 # GUT test runner configuration
├── LICENSE                         # Proprietary licence agreement
└── README.md                       # Technical documentation
```

---

## Prerequisites & Launch

### Requirements
- **Godot Engine 4.x** (version 4.3 or higher recommended).

### Running the Project
1. Open Godot Engine Project Manager.
2. Select **Import**, navigate to the project directory, and select `project.godot`.
3. Launch the project by pressing <kbd>F5</kbd> or clicking **Run** in the Godot interface.

---

## Running Unit Tests

Unit tests are managed via **GUT**. To run the test suite in headless mode via command line:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

---

## Licence & Copyright

**Copyright (C) 2026 Ser Superior (SS). All rights reserved.**

This project is strictly proprietary and confidential. It is **not** open-source software, and third parties are strictly prohibited from copying, distributing, modifying, sublicensing, or commercialising any portion of this software without prior express written authorisation from **Ser Superior (SS)**.

See the [LICENSE](LICENSE) file for complete licence terms.
