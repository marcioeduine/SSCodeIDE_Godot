# Credentials and exported binaries

The NVIDIA NIM key must never live in GDScript constants or Git history.

Typical users never set environment variables. The editor asks for the key on first Chat or Smart Commit use and stores it in Godot user data.

## Variable

`NVIDIA_NIM_API_KEY`

Loader: `AIService.get_nvidia_api_key()` in `scripts/ai_service.gd`.

Persisted copy: `user://ai_secrets.cfg` (section `nvidia`, key `api_key`). Change or clear it from **Config → NVIDIA NIM API key…**.

## Lookup order

1. **Process environment** — `OS.get_environment("NVIDIA_NIM_API_KEY")`. Optional override for tests and CI.
2. **Stored key** — `user://ai_secrets.cfg`, written after the first-use prompt.
3. **`.env` beside the executable** — `OS.get_executable_path()` directory.
4. **macOS bundle parent** — if the executable path ends with `/Contents/MacOS`, also try `.env` next to the `.app`.
5. **Current working directory** — `PWD` or `.env` in `.`.
6. **`user://.env`** — extra optional file in Godot user data.
7. **`res://.env`** — editor / unpacked project only. After export this is inside the `.pck`.

The first non-empty value is cached in `_cached_api_key` for the process lifetime.

`.env` lines are `KEY=value`. Quotes are stripped. Lines starting with `#` are ignored.

## First-use prompt (Applications menu)

A `.desktop` launcher does **not** inherit `export` from `~/.bashrc` or `~/.zshrc`. You do **not** need to put the key in `Exec=`.

On first Chat or Smart Commit, if no key is found, a secret field asks for it. Confirm stores it under `user://`. Later launches reuse it. Config can replace or clear it (empty confirm removes the stored key).

Smart Commit waits for a key before `git add -A`, so cancelling the prompt does not stage files.

## Optional environment / sidecar `.env`

Useful for GUT tests and CI, not required for a GUI user:

```bash
export NVIDIA_NIM_API_KEY="your-key"
./SSCodeIDE
```

That child process inherits the environment. A menu icon does not.

| Platform | Where to put `.env` |
| :--- | :--- |
| Linux | Same folder as the executable |
| Windows | Same folder as the `.exe` |
| macOS | Same folder as `YourApp.app` (not only inside `Contents/MacOS`) |

Linux persistent session env (optional): `~/.config/environment.d/*.conf`, then log in again. Windows: user environment variables. These still lose to the in-app stored key only when the process env is empty.

## What not to do

- Do not commit `.env` or `ai_secrets.cfg`.
- Do not paste keys into `ai_service.gd`.
- Do not rely on `res://.env` in a shipped build.
- Do not put the key in a `.desktop` `Exec=` line.
- If a key leaked in Git, revoke it at the provider, rewrite history (`git filter-repo` / BFG), and force-push only after the team agrees.

The stored file is plaintext in the OS user-data directory, not an OS keyring.

Template: repository root `.env.example`.
