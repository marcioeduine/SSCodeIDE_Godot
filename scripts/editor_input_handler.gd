class_name EditorInputHandler
extends RefCounted

## Handles global shortcuts, unhandled inputs, and code editor GUI inputs

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

func handle_input(event: InputEvent) -> void:
	## ESC must run before CodeEdit consumes it, so the editor can lose focus
	## and subsequent shortcuts reach `handle_unhandled_input`.
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.keycode != KEY_ESCAPE:
		return
	handle_escape()
	_e.get_viewport().set_input_as_handled()


func handle_escape() -> void:
	if _e._find_row.visible:
		_e._find_row.visible = false
		return
	if _e._chat_suggestions_popup.visible:
		_e._chat_suggestions_popup.visible = false
		return
	if _e._dialog_panel.visible:
		_e._hide_overlay()
		return
	if _e._ai_busy:
		_e.chat.cancel_ai_request()
		return
	_e.get_viewport().gui_release_focus()


func handle_unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	var ctrl: bool = key.ctrl_pressed
	var shift: bool = key.shift_pressed
	var alt: bool = key.alt_pressed
	if key.keycode == KEY_DELETE and _e._file_tree.has_focus():
		_e.files.delete_selected_file()
		_e.get_viewport().set_input_as_handled()
		return

	# Code completion (Ctrl+Space)
	if ctrl and key.keycode == KEY_SPACE:
		_e._update_code_completion()
		_e._code_edit.request_code_completion(true)
		_e.get_viewport().set_input_as_handled()
		return

	# Help / Shortcuts (F1)
	if key.keycode == KEY_F1:
		_e.dialog.show_help()
		_e.get_viewport().set_input_as_handled()
		return

	# Settings (Ctrl+,)
	if ctrl and key.keycode == KEY_COMMA:
		_e.dialog.show_config()
		_e.get_viewport().set_input_as_handled()
		return

	# Git & GitHub Operations (Ctrl+Shift+G / C / U / L)
	if ctrl and shift and key.keycode == KEY_G:
		_e.git.show_git_status_dialog()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_C:
		_e.git.generate_smart_commit()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_U:
		_e.git.git_push()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_L:
		_e.git.git_pull()
		_e.get_viewport().set_input_as_handled()
		return

	# File Operations
	if ctrl and shift and key.keycode == KEY_O:
		_e.dialog.get_open_dir_dlg().popup_centered()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_O:
		_e.dialog.get_open_file_dlg().popup_centered()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_S:
		_e.dialog.get_save_as_dlg().popup_centered()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_S:
		_e.files.save_active()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_N:
		_e.files.open_untitled()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_W:
		if _e._active_index >= 0:
			_e.files.on_tab_close(_e._active_index)
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_Q:
		_e.get_tree().quit()
		_e.get_viewport().set_input_as_handled()
		return

	# Tab Navigation (Ctrl+Tab / Ctrl+Shift+Tab)
	if ctrl and shift and key.keycode == KEY_TAB:
		_e.files.switch_tab(-1)
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_TAB:
		_e.files.switch_tab(1)
		_e.get_viewport().set_input_as_handled()
		return

	# Panels & Focus Navigation
	if ctrl and not shift and key.keycode == KEY_B:
		_e._toggle_explorer()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_B:
		_e._toggle_chat()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and (key.keycode == KEY_J or key.keycode == KEY_K or key.keycode == KEY_QUOTELEFT):
		if _e._chat_collapsed:
			_e._toggle_chat()
		_e._chat_input.grab_focus()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_P:
		if _e._explorer_collapsed:
			_e._toggle_explorer()
		_e._file_tree.grab_focus()
		_e.get_viewport().set_input_as_handled()
		return

	# Find & Replace (Ctrl+F)
	if ctrl and key.keycode == KEY_F:
		_e._find_row.visible = true
		_e._find_input.grab_focus()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_H:
		_e._find_row.visible = true
		_e._replace_input.visible = true
		_e._replace_all.visible = true
		_e._find_input.grab_focus()
		_e.get_viewport().set_input_as_handled()
		return

	# Go to Line (Ctrl+G)
	if ctrl and key.keycode == KEY_G:
		_e._chat_input.text = "/goto "
		_e._chat_input.grab_focus()
		_e._chat_input.caret_column = _e._chat_input.text.length()
		_e.get_viewport().set_input_as_handled()
		return

	# Code Editing Shortcuts
	if ctrl and key.keycode == KEY_SLASH:
		_e.files.toggle_comment()
		_e.get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_D:
		_e.files.duplicate_line()
		_e.get_viewport().set_input_as_handled()
		return
	if alt and key.keycode == KEY_UP:
		_e.files.move_line(-1)
		_e.get_viewport().set_input_as_handled()
		return
	if alt and key.keycode == KEY_DOWN:
		_e.files.move_line(1)
		_e.get_viewport().set_input_as_handled()
		return


func on_code_editor_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.ctrl_pressed and key.keycode == KEY_F:
		_e._find_row.visible = true
		_e._find_input.grab_focus()
		_e.get_viewport().set_input_as_handled()
	elif key.ctrl_pressed and key.keycode == KEY_H:
		_e._find_row.visible = true
		_e._replace_input.visible = true
		_e._replace_all.visible = true
		_e._find_input.grab_focus()
		_e.get_viewport().set_input_as_handled()
