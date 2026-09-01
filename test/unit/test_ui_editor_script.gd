extends GutTest


func test_ui_editor_script_loads() -> void:
	var scr: Script = load("res://scripts/ui_editor.gd")
	assert_not_null(scr)


func test_file_kind_script_loads() -> void:
	var scr: Script = load("res://scripts/file_kind.gd")
	assert_not_null(scr)


func test_main_scene_exists() -> void:
	assert_true(ResourceLoader.exists("res://scene/ui_editor.tscn"))


func test_oauth_url_script_loads() -> void:
	var scr: Script = load("res://scripts/oauth_url.gd")
	assert_not_null(scr)


func test_web_view_script_loads() -> void:
	var scr: Script = load("res://scripts/web_view.gd")
	assert_not_null(scr)


func test_ai_service_script_loads() -> void:
	var scr: Script = load("res://scripts/ai_service.gd")
	assert_not_null(scr)


func test_google_auth_script_loads() -> void:
	var scr: Script = load("res://scripts/google_auth.gd")
	assert_not_null(scr)


