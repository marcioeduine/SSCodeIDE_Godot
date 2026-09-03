class_name AppBrandButton
extends MenuButton

## AppBrand menu button providing quick access to Dark/Light mode toggle, About, and Close.

const ID_ABOUT: int = 1
const ID_CLOSE: int = 2

var _on_about_requested: Callable = Callable()
var _on_close_requested: Callable = Callable()

func setup_with_callbacks(_theme_getter: Callable, _on_theme_change: Callable, on_about: Callable, on_close: Callable) -> void:
	_on_about_requested = on_about
	_on_close_requested = on_close
	_rebuild_popup()
	var popup := get_popup()
	if not popup.id_pressed.is_connected(_on_popup_id_pressed):
		popup.id_pressed.connect(_on_popup_id_pressed)

func setup(_controller: ThemeController, on_about: Callable, on_close: Callable) -> void:
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
	popup.add_item("About SSCodeIDE", ID_ABOUT)
	popup.add_item("Close", ID_CLOSE)

func _on_popup_id_pressed(id: int) -> void:
	match id:
		ID_ABOUT:
			if _on_about_requested.is_valid():
				_on_about_requested.call()
		ID_CLOSE:
			if _on_close_requested.is_valid():
				_on_close_requested.call()
			else:
				get_tree().quit()
