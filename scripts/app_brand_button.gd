class_name AppBrandButton
extends MenuButton

## AppBrand menu button providing quick access to Dark/Light mode toggle, About, and Close.

const ID_LIGHT_MODE: int = 1
const ID_DARK_MODE: int = 2
const ID_ABOUT: int = 3
const ID_CLOSE: int = 4

var _theme_controller: ThemeController = null
var _on_theme_select_callback: Callable = Callable()
var _on_about_requested: Callable = Callable()
var _on_close_requested: Callable = Callable()
var _active_theme_getter: Callable = Callable()

func setup_with_callbacks(theme_getter: Callable, on_theme_change: Callable, on_about: Callable, on_close: Callable) -> void:
	_active_theme_getter = theme_getter
	_on_theme_select_callback = on_theme_change
	_on_about_requested = on_about
	_on_close_requested = on_close
	_rebuild_popup()
	var popup := get_popup()
	if not popup.id_pressed.is_connected(_on_popup_id_pressed):
		popup.id_pressed.connect(_on_popup_id_pressed)

func setup(controller: ThemeController, on_about: Callable, on_close: Callable) -> void:
	_theme_controller = controller
	_on_about_requested = on_about
	_on_close_requested = on_close
	_rebuild_popup()
	var popup := get_popup()
	if not popup.id_pressed.is_connected(_on_popup_id_pressed):
		popup.id_pressed.connect(_on_popup_id_pressed)

func update_menu_state() -> void:
	_rebuild_popup()

func _rebuild_popup() -> void:
	var popup := get_popup()
	popup.clear()
	var current_theme: String = ""
	if _active_theme_getter.is_valid():
		current_theme = str(_active_theme_getter.call())
	elif _theme_controller:
		current_theme = _theme_controller.active_theme
	else:
		current_theme = "adwaita_darker"

	var is_curr_light := ThemeColorScheme.is_light(current_theme)

	popup.add_radio_check_item("Dark Mode", ID_DARK_MODE)
	popup.set_item_checked(0, not is_curr_light)

	popup.add_radio_check_item("Light Mode", ID_LIGHT_MODE)
	popup.set_item_checked(1, is_curr_light)

	popup.add_separator()
	popup.add_item("About SSCodeIDE", ID_ABOUT)
	popup.add_item("Close", ID_CLOSE)

func _on_popup_id_pressed(id: int) -> void:
	match id:
		ID_DARK_MODE:
			var current := str(_active_theme_getter.call()) if _active_theme_getter.is_valid() else (_theme_controller.active_theme if _theme_controller else "adwaita_darker")
			if not ThemeColorScheme.is_light(current):
				return
			var target := ThemeColorScheme.get_dark_variant(current)
			if target.is_empty():
				target = "adwaita_darker"
			if _on_theme_select_callback.is_valid():
				_on_theme_select_callback.call(target)
			elif _theme_controller:
				_theme_controller.request_theme_change(target)
		ID_LIGHT_MODE:
			var current := str(_active_theme_getter.call()) if _active_theme_getter.is_valid() else (_theme_controller.active_theme if _theme_controller else "adwaita_darker")
			if ThemeColorScheme.is_light(current):
				return
			var target := ThemeColorScheme.get_light_variant(current)
			if target.is_empty():
				target = "adwaita_lighter"
			if _on_theme_select_callback.is_valid():
				_on_theme_select_callback.call(target)
			elif _theme_controller:
				_theme_controller.request_theme_change(target)
		ID_ABOUT:
			if _on_about_requested.is_valid():
				_on_about_requested.call()
		ID_CLOSE:
			if _on_close_requested.is_valid():
				_on_close_requested.call()
			else:
				get_tree().quit()
