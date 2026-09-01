extends GutTest

## Unit tests verifying core scripts, editor scenes, and CLI formatting routines.


func test_ui_editor_script_loads() -> void:
	var scr: Script = load("res://scripts/ui_editor.gd")
	assert_not_null(scr)


func test_file_kind_script_loads() -> void:
	var scr: Script = load("res://scripts/file_kind.gd")
	assert_not_null(scr)


func test_ai_service_script_loads() -> void:
	var scr: Script = load("res://scripts/ai_service.gd")
	assert_not_null(scr)


func test_main_scene_exists() -> void:
	assert_true(ResourceLoader.exists("res://scene/ui_editor.tscn"))


func test_markdown_formatting_helpers() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	var formatted_bold: String = editor_script._replace_bold("This is **important** code.")
	assert_eq(formatted_bold, "This is [b]important[/b] code.")
	
	var formatted_inline: String = editor_script._replace_inline_code("Run `git status` command.")
	assert_true(formatted_inline.contains("[color=#78dce8] git status [/color]"))
	
	var formatted_link: String = editor_script._replace_links("Read [README](README.md) file.")
	assert_eq(formatted_link, "Read [color=#58a6ff][u]README[/u][/color] file.")
	
	var markdown_sample := "### Actions\n- **Item 1**: Done\n> Note block\n```gdscript\nvar x = 1\n```"
	var bbcode_output: String = editor_script._format_markdown_to_bbcode(markdown_sample)
	assert_true(bbcode_output.contains("[color=#ffd866][b]Actions[/b][/color]"))
	assert_true(bbcode_output.contains("[color=#a9dc76]•[/color] [b]Item 1[/b]: Done"))
	assert_true(bbcode_output.contains("│  Note block"))
	
	editor_script.free()
