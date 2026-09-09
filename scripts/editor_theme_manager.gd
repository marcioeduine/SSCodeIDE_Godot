class_name EditorThemeManager
extends RefCounted

## Manages themes

const ThemeResources = preload("res://scripts/theme_resource_registry.gd")
const MarkdownPreview = preload("res://scripts/markdown_preview_renderer.gd")

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

func refresh_themes_panel() -> void:
	if _e._themes_list == null:
		return
	_e._themes_list.clear()
	var custom_keys: Array[String] = []
	for raw_key in _e._custom_themes.keys():
		var key = str(raw_key)
		if not ThemeColorScheme.is_builtin_mode(key):
			custom_keys.append(key)
	custom_keys.sort()
	for key in custom_keys:
		var info: Dictionary = _e._custom_themes.get(key, {})
		var label: String = str(info.get("label", key))
		var idx = _e._themes_list.add_item(label + " (XML)")
		_e._themes_list.set_item_metadata(idx, key)
		if key == _e._active_theme:
			_e._themes_list.select(idx)
	if custom_keys.is_empty():
		_e._themes_list.add_item("No custom XML themes imported")
		_e._themes_list.set_item_disabled(0, true)


func setup_app_brand_menu() -> void:
	if _e._app_brand == null:
		return
	var popup = _e._app_brand.get_popup()
	if not popup.id_pressed.is_connected(on_app_brand_menu_id_pressed):
		popup.id_pressed.connect(on_app_brand_menu_id_pressed)
	if _e._theme_toggle_btn and not _e._theme_toggle_btn.pressed.is_connected(toggle_light_dark_theme):
		_e._theme_toggle_btn.pressed.connect(toggle_light_dark_theme)
	update_app_brand_menu()
	update_theme_toggle_btn()



func update_app_brand_menu() -> void:
	if _e._app_brand == null:
		return
	var popup = _e._app_brand.get_popup()
	popup.clear()
	popup.add_item("About SSCodeIDE", 1)
	popup.add_item("Close\tCtrl+Q", 2)



func update_theme_toggle_btn() -> void:
	if _e._theme_toggle_btn == null:
		return
	var is_light = theme_is_light(_e._active_theme)
	_e._theme_toggle_btn.icon = preload("res://icons/nav_moon.svg") if is_light else preload("res://icons/nav_sun.svg")
	_e._theme_toggle_btn.text = ""
	_e._theme_toggle_btn.tooltip_text = "Switch to Dark Mode" if is_light else "Switch to Light Mode"



func theme_is_light(theme_name: String) -> bool:
	return ThemeColorScheme.is_light(theme_name, all_themes().get(theme_name, {}))



func toggle_light_dark_theme() -> void:
	var target = ThemeColorScheme.MODE_DARK if theme_is_light(_e._active_theme) else ThemeColorScheme.MODE_LIGHT
	apply_theme_by_name(target)



func on_app_brand_menu_id_pressed(id: int) -> void:
	match id:
		1:
			_e.dialog.show_about()
		2:
			_e.get_tree().quit()



func all_themes() -> Dictionary:
	var merged = ThemeColorScheme.MODE_THEMES.duplicate()
	for key in _e._custom_themes:
		if ThemeColorScheme.is_builtin_mode(str(key)):
			continue
		merged[key] = _e._custom_themes[key]
	return merged



func resolve_theme_name(_name: String) -> String:
	if _e._custom_themes.has(_name) and not ThemeColorScheme.is_builtin_mode(_name):
		return _name
	if ThemeColorScheme.is_builtin_mode(_name):
		return _name
	return ThemeColorScheme.canonical_mode(_name)



func load_theme_config() -> void:
	load_custom_themes()
	var cfg = ConfigFile.new()
	if cfg.load("user://ui_config.cfg") == OK:
		_e._active_theme = str(cfg.get_value("theme", "name", ThemeColorScheme.MODE_DARK))
	_e._active_theme = resolve_theme_name(_e._active_theme)
	if not all_themes().has(_e._active_theme) or ThemeResources.load_theme(_e._active_theme) == null:
		_e._active_theme = ThemeColorScheme.MODE_DARK



func save_theme_config() -> void:
	var cfg = ConfigFile.new()
	cfg.load("user://ui_config.cfg")
	cfg.set_value("theme", "name", _e._active_theme)
	cfg.save("user://ui_config.cfg")



func apply_theme_by_name(_name: String) -> void:
	var resolved = resolve_theme_name(_name)
	if resolved == _e._active_theme:
		return
	var previous_theme = _e._active_theme
	_e._active_theme = resolved
	if not apply_kitty_fish_theme():
		_e._active_theme = previous_theme
		_e.chat.append_chat("IDE", "[color=#ed333b]Theme not found:[/color] " + resolved, Color("#ed333b"))
		_e.dialog.show_toast("Theme not found: " + resolved, true)
		return
	save_theme_config()
	var label: String = str(all_themes().get(resolved, {}).get("label", resolved))
	populate_themes_menu()
	update_app_brand_menu()
	update_theme_toggle_btn()
	_e.chat.rebuild_chat_log()
	if _e._md_preview_active and _e._active_index >= 0 and _e._active_index < _e._open_files.size():
		_e._set_markdown_preview(true, _e._code_edit.text)
	_e.dialog.show_toast("Theme: " + label, false)



func populate_themes_menu() -> void:
	if _e._themes_menu == null:
		return
	_e._themes_menu.clear()
	_e._theme_menu_keys.clear()
	var keys: Array[String] = []
	var custom_keys: Array[String] = []
	for raw_key in _e._custom_themes.keys():
		var key = str(raw_key)
		if ThemeColorScheme.is_builtin_mode(key):
			continue
		if ThemeResources.load_theme(key) != null:
			custom_keys.append(key)
	custom_keys.sort_custom(func(left: String, right: String) -> bool:
		return str(all_themes()[left].get("label", left)).naturalnocasecmp_to(str(all_themes()[right].get("label", right))) < 0
	)
	keys.append_array(custom_keys)
	for key in keys:
		if ThemeResources.load_theme(key) == null:
			continue
		var info: Dictionary = all_themes().get(key, {})
		var item_index = _e._themes_menu.item_count
		var label: String = str(info.get("label", key))
		if _e._custom_themes.has(key):
			label += "  (XML)"
		_e._themes_menu.add_radio_check_item(label, _e._theme_menu_keys.size())
		_e._themes_menu.set_item_checked(item_index, key == _e._active_theme)
		_e._themes_menu.set_item_tooltip(item_index, "Currently selected" if key == _e._active_theme else "Apply " + str(info.get("label", key)))
		_e._theme_menu_keys.append(key)
	if _e._theme_menu_keys.is_empty():
		_e._themes_menu.add_item("No custom XML themes imported")
		_e._themes_menu.set_item_disabled(0, true)
	_e._themes_menu.add_separator()
	_e._themes_menu.add_item("Import XML theme…", _e.THEME_MENU_IMPORT_ID)



func on_theme_menu_id_pressed(id: int) -> void:
	if id == _e.THEME_MENU_IMPORT_ID:
		_e.dialog.import_theme_xml_dialog()
		return
	if id >= 0 and id < _e._theme_menu_keys.size():
		apply_theme_by_name(_e._theme_menu_keys[id])



func load_custom_themes() -> void:
	## Scans user://themes/ and loads all valid .xml theme files into _e._custom_themes
	_e._custom_themes.clear()
	var dir = DirAccess.open("user://themes")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir() and fname.ends_with(".xml"):
			var path = "user://themes/" + fname
			var result = parse_theme_xml(path)
			if not result.is_empty():
				var key: String = ThemeResources.safe_key(str(result.get("key", fname.trim_suffix(".xml"))))
				result["key"] = key
				if ThemeColorScheme.is_builtin_mode(key):
					fname = dir.get_next()
					continue
				_e._custom_themes[key] = result
				ThemeResources.save_custom_theme(key, result)
		fname = dir.get_next()
	dir.list_dir_end()



func parse_theme_xml(path: String) -> Dictionary:
	## Parses an XML theme file and returns a theme Dictionary, or empty if invalid.
	## Expected format:
	##   <theme name="my_theme" label="My Theme Label">
	##     <colour key="bg_black" value="#1a1a2e"/>
	##     ...
	##   </theme>
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var xml_text = file.get_as_text()
	file.close()
	var parser = XMLParser.new()
	if parser.open_buffer(xml_text.to_utf8_buffer()) != OK:
		return {}
	var result: Dictionary = {}
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var tag = parser.get_node_name()
			if tag == "theme":
				result["key"] = parser.get_named_attribute_value_safe("name")
				result["label"] = parser.get_named_attribute_value_safe("label")
				var variant = parser.get_named_attribute_value_safe("variant")
				if not variant.is_empty():
					result["variant"] = variant
				if result["key"].is_empty():
					result["key"] = path.get_file().trim_suffix(".xml")
				if result["label"].is_empty():
					result["label"] = result["key"]
			elif tag == "colour" or tag == "color":
				var k = parser.get_named_attribute_value_safe("key")
				var v = parser.get_named_attribute_value_safe("value")
				if not k.is_empty() and not v.is_empty():
					result[k] = v
	## Validate that the minimum required keys are present
	var required = ["bg_surface", "fg", "blue", "green"]
	for req in required:
		if not result.has(req):
			return {}
	result["variant"] = ThemeColorScheme.infer_variant(result)
	return result



func import_theme_from_xml(xml_path: String) -> void:
	## Imports a theme from the given .xml path into user://themes/
	var parsed = parse_theme_xml(xml_path)
	if parsed.is_empty():
		_e.chat.append_chat("IDE", "[color=#ed333b]Invalid XML file or incomplete theme.[/color]\nCheck the format: [color=#9a9996]<theme name=\"id\" label=\"Name\">[/color]", Color("#ed333b"))
		_e.dialog.show_toast("Theme XML: invalid format.", true)
		return
	## Copy file into user://themes/
	var key: String = ThemeResources.safe_key(str(parsed.get("key", "custom")))
	if ThemeColorScheme.is_builtin_mode(key):
		key = key + "_custom"
	parsed["key"] = key
	var dest_name: String = key + ".xml"
	var dest_path = "user://themes/" + dest_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
	var src = FileAccess.open(xml_path, FileAccess.READ)
	if src == null:
		_e.chat.append_chat("IDE", "[color=#ed333b]Could not read the XML file.[/color]", Color("#ed333b"))
		return
	var content = src.get_as_text()
	src.close()
	var dst = FileAccess.open(dest_path, FileAccess.WRITE)
	if dst == null:
		_e.chat.append_chat("IDE", "[color=#ed333b]Could not save the theme to user://themes/.[/color]", Color("#ed333b"))
		return
	dst.store_string(content)
	dst.close()
	if ThemeResources.save_custom_theme(key, parsed) != OK:
		_e.chat.append_chat("IDE", "[color=#ed333b]Could not compile the imported theme resource.[/color]", Color("#ed333b"))
		_e.dialog.show_toast("Theme import failed.", true)
		return
	## Reload and apply
	load_custom_themes()
	populate_themes_menu()
	var label: String = str(parsed.get("label", key))
	apply_theme_by_name(key)
	_e.chat.append_chat("IDE", "[color=#57e389]Theme imported:[/color] [b]" + label + "[/b]\nSaved as XML and Theme resource in: [color=#9a9996]user://themes/[/color]", Color("#57e389"))
	_e.dialog.show_toast("Theme installed: " + label, false)



func apply_kitty_fish_theme() -> bool:
	## Theme assets are authored in Godot resources. This only selects one;
	## it deliberately does not build or override any visual styles at runtime.
	if not apply_theme_resource(_e._active_theme):
		return false
	_e._code_edit.syntax_highlighter = _e._create_adwaita_fish_highlighter()
	return true



func apply_theme_resource(theme_name: String) -> bool:
	var selected = ThemeResources.load_theme(theme_name)
	if selected == null:
		selected = ThemeResources.load_theme(ThemeColorScheme.MODE_DARK)
	if selected == null:
		return false
	_e.theme = selected
	_e._root_vbox.theme = selected
	return true


