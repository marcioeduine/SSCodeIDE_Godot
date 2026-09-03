# User guide

## Workspace

Use **File → Open Folder** (`Ctrl+Shift+O`) to set the workspace root. The explorer lists files with type icons. Double-click a file to open a tab.

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

Built-in palettes plus optional XML files in `themes/` (`example_theme.xml`, `jakes_theme.xml`). Import via Config.

## Help

Help and About overlays list shortcuts and version notes.
