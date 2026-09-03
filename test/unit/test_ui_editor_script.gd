extends GutTest

## Unit tests verifying core scripts, editor scenes, Git tools, checklist formatting, and prompt controls.


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


func test_theme_menu_is_scene_backed_and_replaces_slash_selector() -> void:
	var scene := load("res://scene/ui_editor.tscn") as PackedScene
	var editor := scene.instantiate()
	add_child_autofree(editor)
	await get_tree().process_frame
	var menu := editor.get_node_or_null("RootVBox/NavBar/NavRow/MenuBar/Themes") as PopupMenu
	assert_not_null(menu)
	assert_gt(menu.item_count, 1)
	assert_eq(menu.get_item_text(menu.item_count - 1), "Import XML theme…")
	var commands: Array[String] = []
	for entry: Dictionary in editor.CHAT_SLASH_COMMANDS:
		commands.append(str(entry.get("cmd", "")))
	assert_false(commands.has("/theme"))


func test_theme_menu_applies_a_resource_and_marks_the_active_choice() -> void:
	var scene := load("res://scene/ui_editor.tscn") as PackedScene
	var editor := scene.instantiate()
	add_child_autofree(editor)
	await get_tree().process_frame
	var previous: String = editor._active_theme
	var monokai_id: int = editor._theme_menu_keys.find("monokai")
	assert_ne(monokai_id, -1)
	editor._on_theme_menu_id_pressed(monokai_id)
	assert_eq(editor._active_theme, "monokai")
	assert_eq((editor.theme as Theme).resource_path, "res://themes/ui_material3_monokai.theme")
	var menu := editor.get_node("RootVBox/NavBar/NavRow/MenuBar/Themes") as PopupMenu
	assert_true(menu.is_item_checked(monokai_id))
	editor._apply_theme_by_name(previous)


func test_markdown_formatting_helpers() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	var formatted_bold: String = editor_script._replace_bold("This is **important** code.")
	assert_eq(formatted_bold, "This is [b]important[/b] code.")
	
	var formatted_inline: String = editor_script._replace_inline_code("Run `git status` command.")
	assert_true(formatted_inline.contains("[color=#99c1f1] git status [/color]"))
	
	var formatted_link: String = editor_script._replace_links("Read [README](README.md) file.")
	assert_true(formatted_link.contains("[color=#62a0ea][u]README[/u][/color]"))
	
	var markdown_sample: String = "### Actions\n- [ ] Pending task\n- [x] Completed task\n- **Item 1**: Done\n> Note block\n```gdscript\nvar x = 1\n```"
	var bbcode_output: String = editor_script._format_markdown_to_bbcode(markdown_sample)
	assert_true(bbcode_output.contains("[color=#ffffff][b]Actions[/b][/color]"))
	assert_true(bbcode_output.contains("☐ Pending task"))
	assert_true(bbcode_output.contains("✔ Completed task"))
	assert_true(bbcode_output.contains("[color=#57e389]•[/color] [b]Item 1[/b]: Done"))
	assert_true(bbcode_output.contains("▎"))
	assert_true(bbcode_output.contains("Copy"))
	
	editor_script.free()


func test_workspace_context_generation() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	editor_script._workspace_root = "/home/mcaquart/sgoinfre/.ss/SSDevTools/SSCodeIDE - Godot"
	var files: Array[String] = editor_script._get_workspace_files_list()
	assert_gt(files.size(), 0)
	
	var context_str: String = editor_script._get_workspace_context()
	assert_true(context_str.contains("Workspace Root:"))
	assert_true(context_str.contains("Project Directory Structure"))
	
	editor_script.free()


func test_git_command_execution() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	var res: Dictionary = editor_script._execute_git_command(["--version"])
	assert_eq(res["exit_code"], 0)
	assert_true(str(res["output"]).to_lower().contains("git version"))
	
	editor_script.free()


func test_file_kind_icons_and_colors() -> void:
	assert_eq(FileKind.icon_key_for_path("dir", true, false), "folder")
	assert_eq(FileKind.icon_key_for_path("dir", true, true), "folder_open")
	assert_eq(FileKind.icon_key_for_path("main.gd"), "godot")
	assert_eq(FileKind.icon_key_for_path("scene.tscn"), "scene")
	assert_eq(FileKind.icon_key_for_path("main.py"), "python")
	assert_eq(FileKind.icon_key_for_path("index.ts"), "typescript")
	assert_eq(FileKind.icon_key_for_path("App.tsx"), "react")
	assert_eq(FileKind.icon_key_for_path(".gitignore"), "git")
	assert_eq(FileKind.icon_key_for_path("package.json"), "json")
	assert_eq(FileKind.icon_key_for_path("Cargo.toml"), "rust")
	assert_eq(FileKind.icon_key_for_path("script.sh"), "shell")
	assert_eq(FileKind.icon_key_for_path("README.md"), "markdown")
	
	assert_eq(FileKind.color_for_path("main.gd"), Color("#478cbf"))
	assert_eq(FileKind.color_for_path("main.py"), Color("#599eff"))
	assert_eq(FileKind.color_for_path("script.sh"), Color("#57e389"))
	assert_eq(FileKind.color_for_path(".gitignore"), Color("#f05032"))
	assert_eq(FileKind.label_for_path("main.gd"), "GDScript")


func test_prompt_history_and_tab_switching() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	# Prompt history test
	assert_eq(editor_script._prompt_history.size(), 0)
	editor_script._prompt_history.append("first prompt")
	editor_script._prompt_history.append("second prompt")
	assert_eq(editor_script._prompt_history.size(), 2)
	assert_eq(editor_script._prompt_history[0], "first prompt")
	assert_eq(editor_script._prompt_history[1], "second prompt")
	
	# Open files mock for tab switching
	editor_script._open_files = [
		{"path": "file1.gd", "title": "file1.gd"},
		{"path": "file2.gd", "title": "file2.gd"},
		{"path": "file3.gd", "title": "file3.gd"}
	]
	editor_script._active_index = 0
	
	editor_script.free()


func test_markdown_to_bbcode_gfm_renderer() -> void:
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	var md_text: String = """# Title
## Section

| Shortcut | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>N</kbd> | Create file |
| <kbd>Ctrl</kbd> + <kbd>S</kbd> | Save file |

- [x] Done task
- [ ] Todo task
"""
	var bbcode: String = editor_script._markdown_to_bbcode(md_text)
	assert_true(bbcode.contains("[table=2]"))
	assert_true(bbcode.contains("Shortcut"))
	assert_true(bbcode.contains("Action"))
	assert_true(bbcode.contains("Ctrl"))
	assert_true(bbcode.contains("☑"))
	assert_true(bbcode.contains("☐"))
	assert_false(bbcode.contains("<kbd>"))
	assert_false(bbcode.contains("</kbd>"))
	
	editor_script.free()


func test_git_service_script_integration() -> void:
	var git_scr: Script = load("res://scripts/git_service.gd")
	assert_not_null(git_scr)
	
	var editor_script = load("res://scripts/ui_editor.gd").new()
	assert_not_null(editor_script)
	
	var res: Dictionary = editor_script._execute_git_command(["--version"])
	assert_eq(int(res.get("exit_code", -1)), 0)
	assert_true(str(res.get("output", "")).to_lower().contains("git version"))
	
	# Verify CHAT_SLASH_COMMANDS includes all Git & GitHub commands
	var cmds: Array[String] = []
	for entry: Dictionary in editor_script.CHAT_SLASH_COMMANDS:
		cmds.append(str(entry.get("cmd", "")))
	assert_true(cmds.has("/git status"))
	assert_true(cmds.has("/git diff"))
	assert_true(cmds.has("/git log"))
	assert_true(cmds.has("/git commit"))
	assert_true(cmds.has("/git push"))
	assert_true(cmds.has("/git pull"))
	assert_true(cmds.has("/git sync"))
	assert_true(cmds.has("/git fetch"))
	assert_true(cmds.has("/git branch"))
	assert_true(cmds.has("/github"))
	
	editor_script.free()
