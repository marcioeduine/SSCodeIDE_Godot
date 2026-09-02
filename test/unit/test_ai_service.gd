extends GutTest

## Unit tests for AIService candidate model resolution and fallback mechanisms.


func test_candidate_models_for_nemotron() -> void:
	var models: Array[String] = AIService.get_candidate_models("nemotron")
	assert_gt(models.size(), 1)
	assert_eq(models[0], "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning")


func test_candidate_models_for_nemotron_lightning() -> void:
	var models: Array[String] = AIService.get_candidate_models("nemotron_lightning")
	assert_gt(models.size(), 1)
	assert_eq(models[0], "nvidia/nemotron-3.5-lightning-30b-a3b")


func test_candidate_models_for_deepseek() -> void:
	var models: Array[String] = AIService.get_candidate_models("deepseek_v4")
	assert_gt(models.size(), 1)
	assert_eq(models[0], "deepseek-ai/deepseek-v4-pro-0813")


func test_candidate_models_for_kimi() -> void:
	var models: Array[String] = AIService.get_candidate_models("kimi_k3")
	assert_gt(models.size(), 1)
	assert_eq(models[0], "moonshotai/kimi-k3")


func test_candidate_models_for_laguna() -> void:
	var models: Array[String] = AIService.get_candidate_models("laguna")
	assert_gt(models.size(), 1)
	assert_eq(models[0], "poolside/laguna-xs-2.1")


func test_fallback_always_includes_nemotron() -> void:
	for provider: String in ["deepseek_v4", "kimi_k3", "laguna"]:
		var models: Array[String] = AIService.get_candidate_models(provider)
		assert_true(models.has("nvidia/nemotron-3-nano-omni-30b-a3b-reasoning"), "Provider '%s' should fallback to nemotron" % provider)


func test_api_key_prefers_environment_variable() -> void:
	AIService._cached_api_key = ""
	OS.set_environment("NVIDIA_NIM_API_KEY", "test-env-key")
	assert_eq(AIService.get_nvidia_api_key(), "test-env-key")
	AIService._cached_api_key = ""
	OS.set_environment("NVIDIA_NIM_API_KEY", "")
