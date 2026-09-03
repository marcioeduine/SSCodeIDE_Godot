class_name ThemeController
extends RefCounted

## Encapsulates theme loading, application, configuration persistence, and
## the built-in palette table. Delegates visual construction to
## ThemeResourceRegistry.

const ThemeResources = preload("res://scripts/theme_resource_registry.gd")
const ThemeColors = preload("res://scripts/theme_color_scheme.gd")

signal theme_changed(theme_name: String, label: String)

var active_theme: String = "adwaita_darker"
var custom_themes: Dictionary[String, Dictionary] = {}
var theme_menu_keys: Array[String] = []
var theme_menu_import_id: int = 10_000
var _root_control: Control = null

func setup(root: Control) -> void:
	_root_control = root

func load_theme_config() -> void:
	_load_custom_themes()
	var cfg := ConfigFile.new()
	if cfg.load("user://ui_config.cfg") == OK:
		active_theme = str(cfg.get_value("theme", "name", "adwaita_darker"))
	if not all_themes().has(active_theme) or ThemeResources.load_theme(active_theme) == null:
		active_theme = "adwaita_darker"

func save_theme_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ui_config.cfg")
	cfg.set_value("theme", "name", active_theme)
	cfg.save("user://ui_config.cfg")

func request_theme_change(name: String) -> bool:
	if name == active_theme:
		return false
	if _root_control:
		return apply_theme_by_name(name, _root_control)
	return false

func apply_theme_by_name(name: String, root: Control) -> bool:
	var previous: String = active_theme
	active_theme = name
	if not apply_theme_resource(name, root):
		active_theme = previous
		return false
	save_theme_config()
	var label: String = str(all_themes().get(name, {}).get("label", name))
	theme_changed.emit(name, label)
	return true

func apply_theme_resource(theme_name: String, root: Control) -> bool:
	var selected := ThemeResources.load_theme(theme_name)
	if selected == null:
		return false
	root.theme = selected
	return true

func all_themes() -> Dictionary:
	var merged := ThemeColors.ALL_THEMES.duplicate()
	for key in custom_themes:
		merged[key] = custom_themes[key]
	return merged

func active_palette() -> Dictionary:
	return all_themes().get(active_theme, ThemeColors.DARK_THEMES.adwaita_darker)

func populate_themes_menu(menu: PopupMenu) -> void:
	if menu == null:
		return
	menu.clear()
	theme_menu_keys.clear()
	var keys: Array[String] = []
	for raw_key in all_themes().keys():
		var key := str(raw_key)
		if ThemeResources.load_theme(key) != null or ThemeResources.save_custom_theme(key, all_themes()[key]) == OK:
			keys.append(key)
	keys.sort_custom(func(a: String, b: String) -> bool:
		return str(all_themes()[a].get("label", a)).naturalnocasecmp_to(str(all_themes()[b].get("label", b))) < 0
	)
	for key in keys:
		var info: Dictionary = all_themes()[key]
		var item_index := menu.item_count
		var label: String = str(info.get("label", key))
		if custom_themes.has(key):
			label += "  (XML)"
		menu.add_radio_check_item(label, theme_menu_keys.size())
		menu.set_item_checked(item_index, key == active_theme)
		menu.set_item_tooltip(item_index, "Currently selected" if key == active_theme else "Apply " + label)
		theme_menu_keys.append(key)
	if theme_menu_keys.is_empty():
		menu.add_item("No theme resources available")
		menu.set_item_disabled(0, true)
	menu.add_separator()
	menu.add_item("Import XML theme…", theme_menu_import_id)

func on_theme_menu_id_pressed(id: int, root: Control, on_applied: Callable = Callable()) -> void:
	if id == theme_menu_import_id:
		return
	if id >= 0 and id < theme_menu_keys.size():
		var name: String = theme_menu_keys[id]
		if name == active_theme:
			return
		if apply_theme_by_name(name, root):
			var label: String = str(all_themes().get(name, {}).get("label", name))
			if on_applied.is_valid():
				on_applied.call(label)

func _load_custom_themes() -> void:
	custom_themes.clear()
	var dir := DirAccess.open("user://themes")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir() and fname.ends_with(".xml"):
			var path := "user://themes/" + fname
			var result := parse_theme_xml(path)
			if not result.is_empty():
				var key: String = ThemeResources.safe_key(str(result.get("key", fname.trim_suffix(".xml"))))
				result["key"] = key
				custom_themes[key] = result
				if ThemeResources.load_theme(key) == null:
					ThemeResources.save_custom_theme(key, result)
		fname = dir.get_next()
	dir.list_dir_end()

func parse_theme_xml(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var xml_text := file.get_as_text()
	file.close()
	var parser := XMLParser.new()
	if parser.open_buffer(xml_text.to_utf8_buffer()) != OK:
		return {}
	var result: Dictionary = {}
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var tag := parser.get_node_name()
			if tag == "theme":
				result["key"] = parser.get_named_attribute_value_safe("name")
				result["label"] = parser.get_named_attribute_value_safe("label")
				if result["key"].is_empty():
					result["key"] = path.get_file().trim_suffix(".xml")
				if result["label"].is_empty():
					result["label"] = result["key"]
			elif tag == "colour" or tag == "color":
				var k := parser.get_named_attribute_value_safe("key")
				var v := parser.get_named_attribute_value_safe("value")
				if not k.is_empty() and not v.is_empty():
					result[k] = v
	var required := ["bg_surface", "fg", "blue", "green"]
	for req in required:
		if not result.has(req):
			return {}
	return result

func import_theme_xml(xml_path: String, on_imported: Callable = Callable()) -> void:
	var parsed := parse_theme_xml(xml_path)
	if parsed.is_empty():
		if on_imported.is_valid():
			on_imported.call(false, "Invalid XML file or incomplete theme.")
		return
	var key: String = ThemeResources.safe_key(str(parsed.get("key", "custom")))
	parsed["key"] = key
	var dest_name: String = key + ".xml"
	var dest_path := "user://themes/" + dest_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
	var src := FileAccess.open(xml_path, FileAccess.READ)
	if src == null:
		if on_imported.is_valid():
			on_imported.call(false, "Could not read the XML file.")
		return
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(dest_path, FileAccess.WRITE)
	if dst == null:
		if on_imported.is_valid():
			on_imported.call(false, "Could not save the theme to user://themes/.")
		return
	dst.store_string(content)
	dst.close()
	if ThemeResources.save_custom_theme(key, parsed) != OK:
		if on_imported.is_valid():
			on_imported.call(false, "Could not compile the imported theme resource.")
		return
	_load_custom_themes()
	var label: String = str(parsed.get("label", key))
	if on_imported.is_valid():
		on_imported.call(true, label)
