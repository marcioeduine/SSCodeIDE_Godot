class_name AIService
extends RefCounted

## AIService — Native GDScript AI Service Integration
## Provides multi-model integration and automated candidate fallback via the NVIDIA NIM API.

const NVIDIA_BASE_URL := "https://integrate.api.nvidia.com/v1/chat/completions"
const NVIDIA_API_KEY_ENV := "NVIDIA_NIM_API_KEY"
const ENV_FILE_PATH := "res://.env"

static var _cached_api_key: String = ""


static func get_nvidia_api_key() -> String:
	if not _cached_api_key.is_empty():
		return _cached_api_key
	var from_env := OS.get_environment(NVIDIA_API_KEY_ENV).strip_edges()
	if not from_env.is_empty():
		_cached_api_key = from_env
		return _cached_api_key
	var from_file := _read_env_file_value(NVIDIA_API_KEY_ENV)
	if not from_file.is_empty():
		_cached_api_key = from_file
	return _cached_api_key


static func _read_env_file_value(key: String) -> String:
	if not FileAccess.file_exists(ENV_FILE_PATH):
		return ""
	var file := FileAccess.open(ENV_FILE_PATH, FileAccess.READ)
	if file == null:
		return ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var eq := line.find("=")
		if eq <= 0:
			continue
		var name := line.substr(0, eq).strip_edges()
		if name != key:
			continue
		var value := line.substr(eq + 1).strip_edges()
		if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
			value = value.substr(1, value.length() - 2)
		elif value.begins_with("'") and value.ends_with("'") and value.length() >= 2:
			value = value.substr(1, value.length() - 2)
		file.close()
		return value
	file.close()
	return ""

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
