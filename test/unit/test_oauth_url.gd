extends GutTest


func test_accepts_google_loopback_callback() -> void:
	var url := "http://127.0.0.1:33221/callback?state=abc&iss=https://accounts.google.com&code=4/0ATsMZqB&scope=email"
	assert_true(OAuthUrl.is_loopback_callback(url))


func test_accepts_localhost_codex_path() -> void:
	var url := "http://localhost:1455/auth/callback?code=xyz&state=s1"
	assert_true(OAuthUrl.is_loopback_callback(url))


func test_rejects_empty_and_https_and_missing_code() -> void:
	assert_false(OAuthUrl.is_loopback_callback(""))
	assert_false(OAuthUrl.is_loopback_callback("https://accounts.google.com/o/oauth2/auth?code=x&state=y"))
	assert_false(OAuthUrl.is_loopback_callback("http://127.0.0.1:33221/callback?state=only"))
	assert_false(OAuthUrl.is_loopback_callback("http://example.com/callback?code=x&state=y"))
