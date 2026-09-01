extends Control

## SSCodeIDE — root controller. All nodes live in ui_editor.tscn.

@onready var _file_tree: Tree = $RootVBox/MainSplit/ExplorerPane/FileTree
@onready var _tab_bar: TabBar = $RootVBox/MainSplit/CenterSplit/EditorPane/TabBar
@onready var _code_edit: CodeEdit = $RootVBox/MainSplit/CenterSplit/EditorPane/CodeEdit
@onready var _chat_log: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatLog
@onready var _chat_input: LineEdit = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputRow/ChatInput
@onready var _chat_send: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputRow/ChatSend
@onready var _status_left: Label = $RootVBox/StatusBar/StatusRow/StatusLeft
@onready var _status_cursor: Label = $RootVBox/StatusBar/StatusRow/StatusCursor
@onready var _status_lang: Label = $RootVBox/StatusBar/StatusRow/StatusLang
@onready var _status_enc: Label = $RootVBox/StatusBar/StatusRow/StatusEnc
@onready var _status_ai: Label = $RootVBox/StatusBar/StatusRow/StatusAI
@onready var _nav_workspace: Label = $RootVBox/NavBar/NavWorkspace
@onready var _main_split: HSplitContainer = $RootVBox/MainSplit
@onready var _center_split: HSplitContainer = $RootVBox/MainSplit/CenterSplit
@onready var _file_menu: PopupMenu = $RootVBox/NavBar/MenuBar/File
@onready var _edit_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Edit
@onready var _config_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Config
@onready var _help_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Help
@onready var _about_menu: PopupMenu = $RootVBox/NavBar/MenuBar/About
@onready var _open_file_dlg: FileDialog = $OpenFileDialog
@onready var _open_dir_dlg: FileDialog = $OpenDirDialog
@onready var _save_as_dlg: FileDialog = $SaveAsDialog
@onready var _overlay: ColorRect = $Overlay
@onready var _dialog_panel: PanelContainer = $Overlay/DialogPanel
@onready var _dialog_title: Label = $Overlay/DialogPanel/DialogVBox/DialogTitle
@onready var _dialog_body: RichTextLabel = $Overlay/DialogPanel/DialogVBox/DialogBody
@onready var _dialog_close: Button = $Overlay/DialogPanel/DialogVBox/DialogClose
@onready var _toast_panel: PanelContainer = $ToastPanel
@onready var _toast_label: RichTextLabel = $ToastPanel/ToastMargin/ToastLabel
@onready var _ai_chat_http: HTTPRequest = $AIChatHttp
@onready var _provider_select: OptionButton = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ProviderSelect
@onready var _chat_login_btn: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatLoginBtn
@onready var _find_row: HBoxContainer = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow
@onready var _find_input: LineEdit = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindInput
@onready var _find_next: Button = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindNext
@onready var _find_close: Button = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindClose

var _nerd_font: FontFile
var _workspace_root: String = ""
var _open_files: Array[Dictionary] = []
var _active_index: int = -1
var _suppress_tab: bool = false
var _ai_busy: bool = false
var _toast_tween: Tween = null
var _ai_provider: String = "nemotron"
var _ai_logged: Dictionary = {"nemotron": true, "nemotron_lightning": true, "kimi_k3": true, "deepseek_v4": true, "laguna": true}
var _current_prompt: String = ""
var _model_candidates: Array[String] = []
var _model_candidate_index: int = 0

const HELP_TEXT := """[b]Atalhos SSCodeIDE[/b]

[b]Ficheiro[/b]
  Ctrl+N            Novo ficheiro
  Ctrl+O            Abrir ficheiro
  Ctrl+Shift+O      Abrir directório
  Ctrl+S            Gravar
  Ctrl+Shift+S      Gravar como
  Ctrl+W            Fechar separador
  Ctrl+Tab          Próximo separador
  Ctrl+Shift+Tab    Separador anterior
  Ctrl+Q            Sair

[b]Edição[/b]
  Ctrl+Z / Ctrl+Y   Undo / Redo
  Ctrl+X / C / V    Cortar / Copiar / Colar
  Ctrl+A            Seleccionar tudo
  Ctrl+F            Procurar
  Ctrl+G            Ir para linha (usa Find)
  Ctrl+/            Comentar linha
  Ctrl+D            Duplicar linha
  Alt+↑ / Alt+↓     Mover linha

[b]IDE[/b]
  Ctrl+,            Config
  Ctrl+L            Login IA (WebView modal, página oficial)
  F1                Ajuda (atalhos)
  Ctrl+P            Foco no explorador
"""

const ABOUT_TEXT := """[b]SSCodeIDE[/b]
IDE em 100% GDScript nativo (Godot 4.7) — tema Monokai Pro.

Fonte padrão: FiraCode Nerd Font
Chat IA: Nemotron · Kimi K3 · DeepSeek V4 · Laguna Code via NVIDIA NIM API
Toast automático · Cancelamento instantâneo · Fallback inteligente

© SSDevTools
"""


func _ready() -> void:
	_nerd_font = FontFile.new()
	_nerd_font.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/FiraCodeNerdFont-Regular.ttf"))
	_workspace_root = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	_nav_workspace.text = "SSCodeIDE  ·  %s" % _workspace_root.get_file()
	_load_ai_config()
	_apply_monokai_pro_theme()
	_wire_signals()
	_configure_code_edit()
	_refresh_file_tree()
	_open_untitled()
	_update_ai_status()
	_status_left.text = "READY"
	_status_enc.text = "UTF-8"
	call_deferred("_apply_split_offsets")


func _apply_split_offsets() -> void:
	var w: float = size.x
	if w <= 1.0:
		w = get_viewport_rect().size.x
	_main_split.split_offset = int(w * 0.18)
	_center_split.split_offset = int(w * 0.50)


func _wire_signals() -> void:
	_file_tree.item_activated.connect(_on_tree_item_activated)
	_file_tree.item_selected.connect(_on_tree_item_selected)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_tab_bar.tab_close_pressed.connect(_on_tab_close)
	_code_edit.text_changed.connect(_on_code_changed)
	_code_edit.caret_changed.connect(_on_caret_changed)
	_chat_input.text_submitted.connect(_on_chat_submitted)
	_chat_input.text_changed.connect(_on_chat_input_text_changed)
	_chat_send.pressed.connect(_on_chat_send_pressed)
	_file_menu.id_pressed.connect(_on_file_menu)
	_edit_menu.id_pressed.connect(_on_edit_menu)
	_config_menu.id_pressed.connect(_on_config_menu)
	_help_menu.id_pressed.connect(_on_help_menu)
	_about_menu.id_pressed.connect(_on_about_menu)
	_open_file_dlg.file_selected.connect(_open_path)
	_open_dir_dlg.dir_selected.connect(_on_dir_selected)
	_save_as_dlg.file_selected.connect(_save_as_path)
	_dialog_close.pressed.connect(_hide_overlay)
	_ai_chat_http.request_completed.connect(_on_ai_chat_http_completed)
	_chat_login_btn.pressed.connect(_show_login)
	_provider_select.item_selected.connect(_on_provider_selected)
	_find_input.text_submitted.connect(_do_find)
	_find_next.pressed.connect(_on_find_next)
	_find_close.pressed.connect(func() -> void: _find_row.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	var ctrl: bool = key.ctrl_pressed
	var shift: bool = key.shift_pressed
	var alt: bool = key.alt_pressed
	if key.keycode == KEY_ESCAPE and _ai_busy:
		_cancel_ai_request()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F1:
		_show_help()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_COMMA:
		_show_config()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_L:
		_show_login()
		get_viewport().set_input_as_handled()
	elif ctrl and shift and key.keycode == KEY_O:
		_open_dir_dlg.popup_centered()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_O:
		_open_file_dlg.popup_centered()
		get_viewport().set_input_as_handled()
	elif ctrl and shift and key.keycode == KEY_S:
		_save_as_dlg.popup_centered()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_S:
		_save_active()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_N:
		_open_untitled()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_W:
		if _active_index >= 0:
			_on_tab_close(_active_index)
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_Q:
		get_tree().quit()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_F:
		_find_row.visible = true
		_find_input.grab_focus()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_P:
		_file_tree.grab_focus()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_SLASH:
		_toggle_comment()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_D:
		_duplicate_line()
		get_viewport().set_input_as_handled()
	elif alt and key.keycode == KEY_UP:
		_move_line(-1)
		get_viewport().set_input_as_handled()
	elif alt and key.keycode == KEY_DOWN:
		_move_line(1)
		get_viewport().set_input_as_handled()


func _on_file_menu(id: int) -> void:
	match id:
		0: _open_file_dlg.popup_centered()
		1: _open_dir_dlg.popup_centered()
		3: _open_untitled()
		4: _save_active()
		5: _save_as_dlg.popup_centered()
		7: get_tree().quit()


func _on_edit_menu(id: int) -> void:
	match id:
		0: _code_edit.undo()
		1: _code_edit.redo()
		3: _code_edit.cut()
		4: _code_edit.copy()
		5: _code_edit.paste()
		6: _code_edit.select_all()
		7:
			_find_row.visible = true
			_find_input.grab_focus()


func _on_config_menu(id: int) -> void:
	match id:
		0: _show_config()
		1: _show_login()


func _on_help_menu(_id: int) -> void:
	_show_help()


func _on_about_menu(_id: int) -> void:
	_show_about()


func _show_overlay(title: String, body: String) -> void:
	_dialog_title.text = title
	_dialog_body.text = body
	_dialog_body.visible = true
	_dialog_panel.visible = true
	_overlay.visible = true


func _hide_overlay() -> void:
	_dialog_panel.visible = false
	_overlay.visible = false


func _show_help() -> void:
	_show_overlay("Help · Shortcuts", HELP_TEXT)


func _show_about() -> void:
	_show_overlay("About", ABOUT_TEXT)


func _show_config() -> void:
	var body := "[b]Config[/b]\n\nFonte: FiraCode Nerd Font (padrão)\nWorkspace: %s\nModelo Ativo: %s (NVIDIA NIM)\nEstado API: Conectado e Ativo" % [
		_workspace_root,
		_ai_provider.replace("_", " ").to_upper(),
	]
	_show_overlay("Config", body)


func _show_login() -> void:
	_append_chat("NVIDIA", "NVIDIA NIM API ativa com a chave de API configurada.\nModelos disponíveis: Nemotron 3 Omni, Nemotron 3.5 Lightning, Kimi K3, DeepSeek V4 e Laguna Code.\nPodes enviar perguntas diretamente no chat.", Color("#a9dc76"))


func _start_provider_oauth() -> void:
	_show_login()


func _on_provider_selected(index: int) -> void:
	if _ai_busy:
		_cancel_ai_request()
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	if index >= 0 and index < names.size():
		_ai_provider = names[index]
	_chat_send.text = "Enviar"
	_save_ai_config()
	_update_ai_status()


func _load_ai_config() -> void:
	_provider_select.clear()
	_provider_select.add_item("Nemotron 3 Omni (NVIDIA)")
	_provider_select.add_item("Nemotron 3.5 Lightning (NVIDIA)")
	_provider_select.add_item("Kimi K3 (NVIDIA)")
	_provider_select.add_item("DeepSeek V4 (NVIDIA)")
	_provider_select.add_item("Laguna Code (NVIDIA)")
	var cfg := ConfigFile.new()
	if cfg.load("user://ai_config.cfg") == OK:
		_ai_provider = str(cfg.get_value("ai", "provider", "nemotron"))
	else:
		_ai_provider = "nemotron"
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	for p: String in names:
		_ai_logged[p] = true
	var idx: int = names.find(_ai_provider)
	if idx < 0:
		idx = 0
		_ai_provider = "nemotron"
	_provider_select.select(idx)
	_chat_send.text = "Enviar"


func _save_ai_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ai", "provider", _ai_provider)
	for p: String in ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]:
		cfg.set_value("ai", p + "_logged", true)
	cfg.save("user://ai_config.cfg")


func _update_ai_status() -> void:
	var titles := {
		"nemotron": "Nemotron 3 Omni",
		"nemotron_lightning": "Nemotron 3.5 Lightning",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_ai_provider, "Nemotron 3 Omni")
	_status_ai.text = "AI: %s · on" % display_title
	_chat_login_btn.text = "NVIDIA"
	_chat_input.placeholder_text = "Pergunta ao %s…" % display_title


func _apply_monokai_pro_theme() -> void:
	## Monokai Pro color palette
	var bg := Color("#2d2a2e")
	var bg_darker := Color("#221f22")
	var bg_lighter := Color("#3b3a3c")
	var fg := Color("#fcfcfa")
	var muted := Color("#939293")
	var accent := Color("#ffd866")
	var green := Color("#a9dc76")
	var red := Color("#ff6188")
	var cyan := Color("#78dce8")

	## Background
	$Background.color = bg_darker

	## NavBar
	var nav_bar: HBoxContainer = $RootVBox/NavBar
	var nav_sb := StyleBoxFlat.new()
	nav_sb.bg_color = bg_darker
	nav_bar.add_theme_stylebox_override("panel", nav_sb)
	_nav_workspace.add_theme_color_override("font_color", accent)

	## Explorer
	var explorer_header: Label = $RootVBox/MainSplit/ExplorerPane/ExplorerHeader
	explorer_header.add_theme_color_override("font_color", muted)
	var explorer_sb := StyleBoxFlat.new()
	explorer_sb.bg_color = bg_darker
	$RootVBox/MainSplit/ExplorerPane.add_theme_stylebox_override("panel", explorer_sb)
	_file_tree.add_theme_color_override("font_color", fg)
	_file_tree.add_theme_color_override("font_selected_color", accent)
	var tree_bg_sb := StyleBoxFlat.new()
	tree_bg_sb.bg_color = bg_darker
	_file_tree.add_theme_stylebox_override("panel", tree_bg_sb)

	## CodeEdit — Monokai Pro editor
	_code_edit.add_theme_color_override("background_color", bg)
	_code_edit.add_theme_color_override("font_color", fg)
	_code_edit.add_theme_color_override("current_line_color", Color("#363337"))
	_code_edit.add_theme_color_override("selection_color", Color("#4a4548"))
	_code_edit.add_theme_color_override("line_number_color", Color("#5b595c"))
	_code_edit.add_theme_color_override("caret_color", fg)
	_code_edit.add_theme_color_override("word_highlighted_color", Color("#4a4548"))
	_code_edit.add_theme_color_override("brace_mismatch_color", red)

	## TabBar
	_tab_bar.add_theme_color_override("font_selected_color", fg)
	_tab_bar.add_theme_color_override("font_unselected_color", muted)

	## Chat pane — Copilot-style
	_chat_log.add_theme_color_override("default_color", fg)
	_chat_input.add_theme_color_override("font_color", fg)
	_chat_input.add_theme_color_override("font_placeholder_color", muted)

	var chat_input_sb := StyleBoxFlat.new()
	chat_input_sb.bg_color = bg_lighter
	chat_input_sb.border_color = Color("#4a4548")
	chat_input_sb.set_border_width_all(1)
	chat_input_sb.set_corner_radius_all(6)
	chat_input_sb.set_content_margin_all(8)
	_chat_input.add_theme_stylebox_override("normal", chat_input_sb)
	var chat_input_focus_sb := chat_input_sb.duplicate()
	chat_input_focus_sb.border_color = accent
	_chat_input.add_theme_stylebox_override("focus", chat_input_focus_sb)

	var send_sb := StyleBoxFlat.new()
	send_sb.bg_color = accent
	send_sb.set_corner_radius_all(6)
	send_sb.set_content_margin_all(6)
	_chat_send.add_theme_stylebox_override("normal", send_sb)
	_chat_send.add_theme_stylebox_override("hover", send_sb)
	_chat_send.add_theme_stylebox_override("pressed", send_sb)
	_chat_send.add_theme_color_override("font_color", bg_darker)
	_chat_send.add_theme_color_override("font_hover_color", bg_darker)
	_chat_send.add_theme_color_override("font_pressed_color", bg_darker)

	## Chat header
	var chat_header: Label = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatHeader
	chat_header.add_theme_color_override("font_color", muted)

	## Status bar — Monokai Pro
	var status_sb := StyleBoxFlat.new()
	status_sb.bg_color = bg_darker
	$RootVBox/StatusBar.add_theme_stylebox_override("panel", status_sb)
	_status_left.add_theme_color_override("font_color", green)
	_status_cursor.add_theme_color_override("font_color", muted)
	_status_lang.add_theme_color_override("font_color", muted)
	_status_enc.add_theme_color_override("font_color", muted)
	_status_ai.add_theme_color_override("font_color", cyan)

	## Login button
	var login_sb := StyleBoxFlat.new()
	login_sb.bg_color = bg_lighter
	login_sb.set_corner_radius_all(4)
	login_sb.set_content_margin_all(4)
	_chat_login_btn.add_theme_stylebox_override("normal", login_sb)
	_chat_login_btn.add_theme_stylebox_override("hover", login_sb)
	_chat_login_btn.add_theme_color_override("font_color", green)

	## Provider select dropdown
	var provider_sb := StyleBoxFlat.new()
	provider_sb.bg_color = bg_lighter
	provider_sb.set_corner_radius_all(4)
	provider_sb.set_content_margin_all(4)
	_provider_select.add_theme_stylebox_override("normal", provider_sb)
	_provider_select.add_theme_color_override("font_color", fg)

	## Apply font everywhere
	if _nerd_font:
		for node: Control in [_code_edit, _file_tree, _chat_log, _chat_input,
				_status_left, _status_cursor, _status_lang, _status_enc,
				_status_ai, _nav_workspace, chat_header, explorer_header]:
			node.add_theme_font_override("font", _nerd_font)
		_code_edit.add_theme_font_size_override("font_size", 14)
		_chat_log.add_theme_font_size_override("normal_font_size", 13)
		_chat_input.add_theme_font_size_override("font_size", 13)


func _configure_code_edit() -> void:
	_code_edit.syntax_highlighter = _create_monokai_highlighter()
	_code_edit.draw_tabs = true
	_code_edit.draw_spaces = false
	_code_edit.indent_size = 4
	_code_edit.indent_use_spaces = false
	_code_edit.auto_brace_completion_enabled = true


func _create_monokai_highlighter() -> CodeHighlighter:
	var hl := CodeHighlighter.new()
	## Monokai Pro syntax colors
	hl.number_color = Color("#ab9df2")         # Purple — numbers
	hl.symbol_color = Color("#ff6188")         # Red/Pink — operators & symbols
	hl.function_color = Color("#a9dc76")       # Green — functions
	hl.member_variable_color = Color("#78dce8") # Cyan — member vars
	hl.add_color_region("#", "", Color("#727072"), true)  # Comments
	hl.add_color_region('"', '"', Color("#ffd866"))       # Strings — Yellow
	hl.add_color_region("'", "'", Color("#ffd866"))
	hl.add_color_region('"""', '"""', Color("#ffd866"))
	var kws := [
		"extends", "class_name", "var", "const", "func", "static", "signal", "enum",
		"if", "elif", "else", "for", "while", "match", "return", "pass", "break",
		"continue", "await", "self", "void", "int", "float", "bool", "String",
		"Vector2", "Vector3", "Color", "Array", "Dictionary", "true", "false", "null",
		"@onready", "@export", "preload", "load", "print", "push_error", "in", "not",
		"and", "or", "is", "as", "class", "super", "get", "set",
	]
	for kw in kws:
		hl.add_keyword_color(kw, Color("#ff6188"))  # Red/Pink — keywords
	## Type keywords in cyan
	var types := ["int", "float", "bool", "String", "Vector2", "Vector3", "Color",
		"Array", "Dictionary", "void", "PackedStringArray", "PackedByteArray",
		"Variant", "Error", "NodePath", "StringName"]
	for t in types:
		hl.add_keyword_color(t, Color("#78dce8"))
	## Built-in constants in purple
	for c in ["true", "false", "null", "self", "PI", "TAU", "INF", "NAN"]:
		hl.add_keyword_color(c, Color("#ab9df2"))
	return hl


func _refresh_file_tree() -> void:
	_file_tree.clear()
	var root_item: TreeItem = _file_tree.create_item()
	root_item.set_text(0, _workspace_root.get_file())
	_file_tree.set_column_title(0, "Files")
	_populate_tree_dir(root_item, _workspace_root)


func _populate_tree_dir(parent_item: TreeItem, dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	var dirs: Array[String] = []
	var files: Array[String] = []
	while fname != "":
		if not fname.begins_with("."):
			if dir.current_is_dir():
				dirs.append(fname)
			else:
				files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	dirs.sort()
	files.sort()
	for d in dirs:
		var item: TreeItem = _file_tree.create_item(parent_item)
		item.set_text(0, "📁 " + d)
		item.set_metadata(0, {"path": dir_path.path_join(d), "is_dir": true})
		item.collapsed = true
		_populate_tree_dir(item, dir_path.path_join(d))
	for f in files:
		var item: TreeItem = _file_tree.create_item(parent_item)
		var icon_glyph: String = FileKind.icon_for_path(f)
		item.set_text(0, icon_glyph + " " + f)
		item.set_metadata(0, {"path": dir_path.path_join(f), "is_dir": false})


func _on_tree_item_activated() -> void:
	var item: TreeItem = _file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and not meta.get("is_dir", false):
		_open_path(str(meta.get("path", "")))


func _on_tree_item_selected() -> void:
	var item: TreeItem = _file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		item.collapsed = not item.collapsed


func _open_untitled() -> void:
	var info := {
		"path": "",
		"title": "untitled",
		"content": "",
		"dirty": false,
		"cursor_line": 0,
		"cursor_col": 0,
	}
	_open_files.append(info)
	_tab_bar.add_tab("untitled")
	_active_index = _open_files.size() - 1
	_tab_bar.current_tab = _active_index
	_load_active_into_editor()


func _open_path(path: String) -> void:
	for i in range(_open_files.size()):
		if _open_files[i].get("path") == path:
			_active_index = i
			_tab_bar.current_tab = i
			_load_active_into_editor()
			return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		_status_left.text = "ERR: Cannot open " + path.get_file()
		return
	var content: String = f.get_as_text()
	var title: String = path.get_file()
	var info := {
		"path": path,
		"title": title,
		"content": content,
		"dirty": false,
		"cursor_line": 0,
		"cursor_col": 0,
	}
	_open_files.append(info)
	_tab_bar.add_tab(title)
	_active_index = _open_files.size() - 1
	_tab_bar.current_tab = _active_index
	_load_active_into_editor()
	_status_left.text = "OPEN: " + title


func _load_active_into_editor() -> void:
	if _active_index < 0 or _active_index >= _open_files.size():
		return
	_suppress_tab = true
	var info: Dictionary = _open_files[_active_index]
	_code_edit.text = str(info.get("content", ""))
	_code_edit.set_caret_line(int(info.get("cursor_line", 0)))
	_code_edit.set_caret_column(int(info.get("cursor_col", 0)))
	_code_edit.clear_undo_history()
	_suppress_tab = false
	var path: String = str(info.get("path", ""))
	_status_lang.text = FileKind.label_for_path(path)
	_update_cursor_status()


func _save_active() -> void:
	if _active_index < 0 or _active_index >= _open_files.size():
		return
	var info: Dictionary = _open_files[_active_index]
	var path: String = str(info.get("path", ""))
	if path.is_empty():
		_save_as_dlg.popup_centered()
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		_status_left.text = "ERR: Cannot save " + path.get_file()
		return
	f.store_string(_code_edit.text)
	info["content"] = _code_edit.text
	info["dirty"] = false
	_tab_bar.set_tab_title(_active_index, info.get("title", ""))
	_status_left.text = "SAVED: " + path.get_file()


func _save_as_path(path: String) -> void:
	if _active_index < 0 or _active_index >= _open_files.size():
		return
	var info: Dictionary = _open_files[_active_index]
	info["path"] = path
	info["title"] = path.get_file()
	_save_active()
	_status_lang.text = FileKind.label_for_path(path)


func _on_dir_selected(dir_path: String) -> void:
	_workspace_root = dir_path
	_nav_workspace.text = "SSCodeIDE  ·  %s" % dir_path.get_file()
	_refresh_file_tree()
	_status_left.text = "WORKSPACE: " + dir_path.get_file()


func _on_tab_changed(tab_idx: int) -> void:
	if _suppress_tab or tab_idx == _active_index:
		return
	_save_editor_state_to_active()
	_active_index = tab_idx
	_load_active_into_editor()


func _on_tab_close(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _open_files.size():
		return
	_open_files.remove_at(tab_idx)
	_tab_bar.remove_tab(tab_idx)
	if _open_files.is_empty():
		_open_untitled()
	else:
		_active_index = clamp(_active_index, 0, _open_files.size() - 1)
		_tab_bar.current_tab = _active_index
		_load_active_into_editor()


func _save_editor_state_to_active() -> void:
	if _active_index < 0 or _active_index >= _open_files.size():
		return
	var info: Dictionary = _open_files[_active_index]
	info["content"] = _code_edit.text
	info["cursor_line"] = _code_edit.get_caret_line()
	info["cursor_col"] = _code_edit.get_caret_column()


func _on_code_changed() -> void:
	if _suppress_tab or _active_index < 0 or _active_index >= _open_files.size():
		return
	var info: Dictionary = _open_files[_active_index]
	if not bool(info.get("dirty", false)):
		info["dirty"] = true
		var t: String = str(info.get("title", "untitled"))
		_tab_bar.set_tab_title(_active_index, t + " •")


func _on_caret_changed() -> void:
	_update_cursor_status()


func _update_cursor_status() -> void:
	var line: int = _code_edit.get_caret_line() + 1
	var col: int = _code_edit.get_caret_column() + 1
	_status_cursor.text = "Ln %d, Col %d" % [line, col]


func _do_find(query: String) -> void:
	if query.is_empty():
		return
	var from_line: int = _code_edit.get_caret_line()
	var from_col: int = _code_edit.get_caret_column()
	var found: Vector2i = _code_edit.search(query, 0, from_line, from_col)
	if found.x < 0:
		found = _code_edit.search(query, 0, 0, 0)
	if found.x >= 0:
		_code_edit.set_caret_line(found.y)
		_code_edit.set_caret_column(found.x)
		_code_edit.select(found.y, found.x, found.y, found.x + query.length())


func _on_find_next() -> void:
	_do_find(_find_input.text)


func _toggle_comment() -> void:
	var line: int = _code_edit.get_caret_line()
	var text: String = _code_edit.get_line(line)
	if text.strip_edges().begins_with("#"):
		_code_edit.set_line(line, text.replace("# ", "").replace("#", ""))
	else:
		_code_edit.set_line(line, "# " + text)


func _duplicate_line() -> void:
	var line: int = _code_edit.get_caret_line()
	_code_edit.insert_line_at(line + 1, _code_edit.get_line(line))


func _move_line(delta: int) -> void:
	var line: int = _code_edit.get_caret_line()
	var dest: int = line + delta
	if dest < 0 or dest >= _code_edit.get_line_count():
		return
	var a: String = _code_edit.get_line(line)
	var b: String = _code_edit.get_line(dest)
	_code_edit.set_line(line, b)
	_code_edit.set_line(dest, a)
	_code_edit.set_caret_line(dest)


func _on_chat_input_text_changed(_new_text: String) -> void:
	if not _ai_busy:
		_chat_send.text = "Enviar"


func _on_chat_send_pressed() -> void:
	var txt := _chat_input.text.strip_edges()
	if not txt.is_empty():
		_on_chat_submitted(txt)
	elif _ai_busy:
		_cancel_ai_request()


func _cancel_ai_request() -> void:
	_ai_chat_http.cancel_request()
	_ai_busy = false
	_chat_send.text = "Enviar"
	_status_left.text = "READY"
	_show_toast("Requisição cancelada.", false)
	_append_chat("IDE", "Requisição cancelada.", Color("#fc9867"))


func _on_chat_submitted(text: String) -> void:
	var prompt: String = text.strip_edges()
	if prompt.is_empty() or _ai_busy:
		return
	_chat_input.text = ""
	_append_chat("TU", prompt, Color("#78dce8"))
	if prompt.begins_with("/"):
		_handle_slash(prompt)
		return
	_ask_ai(prompt)


func _handle_slash(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false, 1)
	var head: String = parts[0].to_lower()
	match head:
		"/save":
			_save_active()
			_append_chat("IDE", "Ficheiro gravado.", Color("#a9dc76"))
		"/files":
			_refresh_file_tree()
			_append_chat("IDE", "Explorador actualizado.", Color("#a9dc76"))
		"/open":
			if parts.size() > 1:
				_open_path(parts[1])
				_append_chat("IDE", "Aberto: " + parts[1], Color("#a9dc76"))
		"/login":
			_show_login()
		"/clear":
			_chat_log.clear()
		"/cancel":
			_cancel_ai_request()
		"/quit", "/exit":
			get_tree().quit()
		_:
			_append_chat("IDE", "Comandos: /save /files /open <path> /cancel /login /clear /quit", Color("#fc9867"))


func _ask_ai(prompt: String) -> void:
	_ai_busy = true
	_chat_send.text = "Cancelar"
	_status_left.text = "IA  ·  %s a responder…" % _ai_provider
	_current_prompt = prompt
	_model_candidates = AIService.get_candidate_models(_ai_provider)
	_model_candidate_index = 0
	_send_chat_completion()


func _send_chat_completion() -> void:
	if _model_candidate_index >= _model_candidates.size():
		_ai_busy = false
		_chat_send.text = "Enviar"
		_append_chat(_ai_provider.to_upper(), "Não foi possível obter resposta dos modelos NVIDIA. Tenta novamente.", Color("#ff6188"))
		_status_left.text = "READY"
		return

	var model_name: String = _model_candidates[_model_candidate_index]
	var target_url: String = AIService.NVIDIA_BASE_URL
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + AIService.NVIDIA_API_KEY,
		"Accept: application/json"
	])
	var payload_dict: Dictionary = {
		"model": model_name,
		"messages": [
			{"role": "user", "content": _current_prompt},
		],
		"temperature": 1.0,
		"top_p": 0.95,
		"max_tokens": 4096,
		"stream": false
	}
	if model_name.begins_with("nvidia/nemotron"):
		payload_dict["chat_template_kwargs"] = {"thinking": false}
	var payload_json := JSON.stringify(payload_dict)
	var err: Error = _ai_chat_http.request(target_url, headers, HTTPClient.METHOD_POST, payload_json)
	if err != OK:
		_ai_busy = false
		_chat_send.text = "Enviar"
		_show_toast("Erro ao iniciar pedido HTTP (Código: %d)." % err, true)
		_append_chat(_ai_provider.to_upper(), "Erro ao iniciar o pedido HTTP (Código: %d)." % err, Color("#ff6188"))
		_status_left.text = "READY"


func _show_toast(message: String, is_warning: bool = true) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()

	var icon_color: String = "#fc9867" if is_warning else "#78dce8"
	var prefix: String = "⚠️" if is_warning else "ℹ️"
	_toast_label.text = "[color=%s][b]%s [/b][/color]%s" % [icon_color, prefix, message]
	_toast_panel.modulate = Color(1, 1, 1, 0)
	_toast_panel.visible = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2d2a2e")
	sb.border_color = Color(icon_color)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	_toast_panel.add_theme_stylebox_override("panel", sb)

	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(3.5)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


func _on_ai_chat_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_ai_busy = false
	_chat_send.text = "Enviar"
	_status_left.text = "READY"

	if result != HTTPRequest.RESULT_SUCCESS:
		_model_candidate_index += 1
		if _model_candidate_index < _model_candidates.size():
			_ai_busy = true
			_chat_send.text = "Cancelar"
			_show_toast("Tempo limite. A tentar modelo alternativo…", true)
			_send_chat_completion()
			return
		_show_toast("Tempo limite de resposta esgotado. Pedido cancelado automaticamente.", true)
		_append_chat(_ai_provider.to_upper(), "O modelo demorou demasiado tempo a responder. O pedido foi cancelado automaticamente.", Color("#fc9867"))
		return

	if body.is_empty():
		_model_candidate_index += 1
		if _model_candidate_index < _model_candidates.size():
			_ai_busy = true
			_chat_send.text = "Cancelar"
			_show_toast("Servidor sem resposta. A tentar modelo alternativo…", true)
			_send_chat_completion()
			return
		_show_toast("Resposta vazia do servidor.", true)
		_append_chat(_ai_provider.to_upper(), "Resposta vazia do servidor. Tenta novamente.", Color("#ff6188"))
		return

	var text := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_err := json.parse(text)
	var parsed: Variant = json.data if parse_err == OK else null

	if response_code in [200, 201] and parsed is Dictionary:
		var choices: Array = parsed.get("choices", [])
		if choices.size() > 0 and choices[0] is Dictionary:
			var msg: Dictionary = choices[0].get("message", {})
			var reply_text: String = str(msg.get("content", "")).strip_edges()
			if not reply_text.is_empty():
				_append_chat(_ai_provider.to_upper(), reply_text, Color("#a9dc76"))
				return
	elif response_code in [200, 201] and not text.strip_edges().is_empty() and not text.begins_with("{"):
		_append_chat(_ai_provider.to_upper(), text.strip_edges(), Color("#a9dc76"))
		return

	_model_candidate_index += 1
	if _model_candidate_index < _model_candidates.size():
		_ai_busy = true
		_chat_send.text = "Cancelar"
		_show_toast("Servidor ocupado. A tentar modelo alternativo…", true)
		_send_chat_completion()
	else:
		var err_detail: String = ""
		if parsed is Dictionary and parsed.has("error"):
			var err_dict: Dictionary = parsed["error"] if parsed["error"] is Dictionary else {}
			err_detail = " — " + str(err_dict.get("message", parsed["error"]))
		_show_toast("Erro ao contactar a IA (Código %d)" % response_code, true)
		_append_chat(_ai_provider.to_upper(), "Não foi possível obter resposta (Código HTTP %d)%s." % [response_code, err_detail], Color("#ff6188"))


func _append_chat(who: String, msg_body: String, color: Color) -> void:
	## Copilot-style chat: icon prefix, bold sender, subtle separator
	var icon: String = "🤖"
	if who == "TU":
		icon = "👤"
	elif who == "IDE":
		icon = "⚙️"
	elif who == "NVIDIA":
		icon = "🟢"
	_chat_log.append_text("[color=#%s][b]%s %s[/b][/color]\n%s\n[color=#4a4548]───────────────────────────────[/color]\n" % [color.to_html(false), icon, who, msg_body])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)
