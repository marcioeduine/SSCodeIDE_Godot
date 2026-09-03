class_name ThemeResourceRegistry
extends RefCounted

## Resource selection and compilation. Visual rules are persisted in .theme assets;
## the running UI avoids inline runtime overrides, following JetBrains IDE design.

const ThemeColors = preload("res://scripts/theme_color_scheme.gd")

const RESOURCE_PATHS: Dictionary = {
	"adwaita_darker": "res://themes/ui_grid_outline.theme",
	"monokai": "res://themes/ui_material3_monokai.theme",
	"tokyo_night": "res://themes/ui_material3_tokyo_night.theme",
	"dracula": "res://themes/ui_material3_dracula.theme",
	"catppuccin": "res://themes/ui_material3_catppuccin.theme",
	"nord": "res://themes/ui_material3_nord.theme",
	"jakes_theme": "res://themes/ui_material3_jakes_theme.theme",
	"terminal": "res://themes/ui_material3_terminal.theme",
	"solarized_dark": "res://themes/ui_material3_solarized_dark.theme",
	"adwaita_lighter": "res://themes/ui_material3_adwaita_lighter.theme",
	"monokai_light": "res://themes/ui_material3_monokai_light.theme",
	"tokyo_night_light": "res://themes/ui_material3_tokyo_night_light.theme",
	"dracula_light": "res://themes/ui_material3_dracula_light.theme",
	"catppuccin_light": "res://themes/ui_material3_catppuccin_light.theme",
	"nord_light": "res://themes/ui_material3_nord_light.theme",
	"solarized_light": "res://themes/ui_material3_solarized_light.theme",
}

static func load_theme(theme_name: String) -> Theme:
	var path: String = str(RESOURCE_PATHS.get(theme_name, ""))
	if path.is_empty():
		path = "user://themes/%s.theme" % safe_key(theme_name)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Theme

static func safe_key(value: String) -> String:
	var cleaned := ""
	for character in value.strip_edges().to_lower():
		if character.to_lower() != character.to_upper() or character.is_valid_int() or character in ["_", "-"]:
			cleaned += character
	return cleaned if not cleaned.is_empty() else "custom_theme"

static func save_custom_theme(theme_name: String, palette: Dictionary) -> Error:
	var directory := "user://themes"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	return ResourceSaver.save(_build_material3_theme(palette), "%s/%s.theme" % [directory, safe_key(theme_name)])

static func _colour(palette: Dictionary, key: String, fallback: Color) -> Color:
	var source := Color(str(palette.get(key, fallback.to_html())))
	return source if source.a > 0.0 else fallback

static func _box(fill: Color, border: Color, radius: int, padding: int, border_width: int = 0, elevated: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	box.anti_aliasing = true
	if elevated:
		box.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 2)
	return box

static func _box_margins(fill: Color, border: Color, radius: int, left: int, top: int, right: int, bottom: int, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = left
	box.content_margin_top = top
	box.content_margin_right = right
	box.content_margin_bottom = bottom
	box.anti_aliasing = true
	return box

static func _set_surface(theme: Theme, control_type: StringName, normal: StyleBox, focused: StyleBox) -> void:
	theme.set_stylebox("panel", control_type, normal)
	theme.set_stylebox("normal", control_type, normal)
	theme.set_stylebox("read_only", control_type, normal)
	theme.set_stylebox("focus", control_type, focused)

static func _build_material3_theme(palette: Dictionary) -> Theme:
	var background := _colour(palette, "bg_darker", _colour(palette, "bg_black", Color("#141416")))
	var surface := _colour(palette, "bg_surface", Color("#1e1e24"))
	var container := _colour(palette, "bg_card", surface.lightened(0.06))
	var variant := _colour(palette, "bg_lighter", container.lightened(0.08))
	var on_surface := _colour(palette, "fg", Color("#dcdce0"))
	var on_variant := _colour(palette, "muted", on_surface.darkened(0.28))
	var outline := on_variant.darkened(0.40) if background.get_luminance() < 0.5 else on_variant.lightened(0.35)
	var primary := _colour(palette, "blue", Color("#4c8bf5"))
	var _secondary := _colour(palette, "cyan", Color("#3bbdbd"))
	var on_primary := Color.WHITE if primary.get_luminance() < 0.4 else background
	var is_light := str(palette.get("variant", "dark")) == "light"

	var theme := Theme.new()
	theme.default_font = null
	theme.default_font_size = 13

	var panel := _box(surface, outline, 4, 8, 1)
	var focus_panel := _box(surface, primary, 4, 8, 2)
	for control_type in [&"Panel", &"PanelContainer", &"PopupPanel", &"FileDialog", &"AcceptDialog"]:
		_set_surface(theme, control_type, panel, focus_panel)

	# JetBrains / VS Code IDE Panels: clean borders with refined padding
	theme.set_type_variation(&"M3SidePanel", &"PanelContainer")
	theme.set_stylebox("panel", &"M3SidePanel", _box_margins(surface, outline, 0, 10, 8, 10, 8, 1))
	theme.set_stylebox("focus", &"M3SidePanel", _box_margins(surface, primary, 0, 10, 8, 10, 8, 1))

	theme.set_type_variation(&"M3EditorSurface", &"PanelContainer")
	theme.set_stylebox("panel", &"M3EditorSurface", _box(background, outline, 0, 0, 1))
	theme.set_stylebox("focus", &"M3EditorSurface", _box(background, primary, 0, 0, 2))

	theme.set_type_variation(&"M3ChatSurface", &"PanelContainer")
	theme.set_stylebox("panel", &"M3ChatSurface", _box_margins(surface, outline, 0, 12, 10, 12, 10, 1))
	theme.set_stylebox("focus", &"M3ChatSurface", _box_margins(surface, primary, 0, 12, 10, 12, 10, 1))

	# NavBar (Top Bar) — JetBrains subtle header styling with comfortable padding
	theme.set_type_variation(&"M3TopAppBar", &"PanelContainer")
	theme.set_stylebox("panel", &"M3TopAppBar", _box_margins(surface, outline, 0, 8, 3, 8, 3, 1))
	theme.set_stylebox("focus", &"M3TopAppBar", _box_margins(surface, primary, 0, 8, 3, 8, 3, 1))

	# StatusBar — JetBrains IDE status line with clean separation and padding
	theme.set_type_variation(&"M3StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", &"M3StatusBar", _box_margins(container, outline, 0, 12, 2, 12, 2, 1))
	theme.set_stylebox("focus", &"M3StatusBar", _box_margins(container, primary, 0, 12, 2, 12, 2, 1))

	# Chat Composer Box
	theme.set_type_variation(&"M3Composer", &"PanelContainer")
	theme.set_stylebox("panel", &"M3Composer", _box_margins(container, outline, 6, 8, 8, 8, 8, 1))
	theme.set_stylebox("focus", &"M3Composer", _box_margins(container, primary, 6, 8, 8, 8, 8, 1))

	# Surfaces
	for control_type in [&"Tree", &"ItemList", &"RichTextLabel", &"TextEdit", &"CodeEdit"]:
		_set_surface(theme, control_type, _box(background, outline, 0, 6, 1), _box(background, primary, 0, 6, 1))
		theme.set_color("font_color", control_type, on_surface)
		theme.set_color("default_color", control_type, on_surface)

	theme.set_type_variation(&"M3CodeEditor", &"CodeEdit")
	theme.set_font("font", &"M3CodeEditor", load("res://fonts/FiraCodeNerdFont-Regular.ttf") as Font)
	theme.set_font_size("font_size", &"M3CodeEditor", 14)
	theme.set_stylebox("normal", &"M3CodeEditor", _box(background, Color.TRANSPARENT, 0, 0))
	theme.set_stylebox("read_only", &"M3CodeEditor", _box(background, Color.TRANSPARENT, 0, 0))
	theme.set_stylebox("focus", &"M3CodeEditor", _box(background, primary, 0, 0, 1))

	theme.set_type_variation(&"M3MarkdownDocument", &"RichTextLabel")
	theme.set_stylebox("normal", &"M3MarkdownDocument", _box(background, Color.TRANSPARENT, 0, 12))
	theme.set_stylebox("focus", &"M3MarkdownDocument", _box(background, primary, 0, 12, 1))

	theme.set_type_variation(&"M3ChatTranscript", &"RichTextLabel")
	theme.set_stylebox("normal", &"M3ChatTranscript", _box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4))
	theme.set_stylebox("focus", &"M3ChatTranscript", _box(background, primary, 0, 4, 1))

	theme.set_type_variation(&"M3ExplorerTree", &"Tree")
	theme.set_stylebox("panel", &"M3ExplorerTree", _box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	theme.set_stylebox("normal", &"M3ExplorerTree", _box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	theme.set_stylebox("focus", &"M3ExplorerTree", _box(Color.TRANSPARENT, primary, 0, 0, 1))

	var field := _box_margins(surface, outline, 4, 8, 4, 8, 4, 1)
	for control_type in [&"LineEdit", &"OptionButton", &"SpinBox"]:
		theme.set_stylebox("normal", control_type, field)
		theme.set_stylebox("hover", control_type, _box_margins(container, primary.darkened(0.2), 4, 8, 4, 8, 4, 1))
		theme.set_stylebox("focus", control_type, _box_margins(surface, primary, 4, 8, 4, 8, 4, 1))
		theme.set_stylebox("pressed", control_type, _box_margins(variant, primary, 4, 8, 4, 8, 4, 1))
		theme.set_color("font_color", control_type, on_surface)
		theme.set_color("font_placeholder_color", control_type, on_variant)

	# Buttons: Default buttons
	theme.set_stylebox("normal", &"Button", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("hover", &"Button", _box(variant, Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("pressed", &"Button", _box(variant.darkened(0.08), Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("focus", &"Button", _box(variant, primary, 4, 6, 1))
	theme.set_color("font_color", &"Button", on_surface)
	theme.set_color("font_hover_color", &"Button", on_surface)
	theme.set_color("font_pressed_color", &"Button", on_surface)

	theme.set_type_variation(&"M3FilledButton", &"Button")
	theme.set_stylebox("normal", &"M3FilledButton", _box(primary, Color.TRANSPARENT, 4, 8))
	theme.set_stylebox("hover", &"M3FilledButton", _box(primary.lightened(0.08), Color.TRANSPARENT, 4, 8))
	theme.set_stylebox("pressed", &"M3FilledButton", _box(primary.darkened(0.08), Color.TRANSPARENT, 4, 8))
	theme.set_stylebox("focus", &"M3FilledButton", _box(primary, on_surface, 4, 8, 1))
	theme.set_color("font_color", &"M3FilledButton", on_primary)
	theme.set_color("font_hover_color", &"M3FilledButton", on_primary)
	theme.set_color("font_pressed_color", &"M3FilledButton", on_primary)

	theme.set_type_variation(&"M3TextButton", &"Button")
	theme.set_stylebox("normal", &"M3TextButton", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("hover", &"M3TextButton", _box(primary.darkened(0.72) if not is_light else primary.lightened(0.85), Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("pressed", &"M3TextButton", _box(primary.darkened(0.62) if not is_light else primary.lightened(0.75), Color.TRANSPARENT, 4, 6))
	theme.set_stylebox("focus", &"M3TextButton", _box(Color.TRANSPARENT, primary, 4, 6, 1))
	theme.set_color("font_color", &"M3TextButton", primary)
	theme.set_color("font_hover_color", &"M3TextButton", primary.lightened(0.15) if not is_light else primary.darkened(0.15))

	# NavBar Buttons: ONLY text color change on hover, no background fill box change
	var transparent_nav := _box_margins(Color.TRANSPARENT, Color.TRANSPARENT, 4, 8, 4, 8, 4)
	theme.set_stylebox("normal", &"MenuBar", transparent_nav)
	theme.set_stylebox("hover", &"MenuBar", transparent_nav)
	theme.set_stylebox("pressed", &"MenuBar", transparent_nav)
	theme.set_color("font_color", &"MenuBar", on_surface)
	theme.set_color("font_hover_color", &"MenuBar", primary)
	theme.set_color("font_pressed_color", &"MenuBar", primary)

	# AppBrandButton in NavBar: text-only hover effect, flat, stylish
	theme.set_type_variation(&"M3AppBrandButton", &"MenuButton")
	theme.set_stylebox("normal", &"M3AppBrandButton", transparent_nav)
	theme.set_stylebox("hover", &"M3AppBrandButton", transparent_nav)
	theme.set_stylebox("pressed", &"M3AppBrandButton", transparent_nav)
	theme.set_stylebox("focus", &"M3AppBrandButton", transparent_nav)
	theme.set_color("font_color", &"M3AppBrandButton", primary)
	theme.set_color("font_hover_color", &"M3AppBrandButton", primary.lightened(0.2) if not is_light else primary.darkened(0.2))
	theme.set_font_size("font_size", &"M3AppBrandButton", 13)

	# ThemeToggleBtn in NavBar (Sun / Moon)
	theme.set_type_variation(&"M3ThemeToggle", &"Button")
	theme.set_stylebox("normal", &"M3ThemeToggle", transparent_nav)
	theme.set_stylebox("hover", &"M3ThemeToggle", transparent_nav)
	theme.set_stylebox("pressed", &"M3ThemeToggle", transparent_nav)
	theme.set_stylebox("focus", &"M3ThemeToggle", transparent_nav)
	theme.set_color("font_color", &"M3ThemeToggle", on_surface)
	theme.set_color("font_hover_color", &"M3ThemeToggle", primary)
	theme.set_font_size("font_size", &"M3ThemeToggle", 14)

	# Popup Menus: JetBrains style elevated dropdowns with clean borders
	theme.set_stylebox("panel", &"PopupMenu", _box_margins(container, outline, 6, 8, 8, 8, 8, 1))
	theme.set_stylebox("hover", &"PopupMenu", _box_margins(variant, Color.TRANSPARENT, 4, 8, 4, 8, 4))
	theme.set_color("font_color", &"PopupMenu", on_surface)
	theme.set_color("font_hover_color", &"PopupMenu", on_surface)
	theme.set_color("font_accelerator_color", &"PopupMenu", on_variant)

	# TabBar: JetBrains IDE style clean tabs
	# Active tab: subtle highlight background + bottom primary accent bar
	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = background
	tab_sel.border_color = primary
	tab_sel.set_border_width(SIDE_BOTTOM, 2)
	tab_sel.content_margin_left = 14
	tab_sel.content_margin_right = 14
	tab_sel.content_margin_top = 7
	tab_sel.content_margin_bottom = 7
	tab_sel.anti_aliasing = true

	var tab_unsel := StyleBoxFlat.new()
	tab_unsel.bg_color = Color.TRANSPARENT
	tab_unsel.border_color = Color.TRANSPARENT
	tab_unsel.content_margin_left = 14
	tab_unsel.content_margin_right = 14
	tab_unsel.content_margin_top = 7
	tab_unsel.content_margin_bottom = 7
	tab_unsel.anti_aliasing = true

	var tab_hov := StyleBoxFlat.new()
	tab_hov.bg_color = variant.darkened(0.15) if not is_light else variant.lightened(0.2)
	tab_hov.border_color = Color.TRANSPARENT
	tab_hov.content_margin_left = 14
	tab_hov.content_margin_right = 14
	tab_hov.content_margin_top = 7
	tab_hov.content_margin_bottom = 7
	tab_hov.anti_aliasing = true

	theme.set_stylebox("tab_selected", &"TabBar", tab_sel)
	theme.set_stylebox("tab_unselected", &"TabBar", tab_unsel)
	theme.set_stylebox("tab_hovered", &"TabBar", tab_hov)
	theme.set_color("font_selected_color", &"TabBar", on_surface)
	theme.set_color("font_unselected_color", &"TabBar", on_variant)
	theme.set_color("font_hovered_color", &"TabBar", on_surface)
	theme.set_constant("tab_separation", &"TabBar", 0)

	# Global fonts and typography
	theme.set_color("font_color", &"Label", on_surface)
	theme.set_font_size("font_size", &"Label", 13)
	theme.set_font_size("font_size", &"Button", 13)
	theme.set_font_size("font_size", &"MenuBar", 13)
	theme.set_font_size("font_size", &"PopupMenu", 13)
	theme.set_font_size("font_size", &"LineEdit", 13)
	theme.set_font_size("font_size", &"OptionButton", 13)
	theme.set_constant("separation", &"HSplitContainer", 1)
	theme.set_constant("separation", &"VSplitContainer", 1)

	theme.set_type_variation(&"M3AppBrand", &"Label")
	theme.set_font_size("font_size", &"M3AppBrand", 12)
	theme.set_color("font_color", &"M3AppBrand", primary)

	theme.set_type_variation(&"M3SidebarHeader", &"Label")
	theme.set_font_size("font_size", &"M3SidebarHeader", 11)
	theme.set_color("font_color", &"M3SidebarHeader", on_variant)

	theme.set_type_variation(&"M3StatusText", &"Label")
	theme.set_font_size("font_size", &"M3StatusText", 12)
	theme.set_color("font_color", &"M3StatusText", on_variant)

	theme.set_color("font_selected_color", &"Tree", primary)
	theme.set_color("font_selected_color", &"ItemList", primary)
	theme.set_color("caret_color", &"CodeEdit", primary)
	theme.set_color("background_color", &"CodeEdit", background)
	theme.set_color("caret_background_color", &"CodeEdit", background)
	theme.set_color("gutter_background_color", &"CodeEdit", surface)
	theme.set_color("minimap_background_color", &"CodeEdit", surface)
	theme.set_color("current_line_color", &"CodeEdit", container)
	theme.set_color("selection_color", &"CodeEdit", primary.darkened(0.45))
	theme.set_color("line_number_color", &"CodeEdit", on_variant)
	theme.set_color("font_color", &"CodeEdit", on_surface)
	theme.set_color("default_color", &"RichTextLabel", on_surface)

	return theme
