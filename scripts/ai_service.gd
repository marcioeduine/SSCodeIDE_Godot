class_name AIService
extends RefCounted

## AIService — Native GDScript AI Service Integration
## Provides multi-model integration and automated candidate fallback via the NVIDIA NIM API.

const NVIDIA_BASE_URL := "https://integrate.api.nvidia.com/v1/chat/completions"
const NVIDIA_API_KEY_ENV := "NVIDIA_NIM_API_KEY"
const STORED_SECRETS_PATH := "user://ai_secrets.cfg"

static var _cached_api_key: String = ""


static func get_nvidia_api_key() -> String:
	if not _cached_api_key.is_empty():
		return _cached_api_key
	var from_env := OS.get_environment(NVIDIA_API_KEY_ENV).strip_edges()
	if not from_env.is_empty():
		_cached_api_key = from_env
		return _cached_api_key
	var from_store := _read_stored_api_key()
	if not from_store.is_empty():
		_cached_api_key = from_store
		return _cached_api_key
	for path in _env_file_candidates():
		var from_file := _read_env_file_value(path, NVIDIA_API_KEY_ENV, false)
		if not from_file.is_empty():
			_cached_api_key = from_file
			return _cached_api_key
	return ""


static func has_nvidia_api_key() -> bool:
	return not get_nvidia_api_key().is_empty()


static func invalidate_cached_api_key() -> void:
	_cached_api_key = ""


## Persist the key in Godot user data (`user://`). Survives restarts; not packed into the .pck.
static func set_stored_nvidia_api_key(key: String) -> bool:
	var trimmed := key.strip_edges()
	var cfg := ConfigFile.new()
	cfg.load(STORED_SECRETS_PATH)
	if trimmed.is_empty():
		if cfg.has_section_key("nvidia", "api_key"):
			cfg.erase_section_key("nvidia", "api_key")
		_cached_api_key = ""
	else:
		cfg.set_value("nvidia", "api_key", trimmed)
		_cached_api_key = trimmed
	var ok := cfg.save(STORED_SECRETS_PATH) == OK
	# A key saved in the UI must take effect immediately, even if a stale
	# (revoked) process environment value was already set.
	OS.set_environment(NVIDIA_API_KEY_ENV, trimmed)
	return ok


static func _read_stored_api_key() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(STORED_SECRETS_PATH) != OK:
		return ""
	return str(cfg.get_value("nvidia", "api_key", "")).strip_edges()


## Lookup order:
## 1. Process environment (`NVIDIA_NIM_API_KEY`) — optional override for tests/CI.
## 2. Stored key in `user://ai_secrets.cfg` (prompted on first chat use).
## 3. `.env` next to the executable / cwd / `user://.env` / `res://.env` (optional).
static func _env_file_candidates() -> PackedStringArray:
	var paths := PackedStringArray()
	var exe := OS.get_executable_path()
	if not exe.is_empty():
		var exe_dir := exe.get_base_dir()
		_append_unique_path(paths, exe_dir.path_join(".env"))
		# macOS: Godot.exe lives in App.app/Contents/MacOS — put .env beside App.app
		if exe_dir.ends_with("/Contents/MacOS"):
			_append_unique_path(paths, exe_dir.get_base_dir().get_base_dir().path_join(".env"))
	var cwd := OS.get_environment("PWD")
	if cwd.is_empty():
		cwd = "."
	_append_unique_path(paths, cwd.path_join(".env") if cwd != "." else ".env")
	_append_unique_path(paths, "user://.env")
	_append_unique_path(paths, "res://.env")
	return paths


static func _append_unique_path(paths: PackedStringArray, path: String) -> void:
	if path.is_empty() or paths.has(path):
		return
	paths.append(path)


static func _assignment_key(left: String) -> String:
	var name := left.strip_edges()
	if name.begins_with("export "):
		name = name.substr(7).strip_edges()
	elif name.begins_with("declare -x "):
		name = name.substr(11).strip_edges()
	elif name.begins_with("typeset -x "):
		name = name.substr(11).strip_edges()
	return name


static func _unquote_env_value(value: String) -> String:
	if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
		return value.substr(1, value.length() - 2)
	if value.begins_with("'") and value.ends_with("'") and value.length() >= 2:
		return value.substr(1, value.length() - 2)
	return value


static func _read_env_file_value(path: String, key: String, last_wins: bool = false) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var found := ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var eq := line.find("=")
		if eq <= 0:
			continue
		var name := _assignment_key(line.substr(0, eq))
		if name != key:
			continue
		var value := _unquote_env_value(line.substr(eq + 1).strip_edges())
		if value.is_empty():
			continue
		if last_wins:
			found = value
			continue
		file.close()
		return value
	file.close()
	return found

const PROVIDER_MAP := {
	"nemotron": "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
	"nemotron_lightning": "nvidia/nemotron-3.5-lightning-30b-a3b",
	"kimi_k3": "moonshotai/kimi-k3",
	"deepseek_v4": "deepseek-ai/deepseek-v4-pro-0813",
	"laguna": "poolside/laguna-xs-2.1",
}

const PRIMARY_MODELS := {
	"nemotron": "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
	"nemotron_lightning": "nvidia/nemotron-3.5-lightning-30b-a3b",
	"kimi_k3": "moonshotai/kimi-k3",
	"deepseek_v4": "deepseek-ai/deepseek-v4-pro-0813",
	"laguna": "poolside/laguna-xs-2.1",
}

const FALLBACK_MODELS := {
	"nemotron": [
		"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
		"nvidia/nemotron-3.5-lightning-30b-a3b",
		"moonshotai/kimi-k3",
	],
	"nemotron_lightning": [
		"nvidia/nemotron-3.5-lightning-30b-a3b",
		"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
		"moonshotai/kimi-k3",
	],
	"kimi_k3": [
		"moonshotai/kimi-k3",
		"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
		"nvidia/nemotron-3.5-lightning-30b-a3b",
	],
	"deepseek_v4": [
		"deepseek-ai/deepseek-v4-pro-0813",
		"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
		"moonshotai/kimi-k3",
	],
	"laguna": [
		"poolside/laguna-xs-2.1",
		"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
		"nvidia/nemotron-3.5-lightning-30b-a3b",
	],
}


static func get_candidate_models(provider: String) -> Array[String]:
	var p := provider.to_lower()
	var primary: String = PRIMARY_MODELS.get(p, "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning")
	var candidates: Array[String] = [primary]
	var fallbacks: Array = FALLBACK_MODELS.get(p, [])
	for m in fallbacks:
		var model_name: String = str(m)
		if not candidates.has(model_name):
			candidates.append(model_name)
	return candidates
