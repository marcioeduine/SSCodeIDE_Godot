extends Control

## SSCodeIDE — root controller. All nodes live in ui_editor.tscn.

@onready var _file_tree: Tree = $RootVBox/MainSplit/ExplorerPane/FileTree
@onready var _tab_bar: TabBar = $RootVBox/MainSplit/CenterSplit/EditorPane/TabBar
@onready var _code_edit: CodeEdit = $RootVBox/MainSplit/CenterSplit/EditorPane/CodeEdit
@onready var _chat_log: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatLog
@onready var _chat_input_card: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard
@onready var _chat_input: LineEdit = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInput
@onready var _chat_send: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/ChatSend
@onready var _think_chip: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/ThinkChip
@onready var _search_chip: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/SearchChip
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
@onready var _chat_badge: Label = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatBadge
@onready var _chat_status_banner: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatStatusBanner
@onready var _chat_status_label: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatStatusBanner/ChatStatusLabel
@onready var _chat_suggestions_popup: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatSuggestionsPopup
@onready var _chat_suggestions_list: ItemList = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatSuggestionsPopup/ChatSuggestionsList
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
var _current_prompt: String = ""
var _model_candidates: Array[String] = []
var _model_candidate_index: int = 0
var _spinner_time: float = 0.0
var _request_start_time: float = 0.0
var _chat_history: Array[Dictionary] = []
var _think_active: bool = true
var _search_active: bool = false
const SPINNER_FRAMES: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

const CHAT_SLASH_COMMANDS: Array[Dictionary] = [
	{"cmd": "/save", "desc": "Save the active file in editor"},
	{"cmd": "/files", "desc": "Refresh workspace file explorer"},
	{"cmd": "/open ", "desc": "Open file by path (/open <path>)"},
	{"cmd": "/clear", "desc": "Clear conversation history & chat context"},
	{"cmd": "/cancel", "desc": "Abort running AI request"},
	{"cmd": "/quit", "desc": "Quit SSCodeIDE"},
]

const GD_KEYWORDS: Array[String] = [
	"func", "var", "const", "extends", "class_name", "if", "elif", "else",
	"for", "while", "match", "return", "signal", "enum", "static", "void",
	"int", "float", "bool", "String", "Array", "Dictionary", "true", "false", "null",
	"@onready", "@export", "preload", "load", "print", "push_error", "await"
]

const GD_BUILTIN_FUNCS: Array[String] = [
	"print", "push_error", "push_warning", "len", "range", "str", "int", "float",
	"bool", "min", "max", "clamp", "abs", "sin", "cos", "sqrt", "randf", "randi",
	"load", "preload", "get_node", "has_node", "find_child", "add_child", "remove_child",
	"queue_free", "emit_signal", "connect", "disconnect", "is_connected"
]

const GD_TYPES: Array[String] = [
	"Node", "Control", "Panel", "PanelContainer", "Label", "Button", "LineEdit",
	"TextEdit", "CodeEdit", "Tree", "TreeItem", "ItemList", "TabBar", "RichTextLabel",
	"HTTPRequest", "ColorRect", "TextureRect", "Vector2", "Vector3", "Color", "Rect2",
	"Transform2D", "Transform3D", "PackedStringArray", "PackedByteArray", "Variant"
]

const HELP_TEXT := """[b]SSCodeIDE Shortcuts[/b]

[b]File[/b]
  Ctrl+N            New file
  Ctrl+O            Open file
  Ctrl+Shift+O      Open directory
  Ctrl+S            Save
  Ctrl+Shift+S      Save as
  Ctrl+W            Close tab
  Ctrl+Tab          Next tab
  Ctrl+Shift+Tab    Previous tab
  Ctrl+Q            Quit

[b]Edit[/b]
  Ctrl+Z / Ctrl+Y   Undo / Redo
  Ctrl+X / C / V    Cut / Copy / Paste
  Ctrl+A            Select all
  Ctrl+F            Find
  Ctrl+G            Go to line
  Ctrl+/            Toggle line comment
  Ctrl+D            Duplicate line
  Alt+↑ / Alt+↓     Move line

[b]IDE[/b]
  Ctrl+,            Settings
  F1                Help (shortcuts)
  Ctrl+P            Focus explorer
  Esc               Cancel AI generation
"""

const ABOUT_TEXT := """[b]SSCodeIDE[/b]
IDE in 100% native GDScript (Godot 4.7) — Kitty Adwaita Darker & Fish theme.

Default Font: FiraCode Nerd Font
AI Chat: Nemotron · Kimi K3 · DeepSeek V4 · Laguna Code via NVIDIA NIM API
Automatic Toast · Multi-Turn Context Memory · Intelligent Candidate Fallback

© Ser Superior (SS)
"""


func _ready() -> void:
	_nerd_font = FontFile.new()
	_nerd_font.load_dynamic_font(ProjectSettings.globalize_path("res://fonts/FiraCodeNerdFont-Regular.ttf"))
	_workspace_root = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	_nav_workspace.text = "SSCodeIDE  ·  %s" % _workspace_root.get_file()
	_load_ai_config()
	_apply_kitty_fish_theme()
	_wire_signals()
	_configure_code_edit()
	_refresh_file_tree()
	_open_untitled()
	_update_ai_status()
	_status_left.text = "READY"
	_status_enc.text = "UTF-8"
	call_deferred("_apply_split_offsets")


func _process(delta: float) -> void:
	if _ai_busy:
		_spinner_time += delta
		var frame_idx: int = int(_spinner_time * 10.0) % SPINNER_FRAMES.size()
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _request_start_time
		var frame: String = SPINNER_FRAMES[frame_idx]
		_chat_status_label.text = "[color=#ffa348]%s[/color] [b]Generating…[/b] [color=#9a9996](%.1fs)[/color]\n[color=#727072]Tip: Use /save, /files, /open, /cancel, /clear[/color]" % [frame, elapsed]
		_status_left.text = "%s Generating · %s (%.1fs) · esc to cancel" % [frame, _ai_provider, elapsed]


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
	_think_chip.pressed.connect(_on_think_chip_pressed)
	_search_chip.pressed.connect(_on_search_chip_pressed)
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
	_provider_select.item_selected.connect(_on_provider_selected)
	_find_input.text_submitted.connect(_do_find)
	_find_next.pressed.connect(_on_find_next)
	_find_close.pressed.connect(func() -> void: _find_row.visible = false)
	_chat_suggestions_list.item_selected.connect(_on_chat_suggestion_selected)
	_chat_suggestions_list.item_activated.connect(_on_chat_suggestion_selected)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	var ctrl: bool = key.ctrl_pressed
	var shift: bool = key.shift_pressed
	var alt: bool = key.alt_pressed
	if ctrl and key.keycode == KEY_SPACE:
		_update_code_completion()
		_code_edit.request_code_completion(true)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and _ai_busy:
		_cancel_ai_request()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F1:
		_show_help()
		get_viewport().set_input_as_handled()
	elif ctrl and key.keycode == KEY_COMMA:
		_show_config()
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
	var body := "[b]Settings[/b]\n\n• [b]Typography:[/b] FiraCode Nerd Font\n• [b]Workspace:[/b] %s\n• [b]Active Model:[/b] %s (NVIDIA NIM)\n• [b]Status:[/b] Connected & Active" % [
		_workspace_root,
		_ai_provider.replace("_", " ").to_upper(),
	]
	_show_overlay("Settings", body)


func _on_provider_selected(index: int) -> void:
	if _ai_busy:
		_cancel_ai_request()
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	if index >= 0 and index < names.size():
		_ai_provider = names[index]
	_chat_send.text = "Send"
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
	var idx: int = names.find(_ai_provider)
	if idx < 0:
		idx = 0
		_ai_provider = "nemotron"
	_provider_select.select(idx)
	_chat_send.text = "Send"


func _save_ai_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ai", "provider", _ai_provider)
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
	_chat_badge.text = "NVIDIA NIM"
	_chat_input.placeholder_text = "Ask %s…" % display_title


func _apply_kitty_fish_theme() -> void:
	## Kitty Adwaita Darker + Fish Shell Palette
	var bg_black := Color("#000000")
	var bg_darker := Color("#0e0e11")
	var bg_surface := Color("#16161b")
	var bg_card := Color("#1c1c22")
	var bg_lighter := Color("#26262e")
	var fg := Color("#deddda")
	var fg_bright := Color("#f6f5f4")
	var muted := Color("#9a9996")
	var blue := Color("#62a0ea")
	var green := Color("#57e389")
	var cyan := Color("#5bc8af")
	var red := Color("#ed333b")

	## Background
	$Background.color = bg_black

	## NavBar
	var nav_bar: HBoxContainer = $RootVBox/NavBar
	var nav_sb := StyleBoxFlat.new()
	nav_sb.bg_color = bg_black
	nav_bar.add_theme_stylebox_override("panel", nav_sb)
	_nav_workspace.add_theme_color_override("font_color", blue)

	## Explorer
	var explorer_header: Label = $RootVBox/MainSplit/ExplorerPane/ExplorerHeader
	explorer_header.add_theme_color_override("font_color", muted)
	var explorer_sb := StyleBoxFlat.new()
	explorer_sb.bg_color = bg_surface
	$RootVBox/MainSplit/ExplorerPane.add_theme_stylebox_override("panel", explorer_sb)
	_file_tree.add_theme_color_override("font_color", fg)
	_file_tree.add_theme_color_override("font_selected_color", blue)
	var tree_bg_sb := StyleBoxFlat.new()
	tree_bg_sb.bg_color = bg_surface
	_file_tree.add_theme_stylebox_override("panel", tree_bg_sb)

	## CodeEdit — Kitty terminal / Adwaita Darker editor
	_code_edit.add_theme_color_override("background_color", bg_black)
	_code_edit.add_theme_color_override("font_color", fg)
	_code_edit.add_theme_color_override("current_line_color", Color("#16161c"))
	_code_edit.add_theme_color_override("selection_color", Color("#1c1c1c"))
	_code_edit.add_theme_color_override("line_number_color", Color("#5e5c5b"))
	_code_edit.add_theme_color_override("caret_color", fg_bright)
	_code_edit.add_theme_color_override("word_highlighted_color", Color("#26262e"))
	_code_edit.add_theme_color_override("brace_mismatch_color", red)

	## TabBar
	_tab_bar.add_theme_color_override("font_selected_color", fg_bright)
	_tab_bar.add_theme_color_override("font_unselected_color", muted)

	## Chat pane — Modern DeepSeek/ChatGPT style on Adwaita Darker
	_chat_log.add_theme_color_override("default_color", fg)
	var chat_log_sb := StyleBoxFlat.new()
	chat_log_sb.bg_color = bg_darker
	chat_log_sb.set_content_margin_all(10)
	_chat_log.add_theme_stylebox_override("normal", chat_log_sb)

	## Chat Input Card (Floating capsule container)
	var input_card_sb := StyleBoxFlat.new()
	input_card_sb.bg_color = bg_card
	input_card_sb.border_color = Color("#2e2e38")
	input_card_sb.set_border_width_all(1)
	input_card_sb.set_corner_radius_all(14)
	input_card_sb.set_content_margin_all(8)
	_chat_input_card.add_theme_stylebox_override("panel", input_card_sb)

	var chat_input_sb := StyleBoxEmpty.new()
	chat_input_sb.set_content_margin_all(4)
	_chat_input.add_theme_stylebox_override("normal", chat_input_sb)
	_chat_input.add_theme_stylebox_override("focus", chat_input_sb)
	_chat_input.add_theme_color_override("font_color", fg_bright)
	_chat_input.add_theme_color_override("font_placeholder_color", muted)

	## Action Chips
	_update_chip_styles()

	## Send button (Circular / pill button with Adwaita blue accent)
	var send_sb := StyleBoxFlat.new()
	send_sb.bg_color = blue
	send_sb.set_corner_radius_all(12)
	send_sb.set_content_margin_all(4)
	_chat_send.add_theme_stylebox_override("normal", send_sb)
	_chat_send.add_theme_stylebox_override("hover", send_sb)
	_chat_send.add_theme_stylebox_override("pressed", send_sb)
	_chat_send.add_theme_color_override("font_color", Color("#ffffff"))
	_chat_send.add_theme_color_override("font_hover_color", Color("#ffffff"))
	_chat_send.add_theme_color_override("font_pressed_color", Color("#ffffff"))

	## Chat header
	var chat_header: Label = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatHeader
	chat_header.add_theme_color_override("font_color", fg_bright)

	## Status bar — Adwaita Darker
	var status_sb := StyleBoxFlat.new()
	status_sb.bg_color = bg_surface
	$RootVBox/StatusBar.add_theme_stylebox_override("panel", status_sb)
	_status_left.add_theme_color_override("font_color", green)
	_status_cursor.add_theme_color_override("font_color", muted)
	_status_lang.add_theme_color_override("font_color", muted)
	_status_enc.add_theme_color_override("font_color", muted)
	_status_ai.add_theme_color_override("font_color", blue)

	## AI Badge
	_chat_badge.add_theme_color_override("font_color", cyan)

	## Provider select dropdown
	var provider_sb := StyleBoxFlat.new()
	provider_sb.bg_color = bg_lighter
	provider_sb.set_corner_radius_all(4)
	provider_sb.set_content_margin_all(4)
	_provider_select.add_theme_stylebox_override("normal", provider_sb)
	_provider_select.add_theme_color_override("font_color", fg)

	## Chat status banner
	var status_banner_sb := StyleBoxFlat.new()
	status_banner_sb.bg_color = bg_card
	status_banner_sb.border_color = Color("#2e2e38")
	status_banner_sb.set_border_width_all(1)
	status_banner_sb.set_corner_radius_all(8)
	status_banner_sb.set_content_margin_all(8)
	_chat_status_banner.add_theme_stylebox_override("panel", status_banner_sb)

	## Chat suggestions popup & list
	var suggestions_sb := StyleBoxFlat.new()
	suggestions_sb.bg_color = bg_card
	suggestions_sb.border_color = Color("#2e2e38")
	suggestions_sb.set_border_width_all(1)
	suggestions_sb.set_corner_radius_all(8)
	suggestions_sb.set_content_margin_all(4)
	_chat_suggestions_popup.add_theme_stylebox_override("panel", suggestions_sb)
	_chat_suggestions_list.add_theme_color_override("font_color", fg)
	_chat_suggestions_list.add_theme_color_override("font_selected_color", blue)
	var list_bg_sb := StyleBoxFlat.new()
	list_bg_sb.bg_color = bg_card
	_chat_suggestions_list.add_theme_stylebox_override("panel", list_bg_sb)

	## Apply font everywhere
	if _nerd_font:
		for node: Control in [_code_edit, _file_tree, _chat_log, _chat_input,
				_status_left, _status_cursor, _status_lang, _status_enc,
				_status_ai, _nav_workspace, chat_header, explorer_header,
				_chat_status_label, _think_chip, _search_chip, _chat_send,
				_chat_suggestions_list]:
			node.add_theme_font_override("font", _nerd_font)
		_code_edit.add_theme_font_size_override("font_size", 14)
		_chat_log.add_theme_font_size_override("normal_font_size", 13)
		_chat_input.add_theme_font_size_override("font_size", 13)
		_chat_status_label.add_theme_font_size_override("normal_font_size", 12)
		_think_chip.add_theme_font_size_override("font_size", 11)
		_search_chip.add_theme_font_size_override("font_size", 11)
		_chat_suggestions_list.add_theme_font_size_override("font_size", 11)


func _on_think_chip_pressed() -> void:
	_think_active = not _think_active
	_update_chip_styles()


func _on_search_chip_pressed() -> void:
	_search_active = not _search_active
	_update_chip_styles()


func _update_chip_styles() -> void:
	var think_sb := StyleBoxFlat.new()
	think_sb.set_corner_radius_all(10)
	think_sb.set_content_margin_all(5)
	if _think_active:
		think_sb.bg_color = Color("#1e2a38")
		think_sb.border_color = Color("#62a0ea")
		think_sb.set_border_width_all(1)
		_think_chip.add_theme_color_override("font_color", Color("#99c1f1"))
	else:
		think_sb.bg_color = Color("#222228")
		think_sb.set_border_width_all(0)
		_think_chip.add_theme_color_override("font_color", Color("#9a9996"))
	_think_chip.add_theme_stylebox_override("normal", think_sb)
	_think_chip.add_theme_stylebox_override("hover", think_sb)

	var search_sb := StyleBoxFlat.new()
	search_sb.set_corner_radius_all(10)
	search_sb.set_content_margin_all(5)
	if _search_active:
		search_sb.bg_color = Color("#1e3028")
		search_sb.border_color = Color("#57e389")
		search_sb.set_border_width_all(1)
		_search_chip.add_theme_color_override("font_color", Color("#8ff0a4"))
	else:
		search_sb.bg_color = Color("#222228")
		search_sb.set_border_width_all(0)
		_search_chip.add_theme_color_override("font_color", Color("#9a9996"))
	_search_chip.add_theme_stylebox_override("normal", search_sb)
	_search_chip.add_theme_stylebox_override("hover", search_sb)


func _configure_code_edit() -> void:
	_code_edit.syntax_highlighter = _create_adwaita_fish_highlighter()
	_code_edit.draw_tabs = true
	_code_edit.draw_spaces = false
	_code_edit.indent_size = 4
	_code_edit.indent_use_spaces = false
	_code_edit.auto_brace_completion_enabled = true
	_code_edit.code_completion_enabled = true
	_code_edit.code_completion_prefixes = [".", "(", "@", "$", " ", ":"]
	_update_code_completion()


func _update_code_completion() -> void:
	for kw in GD_KEYWORDS:
		_code_edit.add_code_completion_option(CodeEdit.KIND_KEYWORD, kw, kw, Color("#dc8add"))
	for fn_name in GD_BUILTIN_FUNCS:
		_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, fn_name, fn_name + "()", Color("#62a0ea"))
	for type_name in GD_TYPES:
		_code_edit.add_code_completion_option(CodeEdit.KIND_CLASS, type_name, type_name, Color("#93ddc2"))
	for file_info in _open_files:
		var fname: String = file_info.get("path", "").get_file()
		if not fname.is_empty():
			_code_edit.add_code_completion_option(CodeEdit.KIND_FILE_PATH, fname, '"' + fname + '"', Color("#57e389"))
	_code_edit.update_code_completion_options(false)


func _create_adwaita_fish_highlighter() -> CodeHighlighter:
	var hl := CodeHighlighter.new()
	## Kitty Adwaita Darker + Fish Shell Syntax Palette
	hl.number_color = Color("#ffa348")         # Orange/Yellow — numbers & literals
	hl.symbol_color = Color("#5bc8af")         # Cyan — operators & symbols (Fish operator)
	hl.function_color = Color("#62a0ea")       # Blue — functions & commands (Fish command)
	hl.member_variable_color = Color("#99c1f1") # Light blue — parameters & member variables
	hl.add_color_region("#", "", Color("#9a9996"), true)  # Comments (Adwaita muted gray)
	hl.add_color_region('"', '"', Color("#57e389"))       # Strings — Green (Fish cwd)
	hl.add_color_region("'", "'", Color("#57e389"))
	hl.add_color_region('"""', '"""', Color("#57e389"))
	var kws := [
		"extends", "class_name", "var", "const", "func", "static", "signal", "enum",
		"if", "elif", "else", "for", "while", "match", "return", "pass", "break",
		"continue", "await", "self", "void", "int", "float", "bool", "String",
		"Vector2", "Vector3", "Color", "Array", "Dictionary", "true", "false", "null",
		"@onready", "@export", "preload", "load", "print", "push_error", "in", "not",
		"and", "or", "is", "as", "class", "super", "get", "set",
	]
	for kw in kws:
		hl.add_keyword_color(kw, Color("#dc8add"))  # Magenta/Purple — keywords
	## Type keywords in bright cyan/blue
	var types := ["int", "float", "bool", "String", "Vector2", "Vector3", "Color",
		"Array", "Dictionary", "void", "PackedStringArray", "PackedByteArray",
		"Variant", "Error", "NodePath", "StringName"]
	for t in types:
		hl.add_keyword_color(t, Color("#93ddc2"))
	## Built-in constants in orange/amber
	for c in ["true", "false", "null", "self", "PI", "TAU", "INF", "NAN"]:
		hl.add_keyword_color(c, Color("#ffa348"))
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
	_update_code_completion()


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


func _on_chat_input_text_changed(new_text: String) -> void:
	if not _ai_busy:
		_chat_send.text = "↑"
	_update_chat_suggestions(new_text)


func _update_chat_suggestions(input_text: String) -> void:
	var query := input_text.strip_edges()
	_chat_suggestions_list.clear()
	
	if query.begins_with("/"):
		for item in CHAT_SLASH_COMMANDS:
			var cmd: String = item["cmd"]
			if query == "/" or cmd.begins_with(query):
				_chat_suggestions_list.add_item(cmd + "  —  " + item["desc"])
				_chat_suggestions_list.set_item_metadata(_chat_suggestions_list.get_item_count() - 1, cmd)
	elif query.contains("@") or query.begins_with("open ") or query.begins_with("read "):
		var at_idx := query.rfind("@")
		var filter := ""
		if at_idx != -1:
			filter = query.substr(at_idx + 1).to_lower()
		var files := _get_workspace_files_list()
		for f in files:
			if filter.is_empty() or f.to_lower().contains(filter):
				_chat_suggestions_list.add_item("📁 @" + f)
				_chat_suggestions_list.set_item_metadata(_chat_suggestions_list.get_item_count() - 1, "@" + f)
				if _chat_suggestions_list.get_item_count() >= 8:
					break
	
	_chat_suggestions_popup.visible = _chat_suggestions_list.get_item_count() > 0


func _on_chat_suggestion_selected(index: int) -> void:
	if index < 0 or index >= _chat_suggestions_list.get_item_count():
		return
	var meta: Variant = _chat_suggestions_list.get_item_metadata(index)
	if meta is String:
		var insert_val: String = meta
		if insert_val.begins_with("@") and _chat_input.text.contains("@"):
			var at_idx := _chat_input.text.rfind("@")
			_chat_input.text = _chat_input.text.substr(0, at_idx) + insert_val + " "
		else:
			_chat_input.text = insert_val + " "
		_chat_input.caret_column = _chat_input.text.length()
	_chat_suggestions_popup.visible = false
	_chat_input.grab_focus()


func _on_chat_send_pressed() -> void:
	var txt := _chat_input.text.strip_edges()
	if not txt.is_empty():
		_on_chat_submitted(txt)
	elif _ai_busy:
		_cancel_ai_request()


func _cancel_ai_request() -> void:
	_ai_chat_http.cancel_request()
	_ai_busy = false
	_chat_status_banner.visible = false
	_chat_send.text = "↑"
	_status_left.text = "READY"
	_show_toast("Request cancelled.", false)
	_append_chat("IDE", "Request cancelled.", Color("#ffa348"))


func _on_chat_submitted(text: String) -> void:
	var prompt: String = text.strip_edges()
	if prompt.is_empty() or _ai_busy:
		return
	_chat_input.text = ""
	_chat_suggestions_popup.visible = false
	_append_user_message(prompt)
	if prompt.begins_with("/"):
		_handle_slash(prompt)
		return
	_chat_history.append({"role": "user", "content": prompt})
	_ask_ai(prompt)


func _handle_slash(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false, 1)
	var head: String = parts[0].to_lower()
	match head:
		"/save":
			_save_active()
			var p: String = _open_files[_active_index]["path"] if _active_index >= 0 else "untitled"
			_append_tool_badge("Save", p)
		"/files":
			_refresh_file_tree()
			_append_tool_badge("Explorer", "refreshed")
		"/open":
			if parts.size() > 1:
				_open_path(parts[1])
				_append_tool_badge("Open", parts[1])
		"/clear":
			_chat_history.clear()
			_chat_log.clear()
			_append_chat("IDE", "Chat history and context cleared.", Color("#57e389"))
		"/cancel":
			_cancel_ai_request()
		"/quit", "/exit":
			get_tree().quit()
		_:
			_append_chat("IDE", "Commands: `/save`, `/files`, `/open <path>`, `/cancel`, `/clear`, `/quit`", Color("#ffa348"))


func _get_workspace_files_list() -> Array[String]:
	var list: Array[String] = []
	if _workspace_root.is_empty():
		return list
	_collect_files_recursive(_workspace_root, "", list)
	return list


func _collect_files_recursive(base_path: String, rel_prefix: String, out_list: Array[String]) -> void:
	var dir := DirAccess.open(base_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_item_name := dir.get_next()
	while not file_item_name.is_empty():
		if file_item_name not in [".", "..", ".git", ".godot", "android", ".gemini"]:
			var full_path := base_path.path_join(file_item_name)
			var rel_path := rel_prefix.path_join(file_item_name) if not rel_prefix.is_empty() else file_item_name
			if dir.current_is_dir():
				if out_list.size() < 120:
					_collect_files_recursive(full_path, rel_path, out_list)
			else:
				out_list.append(rel_path)
		file_item_name = dir.get_next()
	dir.list_dir_end()


func _get_workspace_context() -> String:
	var context_str: String = "Workspace Root: " + _workspace_root + "\n"
	
	# Open files summary
	var open_paths: Array[String] = []
	for f in _open_files:
		open_paths.append(f.get("path", ""))
	context_str += "Open Files in Tabs: " + ", ".join(open_paths) + "\n\n"
	
	# Active file content snippet
	if _active_index >= 0 and _active_index < _open_files.size():
		var active_path: String = _open_files[_active_index].get("path", "untitled")
		var active_code: String = _code_edit.text
		if active_code.length() > 4000:
			active_code = active_code.substr(0, 4000) + "\n... [content truncated for length]"
		context_str += "--- Active File: " + active_path + " ---\n" + active_code + "\n-------------------------\n\n"
	
	# Directory file tree
	var files := _get_workspace_files_list()
	if not files.is_empty():
		context_str += "Project Directory Structure (" + str(files.size()) + " files):\n"
		for f in files.slice(0, 80):
			context_str += "  • " + f + "\n"
		if files.size() > 80:
			context_str += "  • ... and " + str(files.size() - 80) + " more files\n"
	
	return context_str


func _ask_ai(prompt: String) -> void:
	_ai_busy = true
	_request_start_time = Time.get_ticks_msec() / 1000.0
	_spinner_time = 0.0
	_chat_status_banner.visible = true
	_chat_send.text = "■"
	_status_left.text = "Generating response…"
	_current_prompt = prompt
	_model_candidates = AIService.get_candidate_models(_ai_provider)
	_model_candidate_index = 0
	_send_chat_completion()


func _send_chat_completion() -> void:
	if _model_candidate_index >= _model_candidates.size():
		_ai_busy = false
		_chat_status_banner.visible = false
		_chat_send.text = "↑"
		_append_chat(_ai_provider.to_upper(), "Could not retrieve response from NVIDIA NIM models. Please retry.", Color("#ed333b"))
		_status_left.text = "READY"
		return

	var model_name: String = _model_candidates[_model_candidate_index]
	var target_url: String = AIService.NVIDIA_BASE_URL
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + AIService.NVIDIA_API_KEY,
		"Accept: application/json"
	])
	
	var workspace_info: String = _get_workspace_context()
	var system_role_content: String = (
		"You are SSBot, an elite AI programming assistant integrated directly into SSCodeIDE.\n" +
		"You have direct access and visibility to the project workspace files, directory tree, and active file.\n\n" +
		"=== WORKSPACE CONTEXT ===\n" +
		workspace_info + "\n" +
		"=========================\n\n" +
		"Provide accurate, deeply knowledgeable, concise and clean answers with syntax highlighting in British English."
	)
	if _think_active:
		system_role_content += " Think deeply and provide comprehensive step-by-step reasoning."
	
	var messages_payload: Array[Dictionary] = [
		{"role": "system", "content": system_role_content}
	]
	
	var start_idx: int = maxi(0, _chat_history.size() - 16)
	for i in range(start_idx, _chat_history.size()):
		messages_payload.append(_chat_history[i])

	var payload_dict: Dictionary = {
		"model": model_name,
		"messages": messages_payload,
		"temperature": 0.7,
		"top_p": 0.95,
		"max_tokens": 4096,
		"stream": false
	}
	if model_name.begins_with("nvidia/nemotron"):
		payload_dict["chat_template_kwargs"] = {"thinking": _think_active}
	var payload_json := JSON.stringify(payload_dict)
	var err: Error = _ai_chat_http.request(target_url, headers, HTTPClient.METHOD_POST, payload_json)
	if err != OK:
		_ai_busy = false
		_chat_status_banner.visible = false
		_chat_send.text = "↑"
		_show_toast("Failed to initiate HTTP request (Code %d)." % err, true)
		_append_chat(_ai_provider.to_upper(), "Failed to initiate HTTP request (Code %d)." % err, Color("#ed333b"))
		_status_left.text = "READY"


func _show_toast(message: String, is_warning: bool = true) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()

	var icon_color: String = "#ffa348" if is_warning else "#62a0ea"
	var prefix: String = "[!] " if is_warning else "[i] "
	_toast_label.text = "[color=%s][b]%s[/b][/color]%s" % [icon_color, prefix, message]
	_toast_panel.modulate = Color(1, 1, 1, 0)
	_toast_panel.visible = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1c1c22")
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
	_chat_status_banner.visible = false
	_chat_send.text = "↑"
	_status_left.text = "READY"

	var elapsed: float = maxf(0.1, (Time.get_ticks_msec() / 1000.0) - _request_start_time)

	if result != HTTPRequest.RESULT_SUCCESS:
		_model_candidate_index += 1
		if _model_candidate_index < _model_candidates.size():
			_ai_busy = true
			_chat_status_banner.visible = true
			_chat_send.text = "■"
			_show_toast("Request timeout. Attempting candidate model…", true)
			_send_chat_completion()
			return
		_show_toast("Response timeout exceeded. Request cancelled.", true)
		_append_chat(_ai_provider.to_upper(), "The model timed out. The request was cancelled automatically.", Color("#ff7800"))
		return

	if body.is_empty():
		_model_candidate_index += 1
		if _model_candidate_index < _model_candidates.size():
			_ai_busy = true
			_chat_status_banner.visible = true
			_chat_send.text = "■"
			_show_toast("Empty response. Attempting candidate model…", true)
			_send_chat_completion()
			return
		_show_toast("Empty server response.", true)
		_append_chat(_ai_provider.to_upper(), "Empty server response. Please retry.", Color("#ed333b"))
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
				_chat_history.append({"role": "assistant", "content": reply_text})
				var usage: Dictionary = parsed.get("usage", {})
				var prompt_tokens: int = int(usage.get("prompt_tokens", float(_current_prompt.length()) / 4.0))
				var completion_tokens: int = int(usage.get("completion_tokens", float(reply_text.length()) / 4.0))
				_append_ai_response(_ai_provider, reply_text, elapsed, prompt_tokens, completion_tokens)
				return
	elif response_code in [200, 201] and not text.strip_edges().is_empty() and not text.begins_with("{"):
		_chat_history.append({"role": "assistant", "content": text.strip_edges()})
		_append_ai_response(_ai_provider, text.strip_edges(), elapsed)
		return

	_model_candidate_index += 1
	if _model_candidate_index < _model_candidates.size():
		_ai_busy = true
		_chat_status_banner.visible = true
		_chat_send.text = "■"
		_show_toast("Server busy. Attempting candidate model…", true)
		_send_chat_completion()
	else:
		var err_detail: String = ""
		if parsed is Dictionary and parsed.has("error"):
			var err_dict: Dictionary = parsed["error"] if parsed["error"] is Dictionary else {}
			err_detail = " — " + str(err_dict.get("message", parsed["error"]))
		_show_toast("AI Service Error (HTTP %d)" % response_code, true)
		_append_chat(_ai_provider.to_upper(), "Could not retrieve response (HTTP %d)%s." % [response_code, err_detail], Color("#ed333b"))


func _append_user_message(prompt: String) -> void:
	var sanitized: String = prompt.replace("[", "[lb]")
	_chat_log.append_text("\n[right][bgcolor=#25252e][color=#ffffff]   %s   [/color][/bgcolor][/right]\n\n" % sanitized)
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _append_ai_response(provider: String, reply_text: String, elapsed: float, tokens_in: int = 0, tokens_out: int = 0) -> void:
	var stats_header := ""
	if tokens_in > 0 and tokens_out > 0:
		stats_header = "[color=#ffa348][b]%.1fk in | %.1fk out | %.1fs[/b][/color]\n\n" % [tokens_in / 1000.0, tokens_out / 1000.0, elapsed]
	else:
		stats_header = "[color=#ffa348][b]%s[/b][/color] [color=#57e389]● Ready[/color] [color=#9a9996](%.1fs)[/color]\n\n" % [provider.to_upper(), elapsed]

	var formatted_body := _format_markdown_to_bbcode(reply_text)
	_chat_log.append_text("%s%s\n\n[color=#202024]────────────────────────────────────────────────[/color]\n\n" % [stats_header, formatted_body])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _append_tool_badge(action: String, target: String) -> void:
	_chat_log.append_text("[color=#57e389]●[/color] [b]%s[/b][color=#9a9996](%s)[/color]\n\n" % [action, target])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _append_chat(who: String, msg_body: String, color: Color) -> void:
	var formatted := _format_markdown_to_bbcode(msg_body)
	_chat_log.append_text("[color=#%s][b]● %s[/b][/color] %s\n\n[color=#202024]────────────────────────────────────────────────[/color]\n\n" % [color.to_html(false), who, formatted])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _format_markdown_to_bbcode(raw_text: String) -> String:
	if raw_text.is_empty():
		return ""

	var output: String = ""
	var in_code_block: bool = false
	var code_block_lang: String = ""
	var code_block_lines: Array[String] = []

	var lines := raw_text.split("\n")
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with("```"):
			if in_code_block:
				in_code_block = false
				var code_content := "\n".join(code_block_lines)
				code_block_lines.clear()
				var lang_tag := code_block_lang if not code_block_lang.is_empty() else "code"
				output += "\n[bgcolor=#1e1e24][color=#9a9996]  " + lang_tag + "                         [color=#62a0ea]Copy[/color]  [/color][/bgcolor]\n"
				output += "[bgcolor=#121216][color=#57e389]  " + code_content.replace("\n", "\n  ") + "\n[/color][/bgcolor]\n\n"
			else:
				in_code_block = true
				code_block_lang = trimmed.substr(3).strip_edges()
				code_block_lines.clear()
			continue

		if in_code_block:
			code_block_lines.append(line)
			continue

		var formatted_line: String = line

		# Headers
		if formatted_line.begins_with("### "):
			formatted_line = "[color=#ffffff][b]" + formatted_line.substr(4) + "[/b][/color]"
		elif formatted_line.begins_with("## "):
			formatted_line = "[font_size=14][color=#ffffff][b]" + formatted_line.substr(3) + "[/b][/color][/font_size]"
		elif formatted_line.begins_with("# "):
			formatted_line = "[font_size=16][color=#ffffff][b]" + formatted_line.substr(2) + "[/b][/color][/font_size]"
		elif formatted_line.begins_with("> "):
			# Blockquote / Callout
			formatted_line = "[color=#5bc8af]▎[/color] [color=#c0bfbc]" + formatted_line.substr(2) + "[/color]"
		elif formatted_line.begins_with("- ") or formatted_line.begins_with("* "):
			# Unordered list item
			formatted_line = "  [color=#57e389]•[/color] " + formatted_line.substr(2)

		formatted_line = _replace_inline_code(formatted_line)
		formatted_line = _replace_bold(formatted_line)
		formatted_line = _replace_italic(formatted_line)
		formatted_line = _replace_links(formatted_line)

		output += formatted_line + "\n"

	if in_code_block and not code_block_lines.is_empty():
		var code_content := "\n".join(code_block_lines)
		var lang_tag := code_block_lang if not code_block_lang.is_empty() else "code"
		output += "\n[bgcolor=#1e1e24][color=#9a9996]  " + lang_tag + "                         [color=#62a0ea]Copy[/color]  [/color][/bgcolor]\n"
		output += "[bgcolor=#121216][color=#57e389]  " + code_content.replace("\n", "\n  ") + "\n[/color][/bgcolor]\n\n"

	return output.strip_edges(false, true)


func _replace_bold(text: String) -> String:
	var result := text
	while true:
		var first := result.find("**")
		if first == -1:
			break
		var second := result.find("**", first + 2)
		if second == -1:
			break
		var inner := result.substr(first + 2, second - (first + 2))
		result = result.substr(0, first) + "[b]" + inner + "[/b]" + result.substr(second + 2)
	return result


func _replace_inline_code(text: String) -> String:
	var result := text
	while true:
		var first := result.find("`")
		if first == -1:
			break
		var second := result.find("`", first + 1)
		if second == -1:
			break
		var inner := result.substr(first + 1, second - (first + 1))
		result = result.substr(0, first) + "[bgcolor=#23232b][color=#99c1f1] " + inner + " [/color][/bgcolor]" + result.substr(second + 1)
	return result


func _replace_italic(text: String) -> String:
	var result := text
	while true:
		var first := result.find("*")
		if first == -1:
			break
		var second := result.find("*", first + 1)
		if second == -1:
			break
		var inner := result.substr(first + 1, second - (first + 1))
		result = result.substr(0, first) + "[i]" + inner + "[/i]" + result.substr(second + 1)
	return result


func _replace_links(text: String) -> String:
	var result := text
	while true:
		var b_open := result.find("[")
		if b_open == -1:
			break
		var b_close := result.find("]", b_open + 1)
		if b_close == -1 or b_close + 1 >= result.length() or result[b_close + 1] != "(":
			break
		var p_close := result.find(")", b_close + 2)
		if p_close == -1:
			break
		var label := result.substr(b_open + 1, b_close - (b_open + 1))
		var url_target := result.substr(b_close + 2, p_close - (b_close + 2))
		result = result.substr(0, b_open) + "[url=" + url_target + "][color=#62a0ea][u]" + label + "[/u][/color][/url]" + result.substr(p_close + 1)
	return result
