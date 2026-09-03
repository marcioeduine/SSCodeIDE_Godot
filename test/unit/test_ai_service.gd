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


func test_env_file_candidates_include_user_and_res() -> void:
	var paths: PackedStringArray = AIService._env_file_candidates()
	assert_true(paths.has("user://.env"))
	assert_true(paths.has("res://.env"))


func test_reads_quoted_assignment_from_env_file() -> void:
	var path := "user://sscodeide_test_dotenv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("# comment\nNVIDIA_NIM_API_KEY=\"from-dotenv\"\n")
	file.close()
	assert_eq(AIService._read_env_file_value(path, "NVIDIA_NIM_API_KEY", false), "from-dotenv")
	DirAccess.remove_absolute(path)


func test_stored_api_key_roundtrip() -> void:
	var backup := _backup_stored_secrets()
	OS.set_environment("NVIDIA_NIM_API_KEY", "")
	AIService._cached_api_key = ""
	assert_true(AIService.set_stored_nvidia_api_key("stored-key-test"))
	AIService._cached_api_key = ""
	assert_eq(AIService.get_nvidia_api_key(), "stored-key-test")
	assert_true(AIService.has_nvidia_api_key())
	assert_true(AIService.set_stored_nvidia_api_key(""))
	AIService._cached_api_key = ""
	assert_eq(AIService.get_nvidia_api_key(), "")
	_restore_stored_secrets(backup)


func test_environment_overrides_stored_api_key() -> void:
	var backup := _backup_stored_secrets()
	OS.set_environment("NVIDIA_NIM_API_KEY", "")
	AIService._cached_api_key = ""
	AIService.set_stored_nvidia_api_key("stored-only")
	OS.set_environment("NVIDIA_NIM_API_KEY", "env-wins")
	AIService._cached_api_key = ""
	assert_eq(AIService.get_nvidia_api_key(), "env-wins")
	OS.set_environment("NVIDIA_NIM_API_KEY", "")
	AIService._cached_api_key = ""
	_restore_stored_secrets(backup)


func test_saving_stored_key_updates_process_environment() -> void:
	var backup := _backup_stored_secrets()
	OS.set_environment("NVIDIA_NIM_API_KEY", "stale-revoked-key")
	AIService._cached_api_key = ""
	assert_true(AIService.set_stored_nvidia_api_key("fresh-gui-key"))
	assert_eq(OS.get_environment("NVIDIA_NIM_API_KEY"), "fresh-gui-key")
	assert_eq(AIService.get_nvidia_api_key(), "fresh-gui-key")
	OS.set_environment("NVIDIA_NIM_API_KEY", "")
	AIService._cached_api_key = ""
	_restore_stored_secrets(backup)


func _backup_stored_secrets() -> String:
	var path := AIService.STORED_SECRETS_PATH
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var data := f.get_as_text()
	f.close()
	return data


func _restore_stored_secrets(backup: String) -> void:
	var path := AIService.STORED_SECRETS_PATH
	if backup.is_empty():
		DirAccess.remove_absolute(path)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(backup)
	f.close()
