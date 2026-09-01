class_name AIService
extends RefCounted

## AIService — Native GDScript AI Service Integration
## Provides multi-model integration and automated candidate fallback via the NVIDIA NIM API.

const NVIDIA_BASE_URL := "https://integrate.api.nvidia.com/v1/chat/completions"
const NVIDIA_API_KEY := "***REMOVED***"

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
