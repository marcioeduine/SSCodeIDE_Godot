class_name EditorDialogController
extends RefCounted

## Manages dialogs and overlays

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

func ensure_overlay_dialog() -> void:
	if _e.overlay != null:
		return

	_e.overlay = ColorRect.new()
	_e.overlay.name = "Overlay"
	_e.overlay.visible = false
	_e.overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_e.overlay.color = Color(0, 0, 0, 0.55)
	_e.add_child(_e.overlay)

	_e.dialog_panel = PanelContainer.new()
	_e.dialog_panel.name = "DialogPanel"
	_e.dialog_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_e.dialog_panel.anchor_left = 0.5
	_e.dialog_panel.anchor_top = 0.05
	_e.dialog_panel.anchor_right = 0.5
	_e.dialog_panel.anchor_bottom = 0.95
	_e.dialog_panel.offset_left = -300.0
	_e.dialog_panel.offset_right = 300.0
	_e.overlay.add_child(_e.dialog_panel)

	var dialog_vbox = VBoxContainer.new()
	dialog_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_vbox.add_theme_constant_override("separation", 8)
	_e.dialog_panel.add_child(dialog_vbox)

	_e.dialog_title = Label.new()
	_e.dialog_title.text = "Config"
	dialog_vbox.add_child(_e.dialog_title)

	var dialog_scroll = ScrollContainer.new()
	dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_vbox.add_child(dialog_scroll)

	_e.dialog_body = RichTextLabel.new()
	_e.dialog_body.bbcode_enabled = true
	_e.dialog_body.fit_content = true
	_e.dialog_body.scroll_active = false
	_e.dialog_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_scroll.add_child(_e.dialog_body)

	_e.dialog_input_row = HBoxContainer.new()
	_e.dialog_input_row.visible = false
	_e.dialog_input_row.add_theme_constant_override("separation", 6)

	_e.dialog_input = LineEdit.new()
	_e.dialog_input.placeholder_text = "Enter value…"
	_e.dialog_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.dialog_input_row.add_child(_e.dialog_input)

	_e.dialog_action_btn = Button.new()
	_e.dialog_action_btn.theme_type_variation = &"M3FilledButton"
	_e.dialog_action_btn.text = "Confirm"
	_e.dialog_action_btn.pressed.connect(on_dialog_action_pressed)
	_e.dialog_input_row.add_child(_e.dialog_action_btn)
	dialog_vbox.add_child(_e.dialog_input_row)

	_e.dialog_close = Button.new()
	_e.dialog_close.theme_type_variation = &"M3TextButton"
	_e.dialog_close.text = "Close"
	_e.dialog_close.pressed.connect(hide_overlay)
	dialog_vbox.add_child(_e.dialog_close)


func show_overlay(title: String, body: String) -> void:
	ensure_overlay_dialog()
	_e.dialog_title.text = title
	_e.dialog_body.text = body
	_e.dialog_body.visible = true
	if _e.dialog_input_row:
		_e.dialog_input_row.visible = false
	_e.dialog_panel.visible = true
	_e.overlay.visible = true


func show_input_dialog(title: String, body: String, placeholder: String, default_val: String, btn_label: String, callback: Callable, secret: bool = false) -> void:
	ensure_overlay_dialog()
	_e.dialog_title.text = title
	_e.dialog_body.text = body
	_e.dialog_body.visible = true
	if _e.dialog_input_row:
		_e.dialog_input_row.visible = true
		_e.dialog_input.placeholder_text = placeholder
		_e.dialog_input.text = default_val
		_e.dialog_input.secret = secret
		_e.dialog_action_btn.text = btn_label
	_e.dialog_action_callback = callback
	_e.dialog_panel.visible = true
	_e.overlay.visible = true
	if _e.dialog_input:
		_e.dialog_input.grab_focus()
		_e.dialog_input.select_all()



func on_dialog_action_pressed() -> void:
	if _e.dialog_action_callback.is_valid():
		var val: String = _e.dialog_input.text.strip_edges() if _e.dialog_input else ""
		var cb: Callable = _e.dialog_action_callback
		_e.dialog_action_callback = Callable()
		hide_overlay()
		cb.call(val)
	else:
		hide_overlay()



func hide_overlay() -> void:
	_e.dialog_panel.visible = false
	_e.overlay.visible = false
	_e.dialog_action_callback = Callable()
	if _e.dialog_input:
		_e.dialog_input.secret = false
		_e.dialog_input.text = ""



func show_help() -> void:
	show_overlay("Help · Shortcuts", _e.HELP_TEXT)



func show_about() -> void:
	show_overlay("About", _e.ABOUT_TEXT)



func show_config() -> void:
	var key_state = "saved on this machine" if not AIService._read_stored_api_key().is_empty() else "not saved"
	if not OS.get_environment(AIService.NVIDIA_API_KEY_ENV).strip_edges().is_empty():
		key_state = "set via process environment"
	var body = "[b]Settings[/b]\n\n• [b]Typography:[/b] system interface font · FiraCode in editor\n• [b]Workspace:[/b] %s\n• [b]Active Model:[/b] %s (NVIDIA NIM)\n• [b]API key:[/b] %s\n• [b]Status:[/b] %s\n\nUse Config → NVIDIA NIM API key… to change the stored key." % [
		_e.workspace_root,
		_e.ai_provider.replace("_", " ").to_upper(),
		key_state,
		"Ready" if AIService.has_nvidia_api_key() else "API key required",
	]
	show_overlay("Settings", body)



func ensure_api_key(after: Callable) -> void:
	if AIService.has_nvidia_api_key():
		if after.is_valid():
			after.call()
		return
	prompt_api_key(false, after)



func prompt_api_key(force: bool, after: Callable) -> void:
	var existing = AIService._read_stored_api_key()
	var body = "The NVIDIA NIM API key is stored only on this machine (Godot user data) and is never committed with the project.\n\nPaste the key below. Leave empty and confirm to remove a stored key." if force else "To use the chat assistant you need an NVIDIA NIM API key.\n\nIt will be saved on this machine so you do not have to enter it again. You can change it later under Config → NVIDIA NIM API key…"
	show_input_dialog(
		"NVIDIA NIM API key",
		body,
		"nvapi-…",
		existing if force else "",
		"Save",
		func(val: String) -> void:
			if val.is_empty() and not force:
				show_toast("API key not set. Chat is unavailable until you add one.", true)
				return
			if not AIService.set_stored_nvidia_api_key(val):
				show_toast("Could not save the API key.", true)
				return
			if val.is_empty():
				show_toast("Stored API key removed.", false)
			else:
				show_toast("API key saved.", false)
			_e.chat.update_ai_status()
	)
	if after.is_valid() and AIService.has_nvidia_api_key():
		after.call()



func show_toast(message: String, is_warning: bool = true) -> void:
	send_os_notification("SSCodeIDE", message, is_warning)



func send_os_notification(title: String, body: String, is_warning: bool = false) -> void:
	## Native desktop notification. Auto-dismiss after _e.OS_NOTIFY_EXPIRE_MS.
	## GNOME ignores expire-time for urgency=critical, so warnings stay "normal"
	## and transient; CloseNotification is issued after the timeout.
	var icon = "dialog-information" if not is_warning else "dialog-warning"
	var expire_s = float(_e.OS_NOTIFY_EXPIRE_MS) / 1000.0
	match OS.get_name():
		"Linux", "FreeBSD", "OpenBSD", "NetBSD":
			OS.execute("notify-send", [
				"--urgency=normal",
				"--icon=" + icon,
				"--app-name=SSCodeIDE",
				"--hint=int:transient:1",
				"--hint=int:resident:0",
				"--replace-id=" + str(_e.OS_NOTIFY_REPLACE_ID),
				"--expire-time=" + str(_e.OS_NOTIFY_EXPIRE_MS),
				title, body
			])
		"macOS":
			var script = "display notification \"%s\" with title \"%s\"" % [
				body.replace("\"", "'"), title.replace("\"", "'")
			]
			OS.execute("osascript", ["-e", script])
		"Windows":
			var ps_cmd = (
				"[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null;" +
				"$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);" +
				"$xml.GetElementsByTagName('text')[0].InnerText = '%s';" % title.replace("'", "`'") +
				"$xml.GetElementsByTagName('text')[1].InnerText = '%s';" % body.replace("'", "`'") +
				"$toast = New-Object Windows.UI.Notifications.ToastNotification($xml);" +
				"$toast.ExpirationTime = [DateTimeOffset]::Now.AddMilliseconds(%d);" % _e.OS_NOTIFY_EXPIRE_MS +
				"[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('SSCodeIDE').Show($toast)"
			)
			OS.execute("powershell", ["-WindowStyle", "Hidden", "-Command", ps_cmd])
	_e.os_notify_generation += 1
	var gen = _e.os_notify_generation
	_e.get_tree().create_timer(expire_s).timeout.connect(func() -> void:
		if gen == _e.os_notify_generation:
			dismiss_os_notification()
	)



func dismiss_os_notification() -> void:
	match OS.get_name():
		"Linux", "FreeBSD", "OpenBSD", "NetBSD":
			OS.execute("gdbus", [
				"call", "--session",
				"--dest", "org.freedesktop.Notifications",
				"--object-path", "/org/freedesktop/Notifications",
				"--method", "org.freedesktop.Notifications.CloseNotification",
				str(_e.OS_NOTIFY_REPLACE_ID)
			])
		_:
			pass



func get_open_file_dlg() -> FileDialog:
	if _e.open_file_dlg == null:
		_e.open_file_dlg = FileDialog.new()
		_e.open_file_dlg.title = "Open a File"
		_e.open_file_dlg.size = Vector2i(800, 520)
		_e.open_file_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_e.open_file_dlg.access = FileDialog.ACCESS_FILESYSTEM
		_e.open_file_dlg.file_selected.connect(_e.files.open_path)
		_e.add_child(_e.open_file_dlg)
	return _e.open_file_dlg



func get_open_dir_dlg() -> FileDialog:
	if _e.open_dir_dlg == null:
		_e.open_dir_dlg = FileDialog.new()
		_e.open_dir_dlg.title = "Open a Directory"
		_e.open_dir_dlg.size = Vector2i(800, 520)
		_e.open_dir_dlg.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		_e.open_dir_dlg.access = FileDialog.ACCESS_FILESYSTEM
		_e.open_dir_dlg.dir_selected.connect(_e.files.on_dir_selected)
		_e.add_child(_e.open_dir_dlg)
	return _e.open_dir_dlg



func get_save_as_dlg() -> FileDialog:
	if _e.save_as_dlg == null:
		_e.save_as_dlg = FileDialog.new()
		_e.save_as_dlg.title = "Save As"
		_e.save_as_dlg.size = Vector2i(800, 520)
		_e.save_as_dlg.access = FileDialog.ACCESS_FILESYSTEM
		_e.save_as_dlg.file_selected.connect(_e.files.save_as_path)
		_e.add_child(_e.save_as_dlg)
	return _e.save_as_dlg



func get_open_theme_xml_dlg() -> FileDialog:
	if _e.open_theme_xml_dlg == null:
		_e.open_theme_xml_dlg = FileDialog.new()
		_e.open_theme_xml_dlg.title = "Open Theme XML"
		_e.open_theme_xml_dlg.size = Vector2i(800, 520)
		_e.open_theme_xml_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_e.open_theme_xml_dlg.access = FileDialog.ACCESS_FILESYSTEM
		_e.open_theme_xml_dlg.filters = PackedStringArray(["*.xml ; Theme XML files"])
		_e.open_theme_xml_dlg.file_selected.connect(_e.themes.import_theme_from_xml)
		_e.add_child(_e.open_theme_xml_dlg)
	return _e.open_theme_xml_dlg



func import_theme_xml_dialog() -> void:
	## Opens a file picker to select a .xml theme file for import
	get_open_theme_xml_dlg().popup_centered(Vector2i(800, 500))



