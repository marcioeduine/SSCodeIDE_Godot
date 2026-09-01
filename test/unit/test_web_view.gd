extends GutTest


func test_web_view_script_loads() -> void:
	var scr: Script = load("res://scripts/web_view.gd")
	assert_not_null(scr)


func test_web_view_instantiation() -> void:
	var webview = load("res://scripts/web_view.gd").new()
	assert_not_null(webview)
	assert_eq(webview.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(webview.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	webview.free()
