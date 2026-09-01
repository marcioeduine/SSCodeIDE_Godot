# SSCodeIDE

<p align="center">
  <strong>A lightweight, modern Integrated Development Environment (IDE) built entirely in native GDScript for Godot Engine 4.x.</strong>
</p>

<p align="center">
  <img src="icon.svg" alt="SSCodeIDE Logo" width="128" height="128">
</p>

---

## Overview

**SSCodeIDE** is a dedicated code editor and development environment engineered entirely with **Godot Engine 4.x** and **GDScript**. Combining a Monokai Pro aesthetic theme, full typographic support with *FiraCode Nerd Font*, a hierarchical workspace file explorer, and a native AI coding assistant with automated candidate fallback, SSCodeIDE provides a streamlined coding experience.

---

## Key Functional Features

- **Multi-Tab Code Editor (`CodeEdit`)**:
  - Multi-tab management with active file tracking and modification state indicators.
  - Line numbers, syntax highlighting, and dynamic auto-indentation.
  - Built-in search panel (`Find`) with match navigation.
  - Fast line operations: duplication (<kbd>Ctrl</kbd>+<kbd>D</kbd>), upward/downward line shifting (<kbd>Alt</kbd>+<kbd>↑</kbd> / <kbd>Alt</kbd>+<kbd>↓</kbd>), and comment toggling (<kbd>Ctrl</kbd>+<kbd>/</kbd>).

- **Workspace File Explorer (`FileTree`)**:
  - Hierarchical directory inspection and real-time workspace tree updates.
  - Automatic file kind recognition and dedicated visual iconography (`at-icons`) across scripts (`.gd`, `.py`, `.js`, `.ts`, `.cpp`, `.rs`, `.go`), scenes (`.tscn`, `.scn`), configurations (`.json`, `.cfg`, `.toml`, `.yaml`), images, audio, video, documents, and archives.

- **Integrated AI Assistant Panel**:
  - Dedicated side-panel chat interface for code assistance and queries.
  - Direct HTTP client communicating with **NVIDIA NIM API**, supporting:
    - `NVIDIA Nemotron` (`nvidia/nemotron-3-nano-omni-30b-a3b-reasoning`, `nvidia/nemotron-3.5-lightning-30b-a3b`)
    - `Moonshot Kimi K3` (`moonshotai/kimi-k3`)
    - `DeepSeek V4` (`deepseek-ai/deepseek-v4-pro-0813`)
    - `Laguna Code` (`poolside/laguna-xs-2.1`)
  - Multi-model fallback mechanism to handle transient errors and rate limits seamlessly.
  - Instant request cancellation (<kbd>Esc</kbd>) and animated toast notifications.

- **Authentication & Web Integration**:
  - Native Google OAuth 2.0 loopback TCP server authorisation workflow.
  - Embedded modal dialogue for web authorisation and official provider logins.

- **Automated Test Suite**:
  - Full unit test coverage powered by **GUT (Godot Unit Test)**.

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
| <kbd>Ctrl</kbd> + <kbd>L</kbd> | Open AI Login dialogue |
| <kbd>Ctrl</kbd> + <kbd>P</kbd> | Focus File Explorer |
| <kbd>Esc</kbd> | Cancel ongoing AI generation |

---

## Repository Structure

```text
.
├── addons/             # Godot addons (at-icons, gut test framework)
├── fonts/              # Typography (FiraCode Nerd Font)
├── scene/              # Godot scenes
│   └── ui_editor.tscn  # Main IDE scene and layout hierarchy
├── scripts/            # Core GDScript modules
│   ├── ai_service.gd   # NVIDIA NIM API integration and fallback logic
│   ├── file_kind.gd    # File type categorisation and icon mapping
│   ├── google_auth.gd  # Google OAuth 2.0 loopback server handler
│   ├── oauth_url.gd    # OAuth URL parser and validation helper
│   ├── ui_editor.gd    # Primary IDE UI controller and state manager
│   └── web_view.gd     # WebView and web dialogue component
├── test/               # Automated unit tests (GUT)
│   └── unit/
├── project.godot       # Godot project settings and engine configuration
├── .gutconfig.json     # GUT test runner configuration
├── LICENSE             # Proprietary licence agreement
└── README.md           # Technical documentation
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

Unit tests are managed via **GUT**. To run the full test suite in headless mode via command line:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

---

## Licence & Copyright

**Copyright (C) 2026 Ser Superior (SS). All rights reserved.**

This project is strictly proprietary and confidential. It is **not** open-source software, and third parties are strictly prohibited from copying, distributing, modifying, sublicensing, or commercialising any portion of this software without prior express written authorisation from **Ser Superior (SS)**.

See the [LICENSE](LICENSE) file for complete licence terms.
