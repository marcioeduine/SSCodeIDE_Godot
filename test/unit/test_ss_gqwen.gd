extends GutTest


func test_oauth_url_accepts_loopback() -> void:
	var url := "http://127.0.0.1:33221/callback?state=abc&code=4/xyz"
	assert_true(OAuthUrl.is_loopback_callback(url))


func test_oauth_url_rejects_remote() -> void:
	var url := "https://accounts.google.com/o/oauth2/auth?code=x&state=y"
	assert_false(OAuthUrl.is_loopback_callback(url))


func test_google_auth_constants() -> void:
	assert_eq(GoogleAuth.CLIENT_ID, "790560907959-uqr5b5k5m3dk23egj5in47mqtbrtej7d.apps.googleusercontent.com")
	assert_eq(GoogleAuth.CLIENT_SECRET, "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")


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


func test_google_auth_session_persistence() -> void:
	GoogleAuth.save_tokens({"access_token": "ya29.test_token", "refresh_token": "1//test_refresh"})
	assert_true(GoogleAuth.is_logged_in())
	assert_eq(GoogleAuth.get_access_token(), "ya29.test_token")
	assert_eq(GoogleAuth.get_refresh_token(), "1//test_refresh")
	GoogleAuth.clear_session()
	assert_false(GoogleAuth.is_logged_in())
