# User guide

## Minimal Collapsible Sidebar Navigation

SSCodeIDE adopts a modern, minimalist collapsible sidebar navigation inspired by JetBrains and Untitled UI:
- **Navigation Rail (Slim Vertical Bar)**:
  - **App Brand (`favicon.svg`)**: Access application info (About SSCodeIDE) and exit (`Ctrl+Q`).
  - **Navigation Icons**: Quick access to File Explorer (📁), Edit Actions (✏️), Git & GitHub (⎇), Themes (🎨), and AI Chat Assistant (💬).
  - **Theme Toggle (`☀️` / `🌙`)**: Dynamic toggle button switching seamlessly between Dark and Light mode.
  - **Utility Actions**: Quick settings (⚙️) and keyboard shortcuts help (❓).
- **Collapsible Drawer / Explorer**:
  - **Workspace Header**: Displays current workspace folder name with switch workspace action (`⇄ Switch Workspace…`).
  - **File Explorer**: Fast workspace tree view with custom type icons.
  - **Collapse / Expand (`Ctrl+B`)**: Collapse the drawer completely to leave only the minimal rail, giving 100% full-width view to the editor and chat tabs.

## Workspace

Use **⇄ Switch Workspace…** or `Ctrl+Shift+O` to set the workspace root. The explorer lists files with type icons. Double-click a file to open a tab.

## Editing

- New file: `Ctrl+N`
- Open file: `Ctrl+O`
- Save / Save As: `Ctrl+S` / `Ctrl+Shift+S`
- Close tab: `Ctrl+W`
- Next / previous tab: `Ctrl+Tab` / `Ctrl+Shift+Tab`
- Duplicate line: `Ctrl+D`
- Move line: `Alt+↑` / `Alt+↓`
- Toggle comment: `Ctrl+/`
- Find: editor search panel
- Quit: `Ctrl+Q`

Syntax highlighting and auto-indent apply to GDScript and other common source extensions.

## Git

Requires `git` on `PATH`.

| Shortcut | Action |
| :--- | :--- |
| `Ctrl+Shift+G` | Status and changes |
| `Ctrl+Shift+C` | Smart Commit (AI Conventional Commit, then stage all) |
| `Ctrl+Shift+U` | Push |
| `Ctrl+Shift+L` | Pull |

The Git menu also exposes fetch, sync, branch, checkout, remotes, config, clone, and GitHub info. The status bar shows `⎇ <branch>` and a dirty-file count.

### Chat slash commands

In the AI panel: `/git status`, `/git diff`, `/git log`, `/git commit`, `/git push`, `/git pull`, `/git sync`, `/git branch`, `/git checkout`, `/git remote`, `/git config`, `/git clone`, `/github`, `/compact`.

`/compact` summarises older conversation context locally and preserves the most recent messages, reducing the amount of history sent to the AI.

## AI assistant

The side panel talks to NVIDIA NIM. Choose a provider in Config. On first Chat or Smart Commit the editor asks for an API key and saves it on this machine. Change or clear it under **Config → NVIDIA NIM API key…**. Requests are asynchronous; **Esc** cancels.

In Agent mode, the assistant can create or edit workspace files using `<sscode-write path="relative/path">…</sscode-write>` blocks. Paths outside the active workspace are rejected.

See [credentials-and-export.md](credentials-and-export.md).

## Themes

SSCodeIDE provides a comprehensive suite of JetBrains-inspired palettes:
- **Dark themes**: Adwaita Darker, Monokai, Tokyo Night, Dracula, Catppuccin Mocha, Nord, Jake's Theme, Terminal (Antigravity), Solarized Dark.
- **Light themes**: Adwaita Lighter, Monokai Light, Tokyo Night Light, Dracula Light, Catppuccin Latte, Nord Light, Solarized Light.
- **Tab styling**: JetBrains IDE flat tabs with a 2px bottom primary accent indicator on active tabs and clean muted inactive tabs.
- **XML import**: Custom XML themes in `themes/` or `user://themes/` can be imported directly via the Themes menu (`Import XML theme…`).
- **Duplicate protection**: Selecting the currently active theme will not trigger redundant re-application.

## Help

Shortcuts and documentation overlays can be accessed via `F1`, the Help menu, or the AppBrand menu.
