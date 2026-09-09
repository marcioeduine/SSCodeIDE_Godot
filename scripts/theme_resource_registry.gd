class_name ThemeResourceRegistry
extends RefCounted

## Resource selection and compilation. Visual rules are persisted in .theme assets;
## the running UI avoids inline runtime overrides, following JetBrains IDE design.

const ThemeColors = preload("res://scripts/theme_color_scheme.gd")

const RESOURCE_PATHS: Dictionary = {
	ThemeColors.MODE_DARK: "res://themes/dark.theme",
	ThemeColors.MODE_LIGHT: "res://themes/light.theme",
}

static func load_theme(theme_name: String) -> Theme:
	var custom_path := "user://themes/%s.theme" % safe_key(theme_name)
	var builtin_path: String = str(RESOURCE_PATHS.get(theme_name, ""))
	if ThemeColors.is_builtin_mode(theme_name):
		var built := _load_theme_path(builtin_path, true)
		if built != null:
			return built
		var palette: Dictionary = ThemeColors.MODE_THEMES.get(theme_name, ThemeColors.MODE_THEMES[ThemeColors.MODE_DARK])
		return _build_material3_theme(palette)

	var custom := _load_theme_path(custom_path, true)
	if custom != null:
		return custom
	var fallback_path: String = str(RESOURCE_PATHS.get(ThemeColors.MODE_DARK, "res://themes/dark.theme"))
	var fallback := _load_theme_path(fallback_path, true)
	if fallback != null:
		return fallback
	return _build_material3_theme(ThemeColors.MODE_THEMES[ThemeColors.MODE_DARK])


static func _load_theme_path(path: String, replace_cache: bool) -> Theme:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	var cache_mode := ResourceLoader.CACHE_MODE_REPLACE if replace_cache else ResourceLoader.CACHE_MODE_REUSE
	return ResourceLoader.load(path, "", cache_mode) as Theme

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
	var background := _colour(palette, "bg_darker", _colour(palette, "bg_black", Color("#111112")))
	var surface := _colour(palette, "bg_surface", Color("#141415"))
	var container := _colour(palette, "bg_card", surface.lightened(0.06))
	var variant := _colour(palette, "bg_lighter", container.lightened(0.08))
	var on_surface := _colour(palette, "fg", Color("#EDEDED"))
	var on_variant := _colour(palette, "muted", on_surface.darkened(0.28))
	var outline := on_variant.darkened(0.40) if background.get_luminance() < 0.5 else on_variant.lightened(0.35)
	var primary := _colour(palette, "blue", Color("#4c8bf5"))
	var _secondary := _colour(palette, "cyan", Color("#3bbdbd"))
	var on_primary := Color.WHITE if primary.get_luminance() < 0.4 else background
	var is_light := str(palette.get("variant", "dark")) == "light"

	var theme := Theme.new()
	var font_regular: Font = load("res://fonts/FiraCodeNerdFont-Regular.ttf") as Font
	var font_bold: Font = load("res://fonts/FiraCodeNerdFont-Bold.ttf") as Font
	var font_medium: Font = load("res://fonts/FiraCodeNerdFont-Medium.ttf") as Font

	if font_regular:
		theme.default_font = font_regular
		if font_bold:
			for node_type in [&"Label", &"Button", &"RichTextLabel", &"CodeEdit", &"Tree", &"LineEdit"]:
				theme.set_font("bold_font", node_type, font_bold)
		if font_medium:
			for node_type in [&"Label", &"Button", &"RichTextLabel", &"CodeEdit"]:
				theme.set_font("medium_font", node_type, font_medium)
	else:
		theme.default_font = null
	theme.default_font_size = 13

	var panel := _box(surface, outline, 4, 8, 1)
	var focus_panel := _box(surface, primary, 4, 8, 2)
	for control_type in [&"Panel", &"PanelContainer", &"PopupPanel", &"FileDialog", &"AcceptDialog"]:
		_set_surface(theme, control_type, panel, focus_panel)

	# Vibe IDE / Floating Card Panels: rounded corners (12px) with subtle borders
	var card_bg := surface
	var card_border := Color("#24252e") if not is_light else Color("#d8d9de")
	theme.set_type_variation(&"M3SidePanel", &"PanelContainer")
	theme.set_stylebox("panel", &"M3SidePanel", _box_margins(card_bg, card_border, 12, 10, 8, 10, 8, 1))
	theme.set_stylebox("focus", &"M3SidePanel", _box_margins(card_bg, primary, 12, 10, 8, 10, 8, 1))

	theme.set_type_variation(&"M3EditorSurface", &"PanelContainer")
	theme.set_stylebox("panel", &"M3EditorSurface", _box_margins(card_bg, card_border, 12, 0, 0, 0, 0, 1))
	theme.set_stylebox("focus", &"M3EditorSurface", _box_margins(card_bg, primary, 12, 0, 0, 0, 0, 1))

	theme.set_type_variation(&"M3ChatSurface", &"PanelContainer")
	theme.set_stylebox("panel", &"M3ChatSurface", _box_margins(card_bg, card_border, 12, 12, 10, 12, 10, 1))
	theme.set_stylebox("focus", &"M3ChatSurface", _box_margins(card_bg, primary, 12, 12, 10, 12, 10, 1))

	# NavBar (Top Bar) — Vibe subtle header styling with comfortable padding
	theme.set_type_variation(&"M3TopAppBar", &"PanelContainer")
	theme.set_stylebox("panel", &"M3TopAppBar", _box_margins(background, Color.TRANSPARENT, 0, 10, 4, 10, 4, 0))
	theme.set_stylebox("focus", &"M3TopAppBar", _box_margins(background, primary, 0, 10, 4, 10, 4, 1))

	# StatusBar — Vibe IDE status line with clean separation and padding
	theme.set_type_variation(&"M3StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", &"M3StatusBar", _box_margins(background, card_border, 0, 12, 4, 12, 4, 1))
	theme.set_stylebox("focus", &"M3StatusBar", _box_margins(background, primary, 0, 12, 4, 12, 4, 1))

	# Chat Composer Box (Floating Rounded Input Card - 100% Faithful to Reference Image)
	var composer_bg := Color("#1a1a1e") if not is_light else Color("#ffffff")
	var composer_border := Color("#2a2b34") if not is_light else Color("#d0d2d8")
	theme.set_type_variation(&"M3Composer", &"PanelContainer")
	theme.set_stylebox("panel", &"M3Composer", _box_margins(composer_bg, composer_border, 12, 12, 10, 12, 10, 1))
	theme.set_stylebox("focus", &"M3Composer", _box_margins(composer_bg, primary, 12, 12, 10, 12, 10, 1))

	# Transparent Borderless Input inside Composer Card
	theme.set_type_variation(&"M3ComposerInput", &"LineEdit")
	var transparent_input := StyleBoxEmpty.new()
	transparent_input.content_margin_left = 2
	transparent_input.content_margin_right = 2
	transparent_input.content_margin_top = 2
	transparent_input.content_margin_bottom = 2
	theme.set_stylebox("normal", &"M3ComposerInput", transparent_input)
	theme.set_stylebox("focus", &"M3ComposerInput", transparent_input)
	theme.set_stylebox("read_only", &"M3ComposerInput", transparent_input)
	theme.set_color("font_color", &"M3ComposerInput", on_surface)
	theme.set_color("font_placeholder_color", &"M3ComposerInput", on_variant)
	theme.set_font_size("font_size", &"M3ComposerInput", 13)

	# Rounded Pill Badges in Composer Bottom Row (Build ⌵ , Opus-4.5 ⌵)
	theme.set_type_variation(&"M3PillBadge", &"Button")
	var badge_bg := Color("#222329") if not is_light else Color("#e8eaee")
	var badge_border := Color("#2c2d38") if not is_light else Color("#d0d2d8")
	var badge_norm := _box_margins(badge_bg, badge_border, 12, 10, 4, 10, 4, 1)
	var badge_hov := _box_margins(badge_bg.lightened(0.08), primary, 12, 10, 4, 10, 4, 1)
	theme.set_stylebox("normal", &"M3PillBadge", badge_norm)
	theme.set_stylebox("hover", &"M3PillBadge", badge_hov)
	theme.set_stylebox("pressed", &"M3PillBadge", badge_norm)
	theme.set_stylebox("focus", &"M3PillBadge", badge_norm)
	theme.set_color("font_color", &"M3PillBadge", on_surface)
	theme.set_font_size("font_size", &"M3PillBadge", 12)

	# Composer Send Circle Button
	theme.set_type_variation(&"M3SendCircleBtn", &"Button")
	var send_circle_bg := Color("#282932") if not is_light else Color("#d0d2d9")
	var send_circle_norm := _box_margins(send_circle_bg, Color("#363744") if not is_light else Color("#c0c2cb"), 14, 6, 4, 6, 4, 1)
	var send_circle_hov := _box_margins(primary, Color.TRANSPARENT, 14, 6, 4, 6, 4, 0)
	theme.set_stylebox("normal", &"M3SendCircleBtn", send_circle_norm)
	theme.set_stylebox("hover", &"M3SendCircleBtn", send_circle_hov)
	theme.set_stylebox("pressed", &"M3SendCircleBtn", send_circle_norm)
	theme.set_stylebox("focus", &"M3SendCircleBtn", send_circle_norm)
	theme.set_color("font_color", &"M3SendCircleBtn", on_surface)

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

	# AppBrandButton in NavBar/NavRail: clean icon/logo button
	theme.set_type_variation(&"M3AppBrandButton", &"MenuButton")
	theme.set_stylebox("normal", &"M3AppBrandButton", transparent_nav)
	theme.set_stylebox("hover", &"M3AppBrandButton", _box_margins(container, Color.TRANSPARENT, 6, 4, 4, 4, 4))
	theme.set_stylebox("pressed", &"M3AppBrandButton", _box_margins(variant, Color.TRANSPARENT, 6, 4, 4, 4, 4))
	theme.set_stylebox("focus", &"M3AppBrandButton", transparent_nav)
	theme.set_color("font_color", &"M3AppBrandButton", primary)
	theme.set_color("font_hover_color", &"M3AppBrandButton", primary.lightened(0.2) if not is_light else primary.darkened(0.2))
	theme.set_font_size("font_size", &"M3AppBrandButton", 13)

	# ThemeToggleBtn in NavRail (Sun / Moon)
	theme.set_type_variation(&"M3ThemeToggle", &"Button")
	theme.set_stylebox("normal", &"M3ThemeToggle", transparent_nav)
	theme.set_stylebox("hover", &"M3ThemeToggle", _box_margins(container, Color.TRANSPARENT, 6, 4, 4, 4, 4))
	theme.set_stylebox("pressed", &"M3ThemeToggle", _box_margins(variant, Color.TRANSPARENT, 6, 4, 4, 4, 4))
	theme.set_stylebox("focus", &"M3ThemeToggle", transparent_nav)
	theme.set_color("font_color", &"M3ThemeToggle", on_surface)
	theme.set_color("font_hover_color", &"M3ThemeToggle", primary)
	theme.set_color("icon_normal_color", &"M3ThemeToggle", on_variant)
	theme.set_color("icon_hover_color", &"M3ThemeToggle", primary if is_light else Color.WHITE)
	theme.set_color("icon_pressed_color", &"M3ThemeToggle", primary)
	theme.set_font_size("font_size", &"M3ThemeToggle", 14)

	# Minimal Collapsible NavRail panel (Untitled UI style slim vertical bar)
	theme.set_type_variation(&"M3NavRail", &"PanelContainer")
	var rail_box := StyleBoxFlat.new()
	rail_box.bg_color = Color.TRANSPARENT
	rail_box.border_color = Color.TRANSPARENT
	rail_box.set_border_width_all(0)
	rail_box.content_margin_left = 6
	rail_box.content_margin_right = 6
	rail_box.content_margin_top = 4
	rail_box.content_margin_bottom = 4
	rail_box.anti_aliasing = true
	theme.set_stylebox("panel", &"M3NavRail", rail_box)

	# Minimal NavRail icon buttons
	theme.set_type_variation(&"M3RailButton", &"Button")
	var rail_btn_norm := _box_margins(Color.TRANSPARENT, Color.TRANSPARENT, 6, 6, 6, 6, 6)
	var rail_btn_hov := _box_margins(container, Color.TRANSPARENT, 6, 6, 6, 6, 6)
	var rail_btn_press := _box_margins(variant, Color.TRANSPARENT, 6, 6, 6, 6, 6)
	theme.set_stylebox("normal", &"M3RailButton", rail_btn_norm)
	theme.set_stylebox("hover", &"M3RailButton", rail_btn_hov)
	theme.set_stylebox("pressed", &"M3RailButton", rail_btn_press)
	theme.set_stylebox("focus", &"M3RailButton", rail_btn_norm)
	theme.set_color("font_color", &"M3RailButton", on_variant)
	theme.set_color("font_hover_color", &"M3RailButton", primary if is_light else Color.WHITE)
	theme.set_color("font_pressed_color", &"M3RailButton", primary)
	theme.set_color("icon_normal_color", &"M3RailButton", on_variant)
	theme.set_color("icon_hover_color", &"M3RailButton", primary if is_light else Color.WHITE)
	theme.set_color("icon_pressed_color", &"M3RailButton", primary)
	theme.set_font_size("font_size", &"M3RailButton", 14)

	# Active NavRail Pill Button Variation
	theme.set_type_variation(&"M3RailButtonActive", &"Button")
	var rail_active_bg := primary.darkened(0.70) if not is_light else primary.lightened(0.75)
	var rail_active_box := _box_margins(rail_active_bg, primary, 6, 6, 6, 6, 6, 1)
	theme.set_stylebox("normal", &"M3RailButtonActive", rail_active_box)
	theme.set_stylebox("hover", &"M3RailButtonActive", rail_active_box)
	theme.set_stylebox("pressed", &"M3RailButtonActive", rail_active_box)
	theme.set_stylebox("focus", &"M3RailButtonActive", rail_active_box)
	theme.set_color("font_color", &"M3RailButtonActive", primary if is_light else Color.WHITE)
	theme.set_color("icon_normal_color", &"M3RailButtonActive", primary if is_light else Color.WHITE)

	# NavDrawer pill items (e.g. Analytics, Explorer, Git)
	theme.set_type_variation(&"M3NavPillButton", &"Button")
	var pill_norm := _box_margins(Color.TRANSPARENT, Color.TRANSPARENT, 6, 10, 6, 10, 6)
	var pill_hov := _box_margins(container, Color.TRANSPARENT, 6, 10, 6, 10, 6)
	var pill_press := _box_margins(variant, Color.TRANSPARENT, 6, 10, 6, 10, 6)
	theme.set_stylebox("normal", &"M3NavPillButton", pill_norm)
	theme.set_stylebox("hover", &"M3NavPillButton", pill_hov)
	theme.set_stylebox("pressed", &"M3NavPillButton", pill_press)
	theme.set_stylebox("focus", &"M3NavPillButton", pill_norm)
	theme.set_color("font_color", &"M3NavPillButton", on_surface)
	theme.set_color("font_hover_color", &"M3NavPillButton", primary if is_light else Color.WHITE)
	theme.set_color("font_pressed_color", &"M3NavPillButton", primary)
	theme.set_font_size("font_size", &"M3NavPillButton", 13)

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
	tab_sel.content_margin_left = 10
	tab_sel.content_margin_right = 10
	tab_sel.content_margin_top = 4
	tab_sel.content_margin_bottom = 4
	tab_sel.corner_radius_top_left = 4
	tab_sel.corner_radius_top_right = 4
	tab_sel.anti_aliasing = true

	var tab_unsel := StyleBoxFlat.new()
	tab_unsel.bg_color = surface.darkened(0.12) if not is_light else surface.lightened(0.1)
	tab_unsel.border_color = Color.TRANSPARENT
	tab_unsel.content_margin_left = 10
	tab_unsel.content_margin_right = 10
	tab_unsel.content_margin_top = 4
	tab_unsel.content_margin_bottom = 4
	tab_unsel.corner_radius_top_left = 4
	tab_unsel.corner_radius_top_right = 4
	tab_unsel.anti_aliasing = true

	var tab_hov := StyleBoxFlat.new()
	tab_hov.bg_color = variant.darkened(0.15) if not is_light else variant.lightened(0.2)
	tab_hov.border_color = Color.TRANSPARENT
	tab_hov.content_margin_left = 10
	tab_hov.content_margin_right = 10
	tab_hov.content_margin_top = 4
	tab_hov.content_margin_bottom = 4
	tab_hov.corner_radius_top_left = 4
	tab_hov.corner_radius_top_right = 4
	tab_hov.anti_aliasing = true

	theme.set_stylebox("tab_selected", &"TabBar", tab_sel)
	theme.set_stylebox("tab_unselected", &"TabBar", tab_unsel)
	theme.set_stylebox("tab_hovered", &"TabBar", tab_hov)
	theme.set_color("font_selected_color", &"TabBar", on_surface)
	theme.set_color("font_unselected_color", &"TabBar", on_variant)
	theme.set_color("font_hovered_color", &"TabBar", on_surface)
	theme.set_font_size("font_size", &"TabBar", 12)
	theme.set_constant("tab_separation", &"TabBar", 4)
	theme.set_constant("h_separation", &"TabBar", 6)
	theme.set_constant("icon_max_width", &"TabBar", 14)

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
