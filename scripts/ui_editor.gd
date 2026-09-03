extends Control

## SSCodeIDE — root controller. All nodes live in ui_editor.tscn.

@onready var _file_tree: Tree = $RootVBox/MainSplit/ExplorerPane/FileTree
@onready var _tab_bar: TabBar = %TabBar
@onready var _code_edit: CodeEdit = $RootVBox/MainSplit/CenterSplit/EditorPane/CodeEdit
@onready var _chat_log: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatLog
@onready var _chat_header: Label = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatHeader
@onready var _chat_context_badge: Label = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatHeaderRow/ChatContextBadge
@onready var _chat_input_card: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard
@onready var _chat_context_chip: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatContextChip
@onready var _chat_input: LineEdit = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInput
@onready var _attach_btn: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/AttachBtn
@onready var _agent_mode_btn: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/AgentModeBtn
@onready var _provider_select: OptionButton = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/ProviderSelect
@onready var _smart_commit_btn: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/SmartCommitBtn
@onready var _chat_send: Button = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatInputCard/ChatInputVBox/ChatInputBottomRow/ChatSend
@onready var _status_left: Label = $RootVBox/StatusBar/StatusRow/StatusLeft
@onready var _status_git: Button = $RootVBox/StatusBar/StatusRow/StatusGit
@onready var _status_cursor: Label = $RootVBox/StatusBar/StatusRow/StatusCursor
@onready var _status_lang: Label = $RootVBox/StatusBar/StatusRow/StatusLang
@onready var _status_enc: Label = $RootVBox/StatusBar/StatusRow/StatusEnc
@onready var _status_ai: Label = $RootVBox/StatusBar/StatusRow/StatusAI
@onready var _main_split: HSplitContainer = $RootVBox/MainSplit
@onready var _center_split: HSplitContainer = $RootVBox/MainSplit/CenterSplit
@onready var _explorer_pane: VBoxContainer = $RootVBox/MainSplit/ExplorerPane
@onready var _chat_pane: VBoxContainer = $RootVBox/MainSplit/CenterSplit/ChatPane
@onready var _explorer_toggle_btn: Button = %ExplorerToggleBtn
@onready var _chat_toggle_btn: Button = %ChatToggleBtn
@onready var _file_menu: PopupMenu = $RootVBox/NavBar/MenuBar/File
@onready var _edit_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Edit
@onready var _git_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Git
@onready var _config_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Config
@onready var _help_menu: PopupMenu = $RootVBox/NavBar/MenuBar/Help
@onready var _about_menu: PopupMenu = $RootVBox/NavBar/MenuBar/About
@onready var _open_file_dlg: FileDialog = $OpenFileDialog
@onready var _open_dir_dlg: FileDialog = $OpenDirDialog
@onready var _save_as_dlg: FileDialog = $SaveAsDialog
@onready var _open_theme_xml_dlg: FileDialog = $OpenThemeXmlDialog
@onready var _overlay: ColorRect = $Overlay
@onready var _dialog_panel: PanelContainer = $Overlay/DialogPanel
@onready var _dialog_title: Label = $Overlay/DialogPanel/DialogVBox/DialogTitle
@onready var _dialog_body: RichTextLabel = $Overlay/DialogPanel/DialogVBox/DialogScroll/DialogBody
@onready var _dialog_input_row: HBoxContainer = $Overlay/DialogPanel/DialogVBox/DialogInputRow
@onready var _dialog_input: LineEdit = $Overlay/DialogPanel/DialogVBox/DialogInputRow/DialogInput
@onready var _dialog_action_btn: Button = $Overlay/DialogPanel/DialogVBox/DialogInputRow/DialogActionBtn
@onready var _dialog_close: Button = $Overlay/DialogPanel/DialogVBox/DialogClose
@onready var _ai_chat_http: HTTPRequest = $AIChatHttp
@onready var _chat_status_banner: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatStatusBanner
@onready var _chat_status_label: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatStatusBanner/ChatStatusVBox/ChatStatusLabel
@onready var _chat_thinking_label: RichTextLabel = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatStatusBanner/ChatStatusVBox/ChatThinkingLabel
@onready var _chat_suggestions_popup: PanelContainer = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatSuggestionsPopup
@onready var _chat_suggestions_list: ItemList = $RootVBox/MainSplit/CenterSplit/ChatPane/ChatSuggestionsPopup/ChatSuggestionsList
@onready var _find_row: HBoxContainer = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow
@onready var _find_input: LineEdit = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindInput
@onready var _find_next: Button = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindNext
@onready var _find_close: Button = $RootVBox/MainSplit/CenterSplit/EditorPane/FindRow/FindClose
@onready var _markdown_preview: RichTextLabel = $RootVBox/MainSplit/CenterSplit/EditorPane/MarkdownPreview

var _dialog_action_callback: Callable = Callable()

var _nerd_font: FontFile
var _workspace_root: String = ""
var _custom_themes: Dictionary = {}  ## User-installed themes loaded from XML files
var _open_files: Array[Dictionary] = []
var _active_index: int = -1
var _suppress_tab: bool = false
var _md_preview_active: bool = false
var _agent_mode: bool = true
var _ai_busy: bool = false
var _ai_provider: String = "nemotron"
var _active_theme: String = "adwaita_darker"
var _current_prompt: String = ""
var _smart_commit_prompt: String = ""
var _model_candidates: Array[String] = []
var _model_candidate_index: int = 0
var _spinner_time: float = 0.0
var _request_start_time: float = 0.0
var _chat_history: Array[Dictionary] = []
var _prompt_history: Array[String] = []
var _prompt_history_idx: int = -1
var _prompt_draft: String = ""
var _explorer_collapsed: bool = false  ## Whether the file explorer pane is hidden
var _chat_collapsed: bool = false      ## Whether the chat pane is hidden
var _explorer_split_offset: int = 0   ## Saved split offset when explorer is collapsed
var _chat_split_offset: int = 0       ## Saved split offset when chat is collapsed
var _os_notify_generation: int = 0    ## Invalidates pending auto-dismiss timers
var _thinking_text: String = ""
var _stream_http: HTTPClient = HTTPClient.new()
var _stream_active: bool = false
var _sse_buf: String = ""
var _stream_reply: String = ""
const SPINNER_FRAMES: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
const OS_NOTIFY_EXPIRE_MS: int = 4000
const OS_NOTIFY_REPLACE_ID: int = 424242
const SPLIT_COLLAPSE_PX: int = 32

const THEMES: Dictionary = {
	"adwaita_darker": {
		"label": "Adwaita Darker",
		"bg_black":   "#000000", "bg_darker":  "#0e0e11", "bg_surface": "#16161b",
		"bg_card":    "#1c1c22", "bg_lighter": "#26262e",
		"fg":         "#deddda", "fg_bright":  "#f6f5f4", "muted":      "#9a9996",
		"blue":       "#62a0ea", "green":      "#57e389", "cyan":       "#5bc8af", "red": "#ed333b",
		"hl_number":  "#ffa348", "hl_symbol":  "#5bc8af", "hl_func":    "#62a0ea",
		"hl_member":  "#99c1f1", "hl_comment": "#9a9996", "hl_string":  "#57e389",
		"hl_keyword": "#dc8add", "hl_type":    "#93ddc2", "hl_const":   "#ffa348",
	},
	"monokai": {
		"label": "Monokai",
		"bg_black":   "#1a1a1a", "bg_darker":  "#1e1e1e", "bg_surface": "#272822",
		"bg_card":    "#2d2e27", "bg_lighter": "#383830",
		"fg":         "#f8f8f2", "fg_bright":  "#ffffff", "muted":      "#75715e",
		"blue":       "#66d9e8", "green":      "#a6e22e", "cyan":       "#66d9e8", "red": "#f92672",
		"hl_number":  "#ae81ff", "hl_symbol":  "#f8f8f2", "hl_func":    "#a6e22e",
		"hl_member":  "#fd971f", "hl_comment": "#75715e", "hl_string":  "#e6db74",
		"hl_keyword": "#f92672", "hl_type":    "#66d9e8", "hl_const":   "#ae81ff",
	},
	"tokyo_night": {
		"label": "Tokyo Night",
		"bg_black":   "#13131e", "bg_darker":  "#16161f", "bg_surface": "#1a1b26",
		"bg_card":    "#1f2035", "bg_lighter": "#292e42",
		"fg":         "#a9b1d6", "fg_bright":  "#c0caf5", "muted":      "#565f89",
		"blue":       "#7aa2f7", "green":      "#9ece6a", "cyan":       "#2ac3de", "red": "#f7768e",
		"hl_number":  "#ff9e64", "hl_symbol":  "#89ddff", "hl_func":    "#7aa2f7",
		"hl_member":  "#73daca", "hl_comment": "#565f89", "hl_string":  "#9ece6a",
		"hl_keyword": "#bb9af7", "hl_type":    "#2ac3de", "hl_const":   "#ff9e64",
	},
	"dracula": {
		"label": "Dracula",
		"bg_black":   "#1a1a2e", "bg_darker":  "#1e1f29", "bg_surface": "#282a36",
		"bg_card":    "#2e3040", "bg_lighter": "#3d3f4e",
		"fg":         "#f8f8f2", "fg_bright":  "#ffffff", "muted":      "#6272a4",
		"blue":       "#8be9fd", "green":      "#50fa7b", "cyan":       "#8be9fd", "red": "#ff5555",
		"hl_number":  "#bd93f9", "hl_symbol":  "#ff79c6", "hl_func":    "#50fa7b",
		"hl_member":  "#ffb86c", "hl_comment": "#6272a4", "hl_string":  "#f1fa8c",
		"hl_keyword": "#ff79c6", "hl_type":    "#8be9fd", "hl_const":   "#bd93f9",
	},
	"catppuccin": {
		"label": "Catppuccin Mocha",
		"bg_black":   "#0e0e14", "bg_darker":  "#11111b", "bg_surface": "#1e1e2e",
		"bg_card":    "#181825", "bg_lighter": "#313244",
		"fg":         "#cdd6f4", "fg_bright":  "#ffffff", "muted":      "#585b70",
		"blue":       "#89b4fa", "green":      "#a6e3a1", "cyan":       "#94e2d5", "red": "#f38ba8",
		"hl_number":  "#fab387", "hl_symbol":  "#89dceb", "hl_func":    "#89b4fa",
		"hl_member":  "#cba6f7", "hl_comment": "#585b70", "hl_string":  "#a6e3a1",
		"hl_keyword": "#cba6f7", "hl_type":    "#94e2d5", "hl_const":   "#fab387",
	},
	"nord": {
		"label": "Nord",
		"bg_black":   "#191d24", "bg_darker":  "#1e2430", "bg_surface": "#2e3440",
		"bg_card":    "#3b4252", "bg_lighter": "#434c5e",
		"fg":         "#d8dee9", "fg_bright":  "#eceff4", "muted":      "#616e88",
		"blue":       "#88c0d0", "green":      "#a3be8c", "cyan":       "#8fbcbb", "red": "#bf616a",
		"hl_number":  "#b48ead", "hl_symbol":  "#81a1c1", "hl_func":    "#88c0d0",
		"hl_member":  "#81a1c1", "hl_comment": "#616e88", "hl_string":  "#a3be8c",
		"hl_keyword": "#81a1c1", "hl_type":    "#8fbcbb", "hl_const":   "#b48ead",
	},
}

const CHAT_SLASH_COMMANDS: Array[Dictionary] = [
	{"cmd": "/tools", "desc": "List all available AI agent tools"},
	{"cmd": "/git status", "desc": "Show repository status, branch & GitHub remote"},
	{"cmd": "/git diff", "desc": "Show repository diff and code changes"},
	{"cmd": "/git log", "desc": "Show recent commit history"},
	{"cmd": "/git commit", "desc": "Generate intelligent Git commit or commit with message"},
	{"cmd": "/git push", "desc": "Push local commits to GitHub repository"},
	{"cmd": "/git pull", "desc": "Pull latest changes from GitHub repository"},
	{"cmd": "/git sync", "desc": "Synchronise with GitHub (Pull & Push)"},
	{"cmd": "/git fetch", "desc": "Fetch remote branches from GitHub"},
	{"cmd": "/git branch", "desc": "List or switch/create branches"},
	{"cmd": "/git checkout ", "desc": "Switch to branch (/git checkout <branch>)"},
	{"cmd": "/git remote", "desc": "Show configured GitHub remotes & URLs"},
	{"cmd": "/git config ", "desc": "Set Git user name and email (/git config <name> <email>)"},
	{"cmd": "/git clone ", "desc": "Clone GitHub repository (/git clone <url>)"},
	{"cmd": "/github", "desc": "Display GitHub repository links and details"},
	{"cmd": "/save", "desc": "Save the active file in editor"},
	{"cmd": "/files", "desc": "Refresh workspace file explorer"},
	{"cmd": "/open ", "desc": "Open file by path (/open <path>)"},
	{"cmd": "/goto ", "desc": "Go to line number (/goto <line>)"},
	{"cmd": "/clear", "desc": "Clear conversation history & chat context"},
	{"cmd": "/compact", "desc": "Compact older conversation context while preserving recent messages"},
	{"cmd": "/cancel", "desc": "Abort running AI request"},
	{"cmd": "/theme", "desc": "Select or import IDE colour theme (/theme list | /theme <name> | /theme import)"},
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
  Alt+Up / Alt+Down Move line

[b]Git & GitHub[/b]
  Ctrl+Shift+G      Git Status & Changes
  Ctrl+Shift+C      Smart Git Commit
  Ctrl+Shift+U      Push to GitHub
  Ctrl+Shift+L      Pull from GitHub

[b]IDE[/b]
  Ctrl+,            Settings
  F1                Help (shortcuts)
  Ctrl+P            Focus explorer
  Ctrl+B            Collapse / expand the File Explorer
  Ctrl+Shift+B      Collapse / expand Chat
  Ctrl+J / K / `    Focus chat input
  Esc               Cancel AI / dismiss dialog

[b]Markdown[/b]
  .md files auto-render with formatted preview
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
	var base_res := ProjectSettings.globalize_path("res://").rstrip("/")
	if DirAccess.dir_exists_absolute(base_res):
		_workspace_root = base_res
	else:
		_workspace_root = base_res.get_base_dir()
	_load_ai_config()
	_load_theme_config()
	_apply_kitty_fish_theme()
	_wire_signals()
	_configure_code_edit()
	_refresh_file_tree()
	_open_untitled()
	_update_ai_status()
	_update_git_status_bar()
	_status_left.text = "READY"
	_status_enc.text = "UTF-8"
	call_deferred("_apply_split_offsets")


func _process(delta: float) -> void:
	if _stream_active:
		_poll_chat_stream()
	if _ai_busy:
		_spinner_time += delta
		var frame_idx: int = int(_spinner_time * 10.0) % SPINNER_FRAMES.size()
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _request_start_time
		var frame: String = SPINNER_FRAMES[frame_idx]
		_chat_status_label.text = "[color=#ffa348]%s[/color] [b]Thinking…[/b] [color=#858585](%.1fs)[/color]\n[color=#858585]AI thoughts (live) · Tip: Use /save, /files, /open, /cancel, /clear[/color]" % [frame, elapsed]
		_status_left.text = "%s Thinking · %s (%.1fs) · esc to cancel" % [frame, _ai_provider, elapsed]
		_refresh_thinking_panel()


func _refresh_thinking_panel() -> void:
	if _chat_thinking_label == null:
		return
	var body: String = _thinking_text.strip_edges()
	if body.is_empty():
		body = "Waiting for the model’s reasoning tokens…"
	_chat_thinking_label.text = "[color=#9a9996][i]%s[/i][/color]" % body.replace("[", "[lb]")


func _extract_reasoning(msg: Dictionary) -> String:
	for key in ["reasoning_content", "reasoning", "thinking", "reasoning_text"]:
		if msg.has(key) and str(msg[key]).strip_edges() != "":
			return str(msg[key]).strip_edges()
	var content := str(msg.get("content", ""))
	var start := content.find("<think>")
	var end := content.find("</think>")
	if start >= 0 and end > start:
		return content.substr(start + 7, end - start - 7).strip_edges()
	return ""


func _start_chat_stream(payload_json: String) -> bool:
	_stop_chat_stream()
	var err := _stream_http.connect_to_host("integrate.api.nvidia.com", 443, TLSOptions.client())
	if err != OK:
		return false
	_stream_active = true
	_sse_buf = ""
	_stream_reply = ""
	_thinking_text = ""
	## Handshake is completed in _poll_chat_stream; stash payload on the client via meta.
	_stream_http.set_meta("payload", payload_json)
	_stream_http.set_meta("sent", false)
	return true


func _stop_chat_stream() -> void:
	_stream_active = false
	if _stream_http.get_status() != HTTPClient.STATUS_DISCONNECTED:
		_stream_http.close()
	_sse_buf = ""


func _poll_chat_stream() -> void:
	_stream_http.poll()
	var st := _stream_http.get_status()
	if st == HTTPClient.STATUS_CONNECTING or st == HTTPClient.STATUS_RESOLVING:
		return
	if st == HTTPClient.STATUS_CONNECTED and not bool(_stream_http.get_meta("sent", false)):
		var headers := PackedStringArray([
			"Content-Type: application/json",
			"Authorization: Bearer " + AIService.get_nvidia_api_key(),
			"Accept: text/event-stream",
		])
		var payload: String = str(_stream_http.get_meta("payload", ""))
		var req_err := _stream_http.request(HTTPClient.METHOD_POST, "/v1/chat/completions", headers, payload)
		_stream_http.set_meta("sent", true)
		if req_err != OK:
			_stop_chat_stream()
			_on_ai_chat_http_completed(HTTPRequest.RESULT_CONNECTION_ERROR, 0, PackedStringArray(), PackedByteArray())
		return
	if st == HTTPClient.STATUS_BODY:
		var chunk := _stream_http.read_response_body_chunk()
		if chunk.size() > 0:
			_sse_buf += chunk.get_string_from_utf8()
			_consume_sse_buffer()
		if not _stream_http.has_response() or _stream_http.get_status() == HTTPClient.STATUS_DISCONNECTED:
			_finish_chat_stream()
		return
	if st == HTTPClient.STATUS_DISCONNECTED or st == HTTPClient.STATUS_CONNECTION_ERROR or st == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
		if not _stream_reply.is_empty() or not _thinking_text.is_empty():
			_finish_chat_stream()
		else:
			_stop_chat_stream()
			_on_ai_chat_http_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())


func _consume_sse_buffer() -> void:
	while true:
		var nl := _sse_buf.find("\n")
		if nl < 0:
			break
		var line := _sse_buf.substr(0, nl).strip_edges()
		_sse_buf = _sse_buf.substr(nl + 1)
		if line.is_empty() or not line.begins_with("data:"):
			continue
		var data := line.substr(5).strip_edges()
		if data == "[DONE]":
			_finish_chat_stream()
			return
		var json := JSON.new()
		if json.parse(data) != OK or not (json.data is Dictionary):
			continue
		var parsed: Dictionary = json.data
		var choices: Array = parsed.get("choices", [])
		if choices.is_empty() or not (choices[0] is Dictionary):
			continue
		var choice: Dictionary = choices[0]
		var delta: Dictionary = choice.get("delta", {}) if choice.get("delta", {}) is Dictionary else {}
		var msg: Dictionary = choice.get("message", {}) if choice.get("message", {}) is Dictionary else {}
		for src in [delta, msg]:
			var thought := _extract_reasoning(src)
			if not thought.is_empty():
				if thought.begins_with(_thinking_text):
					_thinking_text = thought
				else:
					_thinking_text += thought
			var piece := str(src.get("content", ""))
			if not piece.is_empty() and piece != "<null>":
				_stream_reply += piece


func _finish_chat_stream() -> void:
	if not _stream_active and _stream_reply.is_empty() and _thinking_text.is_empty():
		return
	_stop_chat_stream()
	var elapsed: float = maxf(0.1, (Time.get_ticks_msec() / 1000.0) - _request_start_time)
	if _current_prompt.begins_with("__SMART_COMMIT__:"):
		if _stream_reply.strip_edges().is_empty():
			_fallback_smart_commit("Empty AI reply.")
			return
		_finish_smart_commit(_stream_reply.strip_edges(), true)
		return
	var reply := _stream_reply.strip_edges()
	if reply.is_empty() and not _thinking_text.is_empty():
		reply = _thinking_text.strip_edges()
	if reply.is_empty():
		if _try_next_ai_candidate("Empty stream. Attempting candidate model…"):
			return
		_append_chat(_ai_provider.to_upper(), "Empty server response. Please retry.", Color("#ed333b"))
		return
	_chat_history.append({"role": "assistant", "content": reply})
	_clear_ai_busy()
	_append_ai_response(_ai_provider, reply, elapsed)


func _apply_split_offsets() -> void:
	var w: float = size.x
	if w <= 1.0:
		w = get_viewport_rect().size.x
	if not _explorer_collapsed:
		_main_split.split_offset = int(w * 0.18)
		_explorer_split_offset = _main_split.split_offset
	if not _chat_collapsed:
		_center_split.split_offset = int(w * 0.50)
		_chat_split_offset = _center_split.split_offset


func _toggle_explorer() -> void:
	if _explorer_collapsed:
		_expand_explorer()
	else:
		_collapse_explorer(true)


func _toggle_chat() -> void:
	if _chat_collapsed:
		_expand_chat()
	else:
		_collapse_chat(true)


func _expand_explorer() -> void:
	_explorer_collapsed = false
	_explorer_pane.visible = true
	var target := _explorer_split_offset if _explorer_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.18)
	_main_split.split_offset = target
	_status_left.text = "Explorer  ▶  shown"


func _collapse_explorer(save_offset: bool) -> void:
	if _explorer_collapsed:
		return
	if save_offset and _main_split.split_offset > SPLIT_COLLAPSE_PX:
		_explorer_split_offset = _main_split.split_offset
	_explorer_collapsed = true
	_explorer_pane.visible = false
	_status_left.text = "Explorer  ◀  hidden  (Ctrl+B to restore)"


func _expand_chat() -> void:
	_chat_collapsed = false
	_chat_pane.visible = true
	var target := _chat_split_offset if _chat_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.50)
	_center_split.split_offset = target
	_status_left.text = "Chat  ▶  shown"


func _collapse_chat(save_offset: bool) -> void:
	if _chat_collapsed:
		return
	if save_offset and _center_split.split_offset > SPLIT_COLLAPSE_PX:
		_chat_split_offset = _center_split.split_offset
	_chat_collapsed = true
	_chat_pane.visible = false
	_status_left.text = "Chat  ◀  hidden  (Ctrl+Shift+B to restore)"

func _on_main_split_dragged(offset: int) -> void:
	if _explorer_collapsed:
		return
	if offset > SPLIT_COLLAPSE_PX:
		_explorer_split_offset = offset
		return
	_collapse_explorer(false)


func _on_center_split_dragged(offset: int) -> void:
	if _chat_collapsed:
		return
	var remaining: int = int(_center_split.size.x) - offset
	if remaining > SPLIT_COLLAPSE_PX:
		_chat_split_offset = offset
		return
	_collapse_chat(false)


func _wire_signals() -> void:
	_file_tree.item_activated.connect(_on_tree_item_activated)
	_file_tree.item_selected.connect(_on_tree_item_selected)
	_file_tree.item_collapsed.connect(_on_tree_item_collapsed)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_tab_bar.tab_close_pressed.connect(_on_tab_close)
	_code_edit.text_changed.connect(_on_code_changed)
	_code_edit.caret_changed.connect(_on_caret_changed)
	_chat_input.text_submitted.connect(_on_chat_submitted)
	_chat_input.text_changed.connect(_on_chat_input_text_changed)
	_chat_input.gui_input.connect(_on_chat_input_gui_input)
	_chat_send.pressed.connect(_on_chat_send_pressed)
	_chat_context_chip.pressed.connect(_on_context_chip_pressed)
	_attach_btn.pressed.connect(_on_attach_btn_pressed)
	_agent_mode_btn.pressed.connect(_on_agent_mode_pressed)
	_smart_commit_btn.pressed.connect(_generate_smart_commit)
	_file_menu.id_pressed.connect(_on_file_menu)
	_edit_menu.id_pressed.connect(_on_edit_menu)
	if _git_menu:
		_git_menu.id_pressed.connect(_on_git_menu)
	if _status_git:
		_status_git.pressed.connect(_show_git_status_dialog)
	_config_menu.id_pressed.connect(_on_config_menu)
	_help_menu.id_pressed.connect(_on_help_menu)
	_about_menu.id_pressed.connect(_on_about_menu)
	_open_file_dlg.file_selected.connect(_open_path)
	_open_dir_dlg.dir_selected.connect(_on_dir_selected)
	_save_as_dlg.file_selected.connect(_save_as_path)
	if _open_theme_xml_dlg:
		_open_theme_xml_dlg.file_selected.connect(_import_theme_from_xml)
	_dialog_close.pressed.connect(_hide_overlay)
	if _dialog_action_btn:
		_dialog_action_btn.pressed.connect(_on_dialog_action_pressed)
	if _dialog_input:
		_dialog_input.text_submitted.connect(func(_t: String) -> void: _on_dialog_action_pressed())
	_ai_chat_http.request_completed.connect(_on_ai_chat_http_completed)
	_provider_select.item_selected.connect(_on_provider_selected)
	_find_input.text_submitted.connect(_do_find)
	_find_next.pressed.connect(_on_find_next)
	_find_close.pressed.connect(func() -> void: _find_row.visible = false)
	_chat_suggestions_list.item_selected.connect(_on_chat_suggestion_selected)
	_chat_suggestions_list.item_activated.connect(_on_chat_suggestion_selected)
	_main_split.dragged.connect(_on_main_split_dragged)
	_center_split.dragged.connect(_on_center_split_dragged)
	_explorer_toggle_btn.pressed.connect(_toggle_explorer)
	_chat_toggle_btn.pressed.connect(_toggle_chat)


func _input(event: InputEvent) -> void:
	## ESC must run before CodeEdit consumes it, so the editor can lose focus
	## and subsequent shortcuts reach `_unhandled_input`.
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.keycode != KEY_ESCAPE:
		return
	_handle_escape()
	get_viewport().set_input_as_handled()


func _handle_escape() -> void:
	if _find_row.visible:
		_find_row.visible = false
		return
	if _chat_suggestions_popup.visible:
		_chat_suggestions_popup.visible = false
		return
	if _dialog_panel.visible:
		_hide_overlay()
		return
	if _ai_busy:
		_cancel_ai_request()
		return
	get_viewport().gui_release_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	var ctrl: bool = key.ctrl_pressed
	var shift: bool = key.shift_pressed
	var alt: bool = key.alt_pressed

	# Code completion (Ctrl+Space)
	if ctrl and key.keycode == KEY_SPACE:
		_update_code_completion()
		_code_edit.request_code_completion(true)
		get_viewport().set_input_as_handled()
		return

	# Help / Shortcuts (F1)
	if key.keycode == KEY_F1:
		_show_help()
		get_viewport().set_input_as_handled()
		return

	# Settings (Ctrl+,)
	if ctrl and key.keycode == KEY_COMMA:
		_show_config()
		get_viewport().set_input_as_handled()
		return

	# Git & GitHub Operations (Ctrl+Shift+G / C / U / L)
	if ctrl and shift and key.keycode == KEY_G:
		_show_git_status_dialog()
		get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_C:
		_generate_smart_commit()
		get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_U:
		_git_push()
		get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_L:
		_git_pull()
		get_viewport().set_input_as_handled()
		return

	# File Operations
	if ctrl and shift and key.keycode == KEY_O:
		_open_dir_dlg.popup_centered()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_O:
		_open_file_dlg.popup_centered()
		get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_S:
		_save_as_dlg.popup_centered()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_S:
		_save_active()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_N:
		_open_untitled()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_W:
		if _active_index >= 0:
			_on_tab_close(_active_index)
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_Q:
		get_tree().quit()
		get_viewport().set_input_as_handled()
		return

	# Tab Navigation (Ctrl+Tab / Ctrl+Shift+Tab)
	if ctrl and shift and key.keycode == KEY_TAB:
		_switch_tab(-1)
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_TAB:
		_switch_tab(1)
		get_viewport().set_input_as_handled()
		return

	# Panels & Focus Navigation
	if ctrl and not shift and key.keycode == KEY_B:
		_toggle_explorer()
		get_viewport().set_input_as_handled()
		return
	if ctrl and shift and key.keycode == KEY_B:
		_toggle_chat()
		get_viewport().set_input_as_handled()
		return
	if ctrl and (key.keycode == KEY_J or key.keycode == KEY_K or key.keycode == KEY_QUOTELEFT):
		if _chat_collapsed:
			_toggle_chat()
		_chat_input.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_P:
		if _explorer_collapsed:
			_toggle_explorer()
		_file_tree.grab_focus()
		get_viewport().set_input_as_handled()
		return

	# Find & Replace (Ctrl+F)
	if ctrl and key.keycode == KEY_F:
		_find_row.visible = true
		_find_input.grab_focus()
		get_viewport().set_input_as_handled()
		return

	# Go to Line (Ctrl+G)
	if ctrl and key.keycode == KEY_G:
		_chat_input.text = "/goto "
		_chat_input.grab_focus()
		_chat_input.caret_column = _chat_input.text.length()
		get_viewport().set_input_as_handled()
		return

	# Code Editing Shortcuts
	if ctrl and key.keycode == KEY_SLASH:
		_toggle_comment()
		get_viewport().set_input_as_handled()
		return
	if ctrl and key.keycode == KEY_D:
		_duplicate_line()
		get_viewport().set_input_as_handled()
		return
	if alt and key.keycode == KEY_UP:
		_move_line(-1)
		get_viewport().set_input_as_handled()
		return
	if alt and key.keycode == KEY_DOWN:
		_move_line(1)
		get_viewport().set_input_as_handled()
		return


func _select_tab(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _open_files.size() or tab_idx == _active_index:
		return
	_save_editor_state_to_active()
	_active_index = tab_idx
	_tab_bar.current_tab = tab_idx
	_load_active_into_editor()


func _switch_tab(offset: int) -> void:
	if _open_files.size() <= 1:
		return
	var new_idx: int = (_active_index + offset) % _open_files.size()
	if new_idx < 0:
		new_idx += _open_files.size()
	_select_tab(new_idx)


func _on_chat_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key: InputEventKey = event
	if key.keycode == KEY_UP and not _chat_suggestions_popup.visible:
		if _prompt_history.is_empty():
			return
		if _prompt_history_idx == -1:
			_prompt_draft = _chat_input.text
			_prompt_history_idx = _prompt_history.size() - 1
		elif _prompt_history_idx > 0:
			_prompt_history_idx -= 1
		_chat_input.text = _prompt_history[_prompt_history_idx]
		_chat_input.caret_column = _chat_input.text.length()
		_chat_input.accept_event()
	elif key.keycode == KEY_DOWN and not _chat_suggestions_popup.visible:
		if _prompt_history_idx == -1:
			return
		if _prompt_history_idx < _prompt_history.size() - 1:
			_prompt_history_idx += 1
			_chat_input.text = _prompt_history[_prompt_history_idx]
		else:
			_prompt_history_idx = -1
			_chat_input.text = _prompt_draft
		_chat_input.caret_column = _chat_input.text.length()
		_chat_input.accept_event()


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


func _on_git_menu(id: int) -> void:
	match id:
		0: _show_git_status_dialog()
		1: _generate_smart_commit()
		2: _git_push()
		3: _git_pull()
		4: _git_fetch()
		5: _git_sync()
		7: _prompt_git_branch()
		8: _show_git_log_dialog()
		9: _show_git_diff_dialog()
		11: _show_github_info_dialog()
		12: _prompt_git_config()


func _on_config_menu(id: int) -> void:
	match id:
		0: _show_config()
		1: _prompt_api_key(true, Callable())


func _on_help_menu(_id: int) -> void:
	_show_help()


func _on_about_menu(_id: int) -> void:
	_show_about()


func _show_overlay(title: String, body: String) -> void:
	_dialog_title.text = title
	_dialog_body.text = body
	_dialog_body.visible = true
	if _dialog_input_row:
		_dialog_input_row.visible = false
	_dialog_panel.visible = true
	_overlay.visible = true


func _show_input_dialog(title: String, body: String, placeholder: String, default_val: String, btn_label: String, callback: Callable, secret: bool = false) -> void:
	_dialog_title.text = title
	_dialog_body.text = body
	_dialog_body.visible = true
	if _dialog_input_row:
		_dialog_input_row.visible = true
		_dialog_input.placeholder_text = placeholder
		_dialog_input.text = default_val
		_dialog_input.secret = secret
		_dialog_action_btn.text = btn_label
	_dialog_action_callback = callback
	_dialog_panel.visible = true
	_overlay.visible = true
	if _dialog_input:
		_dialog_input.grab_focus()
		_dialog_input.select_all()


func _on_dialog_action_pressed() -> void:
	if _dialog_action_callback.is_valid():
		var val: String = _dialog_input.text.strip_edges() if _dialog_input else ""
		var cb: Callable = _dialog_action_callback
		_dialog_action_callback = Callable()
		_hide_overlay()
		cb.call(val)
	else:
		_hide_overlay()


func _hide_overlay() -> void:
	_dialog_panel.visible = false
	_overlay.visible = false
	_dialog_action_callback = Callable()
	if _dialog_input:
		_dialog_input.secret = false
		_dialog_input.text = ""


func _update_git_status_bar() -> void:
	if not _status_git:
		return
	if not GitService.is_git_repository(_workspace_root):
		_status_git.text = "⎇ no git"
		_status_git.add_theme_color_override("font_color", Color("#9a9996"))
		return
	var st: Dictionary = GitService.get_status(_workspace_root)
	var branch: String = str(st.get("branch", "main"))
	var is_clean: bool = bool(st.get("is_clean", true))
	if is_clean:
		_status_git.text = "⎇ " + branch
		_status_git.add_theme_color_override("font_color", Color("#57e389"))
	else:
		var staged: Array = st.get("staged", [])
		var unstaged: Array = st.get("unstaged", [])
		var untracked: Array = st.get("untracked", [])
		var total: int = staged.size() + unstaged.size() + untracked.size()
		_status_git.text = "⎇ %s *(%d)" % [branch, total]
		_status_git.add_theme_color_override("font_color", Color("#ffa348"))


func _show_git_status_dialog() -> void:
	var st: Dictionary = GitService.get_status(_workspace_root)
	var gh: Dictionary = GitService.get_github_info(_workspace_root)
	_show_overlay("Git Repository Status", GitService.format_status_bbcode(st, gh))
	_update_git_status_bar()


func _show_git_log_dialog() -> void:
	var log_entries: Array[Dictionary] = GitService.get_log(20, _workspace_root)
	_show_overlay("Git Commit History", GitService.format_log_bbcode(log_entries))


func _show_git_diff_dialog() -> void:
	var diff_res: Dictionary = GitService.get_diff("", false, _workspace_root)
	_show_overlay("Working Tree Diff", GitService.format_diff_bbcode(str(diff_res.get("output", ""))))


func _show_github_info_dialog() -> void:
	var gh: Dictionary = GitService.get_github_info(_workspace_root)
	var body := "[b][color=#62a0ea]GitHub Repository Information[/color][/b]\n\n"
	if bool(gh.get("is_github", false)):
		body += "• [b]Repository:[/b] [color=#57e389]%s[/color]\n" % str(gh.get("full_name", ""))
		body += "• [b]Owner:[/b] %s\n" % str(gh.get("owner", ""))
		body += "• [b]Current Branch:[/b] %s\n" % str(gh.get("current_branch", "main"))
		body += "• [b]Remote URL:[/b] %s\n\n" % str(gh.get("remote_url", ""))
		body += "[b]Quick Web Links:[/b]\n"
		body += "• [color=#62a0ea][u]%s[/u][/color]\n" % str(gh.get("web_url", ""))
		body += "• Commits: [color=#62a0ea][u]%s[/u][/color]\n" % str(gh.get("commits_url", ""))
		body += "• Pull Requests: [color=#62a0ea][u]%s[/u][/color]\n" % str(gh.get("pulls_url", ""))
		body += "• Issues: [color=#62a0ea][u]%s[/u][/color]\n" % str(gh.get("issues_url", ""))
	else:
		body += "[color=#ffa348]No GitHub remote detected for origin.[/color]\n"
		body += "Configured Remote URL: %s\n" % str(gh.get("remote_url", "none"))
	_show_overlay("GitHub Repository", body)


func _prompt_git_branch() -> void:
	var branches: Array[Dictionary] = GitService.get_branches(_workspace_root)
	var branch_list := ""
	for b in branches:
		var prefix := "● " if bool(b.get("is_current", false)) else "  "
		branch_list += prefix + str(b.get("display_name", "")) + "\n"
	var current: String = GitService.get_current_branch(_workspace_root)
	_show_input_dialog(
		"Switch / New Branch",
		"[b]Current Branches:[/b]\n" + branch_list + "\nEnter branch name to switch or create (prefix with '+' to create a new branch):",
		"branch-name or +new-branch",
		current,
		"Switch / Create",
		func(val: String) -> void:
			if val.is_empty():
				return
			var create_new := false
			var target_b := val
			if target_b.begins_with("+") or target_b.begins_with("-b "):
				create_new = true
				target_b = target_b.trim_prefix("+").trim_prefix("-b ").strip_edges()
			var res: Dictionary = GitService.checkout_branch(target_b, create_new, _workspace_root)
			if bool(res.get("success", false)):
				_append_chat("GIT", "[color=#57e389]Switched to branch '%s' successfully.[/color]" % target_b, Color("#57e389"))
				_show_toast("Switched to branch: " + target_b, false)
			else:
				_append_chat("GIT", "[color=#ed333b]Failed to switch branch:\n" + str(res.get("output", "")) + "[/color]", Color("#ed333b"))
				_show_toast("Branch switch failed.", true)
			_update_git_status_bar()
	)


func _prompt_git_config() -> void:
	var cfg: Dictionary = GitService.get_user_config(_workspace_root)
	var def_val: String = "%s <%s>" % [str(cfg.get("name", "")), str(cfg.get("email", ""))]
	_show_input_dialog(
		"Configure Git User",
		"[b]Git User Configuration[/b]\nFormat: `Your Name <your.email@example.com>`",
		"Name <email@example.com>",
		def_val if def_val != " <>" else "",
		"Save Config",
		func(val: String) -> void:
			if val.is_empty():
				return
			var name_part := val
			var email_part := ""
			if val.contains("<") and val.contains(">"):
				var start_idx := val.find("<")
				var end_idx := val.find(">")
				name_part = val.substr(0, start_idx).strip_edges()
				email_part = val.substr(start_idx + 1, end_idx - start_idx - 1).strip_edges()
			var res: Dictionary = GitService.set_user_config(name_part, email_part, false, _workspace_root)
			if bool(res.get("success", false)):
				_append_chat("GIT", "[color=#57e389]Git user configured: %s <%s>[/color]" % [name_part, email_part], Color("#57e389"))
				_show_toast("Git user configured.", false)
			else:
				_show_toast("Failed to configure Git user.", true)
	)


func _prompt_git_clone() -> void:
	_show_input_dialog(
		"Clone Repository",
		"[b]Clone a GitHub Repository[/b]\nEnter the repository URL (SSH or HTTPS):",
		"git@github.com:user/repo.git",
		"",
		"Clone",
		func(url: String) -> void:
			if url.is_empty():
				return
			var target_dir: String = _workspace_root.path_join(url.get_file().trim_suffix(".git"))
			_show_toast("Cloning repository…", false)
			var res: Dictionary = GitService.clone_repository(url, target_dir)
			if bool(res.get("success", false)):
				_append_chat("GIT", "[color=#57e389]Repository cloned to %s[/color]" % target_dir, Color("#57e389"))
				_refresh_file_tree()
				_update_git_status_bar()
			else:
				_append_chat("GIT", "[b][color=#ed333b]Failed to clone repository:[/color][/b]\n" + str(res.get("output", "")), Color("#ed333b"))
				_show_toast("Git clone failed. Check chat for details.", true)
	)


func _git_push(remote: String = "origin", branch: String = "") -> void:
	_show_toast("Pushing commits to GitHub…", false)
	var res: Dictionary = GitService.push(remote, branch, true, _workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Everything up-to-date."
		_append_chat("GIT", "[b][color=#57e389]Push to GitHub succeeded:[/color][/b]\n" + out_txt, Color("#57e389"))
		_show_toast("Push to GitHub completed successfully!", false)
	else:
		_append_chat("GIT", "[b][color=#ed333b]Git push error:[/color][/b]\n" + str(res.get("output", "")), Color("#ed333b"))
		_show_toast("Git push failed. Check chat for details.", true)
	_update_git_status_bar()


func _git_pull(remote: String = "origin", branch: String = "") -> void:
	_show_toast("Pulling changes from GitHub…", false)
	var res: Dictionary = GitService.pull(remote, branch, false, _workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Already up to date."
		_append_chat("GIT", "[b][color=#57e389]Pull from GitHub succeeded:[/color][/b]\n" + out_txt, Color("#57e389"))
		_show_toast("Pull from GitHub completed!", false)
		_refresh_file_tree()
	else:
		_append_chat("GIT", "[b][color=#ed333b]Git pull error:[/color][/b]\n" + str(res.get("output", "")), Color("#ed333b"))
		_show_toast("Git pull failed.", true)
	_update_git_status_bar()


func _git_fetch(remote: String = "origin") -> void:
	_show_toast("Fetching from %s…" % remote, false)
	var res: Dictionary = GitService.fetch(remote, _workspace_root)
	if bool(res.get("success", false)):
		_append_chat("GIT", "[color=#57e389]Fetch completed successfully.[/color]", Color("#57e389"))
		_show_toast("Fetch completed.", false)
	else:
		_append_chat("GIT", "[color=#ed333b]Fetch error:\n" + str(res.get("output", "")) + "[/color]", Color("#ed333b"))
	_update_git_status_bar()


func _git_sync(remote: String = "origin", branch: String = "") -> void:
	_show_toast("Synchronising with GitHub (Pull & Push)…", false)
	var res: Dictionary = GitService.sync(remote, branch, _workspace_root)
	if bool(res.get("success", false)):
		_append_chat("GIT", "[b][color=#57e389]GitHub Sync Succeeded:[/color][/b]\n" + str(res.get("output", "")), Color("#57e389"))
		_show_toast("GitHub synchronisation completed!", false)
		_refresh_file_tree()
	else:
		_append_chat("GIT", "[b][color=#ed333b]GitHub Sync Error (%s):[/color][/b]\n%s" % [str(res.get("stage", "sync")), str(res.get("error", ""))], Color("#ed333b"))
		_show_toast("Sync failed. Check chat log.", true)
	_update_git_status_bar()


func _show_help() -> void:
	_show_overlay("Help · Shortcuts", HELP_TEXT)


func _show_about() -> void:
	_show_overlay("About", ABOUT_TEXT)


func _show_config() -> void:
	var key_state := "saved on this machine" if not AIService._read_stored_api_key().is_empty() else "not saved"
	if not OS.get_environment(AIService.NVIDIA_API_KEY_ENV).strip_edges().is_empty():
		key_state = "set via process environment"
	var body := "[b]Settings[/b]\n\n• [b]Typography:[/b] FiraCode Nerd Font\n• [b]Workspace:[/b] %s\n• [b]Active Model:[/b] %s (NVIDIA NIM)\n• [b]API key:[/b] %s\n• [b]Status:[/b] %s\n\nUse Config → NVIDIA NIM API key… to change the stored key." % [
		_workspace_root,
		_ai_provider.replace("_", " ").to_upper(),
		key_state,
		"Ready" if AIService.has_nvidia_api_key() else "API key required",
	]
	_show_overlay("Settings", body)


func _ensure_api_key(after: Callable) -> void:
	if AIService.has_nvidia_api_key():
		if after.is_valid():
			after.call()
		return
	_prompt_api_key(false, after)


func _prompt_api_key(force: bool, after: Callable) -> void:
	var existing := AIService._read_stored_api_key()
	var body := "The NVIDIA NIM API key is stored only on this machine (Godot user data) and is never committed with the project.\n\nPaste the key below. Leave empty and confirm to remove a stored key." if force else "To use the chat assistant you need an NVIDIA NIM API key.\n\nIt will be saved on this machine so you do not have to enter it again. You can change it later under Config → NVIDIA NIM API key…"
	_show_input_dialog(
		"NVIDIA NIM API key",
		body,
		"nvapi-…",
		existing if force else "",
		"Save",
		func(val: String) -> void:
			if val.is_empty() and not force:
				_show_toast("API key not set. Chat is unavailable until you add one.", true)
				return
			if not AIService.set_stored_nvidia_api_key(val):
				_show_toast("Could not save the API key.", true)
				return
			if val.is_empty():
				_show_toast("Stored API key removed.", false)
			else:
				_show_toast("API key saved.", false)
			_update_ai_status()
			if after.is_valid() and AIService.has_nvidia_api_key():
				after.call(), true)


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
	_chat_send.text = "↑"


func _save_ai_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ai", "provider", _ai_provider)
	cfg.save("user://ai_config.cfg")


func _all_themes() -> Dictionary:
	## Returns built-in themes merged with any user-installed XML themes
	var merged := THEMES.duplicate()
	for key in _custom_themes:
		merged[key] = _custom_themes[key]
	return merged


func _load_theme_config() -> void:
	_load_custom_themes()
	var cfg := ConfigFile.new()
	if cfg.load("user://ui_config.cfg") == OK:
		_active_theme = str(cfg.get_value("theme", "name", "adwaita_darker"))
	if not _all_themes().has(_active_theme):
		_active_theme = "adwaita_darker"


func _save_theme_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ui_config.cfg")
	cfg.set_value("theme", "name", _active_theme)
	cfg.save("user://ui_config.cfg")


func _apply_theme_by_name(_name: String) -> void:
	_active_theme = _name
	_save_theme_config()
	_apply_kitty_fish_theme()
	var label: String = str(_all_themes().get(_name, {}).get("label", _name))
	_append_chat("IDE", "[color=#57e389]Theme applied:[/color] [b]" + label + "[/b]", Color("#57e389"))
	_show_toast("Theme: " + label, false)


func _show_theme_picker() -> void:
	var all := _all_themes()
	var body := "[b][color=#62a0ea]Available themes:[/color][/b]\n\n"
	for key: String in all.keys():
		var t: Dictionary = all[key]
		var active_mark := "  [color=#57e389]✓ active[/color]" if key == _active_theme else ""
		var custom_mark := "  [color=#ffa348]⬡ XML[/color]" if _custom_themes.has(key) else ""
		body += "• [b]%s[/b]%s%s\n  [color=#9a9996]/theme %s[/color]\n\n" % [str(t.get("label", key)), active_mark, custom_mark, key]
	body += "[color=#9a9996]Usage: /theme <name>   e.g. /theme dracula\n"
	body += "/theme import — install a theme from a .xml file[/color]"
	_show_overlay("Select theme", body)


func _load_custom_themes() -> void:
	## Scans user://themes/ and loads all valid .xml theme files into _custom_themes
	_custom_themes.clear()
	var dir := DirAccess.open("user://themes")
	if dir == null:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://themes"))
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir() and fname.ends_with(".xml"):
			var path := "user://themes/" + fname
			var result := _parse_theme_xml(path)
			if not result.is_empty():
				var key: String = str(result.get("key", fname.trim_suffix(".xml")))
				_custom_themes[key] = result
		fname = dir.get_next()
	dir.list_dir_end()


func _parse_theme_xml(path: String) -> Dictionary:
	## Parses an XML theme file and returns a theme Dictionary, or empty if invalid.
	## Expected format:
	##   <theme name="my_theme" label="My Theme Label">
	##     <colour key="bg_black" value="#1a1a2e"/>
	##     ...
	##   </theme>
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
	## Validate that the minimum required keys are present
	var required := ["bg_surface", "fg", "blue", "green"]
	for req in required:
		if not result.has(req):
			return {}
	return result


func _import_theme_xml_dialog() -> void:
	## Opens a file picker to select a .xml theme file for import
	if _open_theme_xml_dlg:
		_open_theme_xml_dlg.popup_centered(Vector2i(800, 500))
	else:
		_append_chat("IDE", "[color=#ed333b]Theme import dialogue is not available.[/color]", Color("#ed333b"))


func _import_theme_from_xml(xml_path: String) -> void:
	## Imports a theme from the given .xml path into user://themes/
	var parsed := _parse_theme_xml(xml_path)
	if parsed.is_empty():
		_append_chat("IDE", "[color=#ed333b]Invalid XML file or incomplete theme.[/color]\nCheck the format: [color=#9a9996]<theme name=\"id\" label=\"Name\">[/color]", Color("#ed333b"))
		_show_toast("Theme XML: invalid format.", true)
		return
	## Copy file into user://themes/
	var dest_name: String = str(parsed.get("key", "custom")) + ".xml"
	var dest_path := "user://themes/" + dest_name
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://themes"))
	var src := FileAccess.open(xml_path, FileAccess.READ)
	if src == null:
		_append_chat("IDE", "[color=#ed333b]Could not read the XML file.[/color]", Color("#ed333b"))
		return
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(dest_path, FileAccess.WRITE)
	if dst == null:
		_append_chat("IDE", "[color=#ed333b]Could not save the theme to user://themes/.[/color]", Color("#ed333b"))
		return
	dst.store_string(content)
	dst.close()
	## Reload and apply
	_load_custom_themes()
	var key: String = str(parsed.get("key", "custom"))
	var label: String = str(parsed.get("label", key))
	_apply_theme_by_name(key)
	_append_chat("IDE", "[color=#57e389]Theme imported:[/color] [b]" + label + "[/b]\nSaved to: [color=#9a9996]" + dest_path + "[/color]", Color("#57e389"))
	_show_toast("Theme installed: " + label, false)


func _update_ai_status() -> void:
	var titles := {
		"nemotron": "Nemotron 3 Omni",
		"nemotron_lightning": "Nemotron 3.5 Lightning",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_ai_provider, "Nemotron 3 Omni")
	if AIService.has_nvidia_api_key():
		_status_ai.text = "AI: %s · on" % display_title
	else:
		_status_ai.text = "AI: %s · key needed" % display_title
	_chat_context_badge.text = "Local · Autopilot"
	_chat_input.placeholder_text = "Describe what to build or ask %s…" % display_title


func _apply_style_if_unset(control: Control, _name: StringName, style: StyleBox) -> void:
	if not control.has_theme_stylebox_override(_name):
		control.add_theme_stylebox_override(_name, style)


func _apply_kitty_fish_theme() -> void:
	## Resolve active palette from THEMES dict
	var p: Dictionary = THEMES.get(_active_theme, THEMES["adwaita_darker"])
	var bg_black   := Color(str(p.get("bg_black",   "#000000")))
	var bg_surface := Color(str(p.get("bg_surface", "#16161b")))
	var bg_card    := Color(str(p.get("bg_card",    "#1c1c22")))
	var bg_lighter := Color(str(p.get("bg_lighter", "#26262e")))
	var fg         := Color(str(p.get("fg",         "#deddda")))
	var fg_bright  := Color(str(p.get("fg_bright",  "#f6f5f4")))
	var muted      := Color(str(p.get("muted",      "#9a9996")))
	var blue       := Color(str(p.get("blue",       "#62a0ea")))
	var green      := Color(str(p.get("green",      "#57e389")))
	var cyan       := Color(str(p.get("cyan",       "#5bc8af")))
	var red        := Color(str(p.get("red",        "#ed333b")))

	## Background
	$Background.color = bg_black

	## NavBar
	var nav_bar: HBoxContainer = $RootVBox/NavBar
	var nav_sb := StyleBoxFlat.new()
	nav_sb.bg_color = bg_black
	nav_bar.add_theme_stylebox_override("panel", nav_sb)

	## Explorer
	var explorer_header: Label = $RootVBox/MainSplit/ExplorerPane/ExplorerHeader
	explorer_header.add_theme_color_override("font_color", muted)
	var explorer_sb := StyleBoxFlat.new()
	explorer_sb.bg_color = bg_black
	_apply_style_if_unset($RootVBox/MainSplit/ExplorerPane, "panel", explorer_sb)
	_file_tree.add_theme_color_override("font_color", fg)
	_file_tree.add_theme_color_override("font_selected_color", blue)
	var tree_bg_sb := StyleBoxFlat.new()
	tree_bg_sb.bg_color = bg_black
	_file_tree.add_theme_stylebox_override("panel", tree_bg_sb)
	_file_tree.add_theme_stylebox_override("focus", tree_bg_sb)

	## CodeEdit — palette-driven colours (styleboxes fill gutter/minimap, not just font bg)
	var code_sb := StyleBoxFlat.new()
	code_sb.bg_color = bg_black
	_code_edit.add_theme_stylebox_override("normal", code_sb)
	_code_edit.add_theme_stylebox_override("focus", code_sb)
	_code_edit.add_theme_stylebox_override("read_only", code_sb)
	_code_edit.add_theme_color_override("background_color", bg_black)
	_code_edit.add_theme_color_override("caret_background_color", bg_black)
	_code_edit.add_theme_color_override("gutter_background_color", bg_black)
	_code_edit.add_theme_color_override("minimap_background_color", bg_black)
	_code_edit.add_theme_color_override("font_color", fg)
	_code_edit.add_theme_color_override("current_line_color", bg_surface)
	_code_edit.add_theme_color_override("selection_color", bg_lighter)
	_code_edit.add_theme_color_override("line_number_color", muted.darkened(0.2))
	_code_edit.add_theme_color_override("caret_color", fg_bright)
	_code_edit.add_theme_color_override("word_highlighted_color", bg_lighter)
	_code_edit.add_theme_color_override("brace_mismatch_color", red)
	_code_edit.syntax_highlighter = _create_adwaita_fish_highlighter()

	## Markdown Preview
	var md_sb := StyleBoxFlat.new()
	md_sb.bg_color = bg_black
	md_sb.set_content_margin_all(24)
	_markdown_preview.add_theme_stylebox_override("normal", md_sb)
	_markdown_preview.add_theme_color_override("default_color", fg)
	_markdown_preview.add_theme_font_size_override("normal_font_size", 15)
	_markdown_preview.add_theme_font_size_override("bold_font_size", 15)
	_markdown_preview.add_theme_font_size_override("italics_font_size", 15)

	## TabBar
	_tab_bar.add_theme_color_override("font_selected_color", fg_bright)
	_tab_bar.add_theme_color_override("font_unselected_color", muted)
	var tab_bg := StyleBoxFlat.new()
	tab_bg.bg_color = bg_black
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = bg_black
	tab_selected.border_color = blue
	tab_selected.border_width_bottom = 1
	_tab_bar.add_theme_stylebox_override("tab_unselected", tab_bg)
	_tab_bar.add_theme_stylebox_override("tab_selected", tab_selected)
	_tab_bar.add_theme_stylebox_override("tab_hovered", tab_bg)

	## Chat pane
	_chat_log.add_theme_color_override("default_color", fg)
	var chat_log_sb := StyleBoxFlat.new()
	chat_log_sb.bg_color = bg_black
	chat_log_sb.set_content_margin_all(10)
	_apply_style_if_unset(_chat_log, "normal", chat_log_sb)

	## Chat Input Card
	var input_card_sb := StyleBoxFlat.new()
	input_card_sb.bg_color = bg_black
	input_card_sb.border_color = bg_lighter
	input_card_sb.set_border_width_all(1)
	input_card_sb.set_corner_radius_all(14)
	input_card_sb.set_content_margin_all(8)
	_apply_style_if_unset(_chat_input_card, "panel", input_card_sb)

	var chat_input_sb := StyleBoxEmpty.new()
	chat_input_sb.set_content_margin_all(4)
	_chat_input.add_theme_stylebox_override("normal", chat_input_sb)
	_chat_input.add_theme_stylebox_override("focus", chat_input_sb)
	_chat_input.add_theme_color_override("font_color", fg_bright)
	_chat_input.add_theme_color_override("font_placeholder_color", muted)

	## Action toolbar buttons
	var btn_tool_sb := StyleBoxFlat.new()
	btn_tool_sb.bg_color = bg_lighter
	btn_tool_sb.set_corner_radius_all(6)
	btn_tool_sb.set_content_margin_all(4)
	for btn: Button in [_attach_btn, _agent_mode_btn, _smart_commit_btn, _chat_context_chip]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_tool_sb)
			btn.add_theme_color_override("font_color", fg_bright)

	## Send button
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

	## Chat header & actions
	_chat_header.add_theme_color_override("font_color", fg_bright)
	_chat_context_badge.add_theme_color_override("font_color", cyan)

	var btn_pill_sb := StyleBoxFlat.new()
	btn_pill_sb.bg_color = bg_lighter
	btn_pill_sb.set_corner_radius_all(6)
	btn_pill_sb.set_content_margin_all(4)
	for btn: Button in [_chat_context_chip, _attach_btn, _agent_mode_btn, _smart_commit_btn]:
		btn.add_theme_stylebox_override("normal", btn_pill_sb)
		btn.add_theme_stylebox_override("hover", btn_pill_sb)
		btn.add_theme_color_override("font_color", fg)

	## Status bar
	var status_sb := StyleBoxFlat.new()
	status_sb.bg_color = bg_surface
	$RootVBox/StatusBar.add_theme_stylebox_override("panel", status_sb)
	_status_left.add_theme_color_override("font_color", green)
	if _status_git:
		_status_git.add_theme_color_override("font_color", green)
		_status_git.add_theme_color_override("font_hover_color", fg_bright)
		_status_git.add_theme_color_override("font_pressed_color", blue)
	_status_cursor.add_theme_color_override("font_color", muted)
	_status_lang.add_theme_color_override("font_color", muted)
	_status_enc.add_theme_color_override("font_color", muted)
	_status_ai.add_theme_color_override("font_color", blue)

	## Dialog and modal input styling
	var dialog_sb := StyleBoxFlat.new()
	dialog_sb.bg_color = bg_card
	dialog_sb.border_color = bg_lighter
	dialog_sb.set_border_width_all(1)
	dialog_sb.set_corner_radius_all(10)
	dialog_sb.set_content_margin_all(14)
	_dialog_panel.add_theme_stylebox_override("panel", dialog_sb)
	_dialog_title.add_theme_color_override("font_color", fg_bright)
	_dialog_body.add_theme_color_override("default_color", fg)
	var dlg_body_sb := StyleBoxEmpty.new()
	_dialog_body.add_theme_stylebox_override("normal", dlg_body_sb)
	var dlg_scroll_node: ScrollContainer = _dialog_body.get_parent() as ScrollContainer
	if dlg_scroll_node:
		dlg_scroll_node.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if _dialog_input:
		var dlg_in_sb := StyleBoxFlat.new()
		dlg_in_sb.bg_color = bg_surface
		dlg_in_sb.border_color = bg_lighter
		dlg_in_sb.set_border_width_all(1)
		dlg_in_sb.set_corner_radius_all(6)
		dlg_in_sb.set_content_margin_all(6)
		_dialog_input.add_theme_stylebox_override("normal", dlg_in_sb)
		_dialog_input.add_theme_stylebox_override("focus", dlg_in_sb)
		_dialog_input.add_theme_color_override("font_color", fg_bright)
	if _dialog_action_btn:
		var dlg_act_sb := StyleBoxFlat.new()
		dlg_act_sb.bg_color = blue
		dlg_act_sb.set_corner_radius_all(6)
		dlg_act_sb.set_content_margin_all(6)
		_dialog_action_btn.add_theme_stylebox_override("normal", dlg_act_sb)
		_dialog_action_btn.add_theme_color_override("font_color", Color("#ffffff"))
	if _dialog_close:
		var dlg_cls_sb := StyleBoxFlat.new()
		dlg_cls_sb.bg_color = bg_lighter
		dlg_cls_sb.set_corner_radius_all(6)
		dlg_cls_sb.set_content_margin_all(6)
		_dialog_close.add_theme_stylebox_override("normal", dlg_cls_sb)
		_dialog_close.add_theme_color_override("font_color", fg)

	## Provider select dropdown
	var provider_sb := StyleBoxFlat.new()
	provider_sb.bg_color = bg_card
	provider_sb.border_color = bg_lighter
	provider_sb.set_border_width_all(1)
	provider_sb.set_corner_radius_all(6)
	provider_sb.set_content_margin_all(4)
	_provider_select.add_theme_stylebox_override("normal", provider_sb)
	_provider_select.add_theme_color_override("font_color", fg)

	## Chat status banner
	var status_banner_sb := StyleBoxFlat.new()
	status_banner_sb.bg_color = bg_card
	status_banner_sb.border_color = bg_lighter
	status_banner_sb.set_border_width_all(1)
	status_banner_sb.set_corner_radius_all(8)
	status_banner_sb.set_content_margin_all(8)
	_apply_style_if_unset(_chat_status_banner, "panel", status_banner_sb)
	if _chat_thinking_label:
		_chat_thinking_label.add_theme_color_override("default_color", muted)
		_chat_thinking_label.add_theme_font_size_override("normal_font_size", 11)

	## Chat suggestions popup & list
	var suggestions_sb := StyleBoxFlat.new()
	suggestions_sb.bg_color = bg_card
	suggestions_sb.border_color = bg_lighter
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
				_status_left, _status_git, _status_cursor, _status_lang, _status_enc,
				_chat_context_chip,
				_attach_btn, _agent_mode_btn, _smart_commit_btn,
				_provider_select, explorer_header,
				_chat_status_label, _chat_thinking_label, _chat_send, _chat_suggestions_list,
				_dialog_title, _dialog_input, _dialog_action_btn, _dialog_close]:
			if node:
				node.add_theme_font_override("font", _nerd_font)
		_code_edit.add_theme_font_size_override("font_size", 14)
		_chat_log.add_theme_font_size_override("normal_font_size", 13)
		_chat_input.add_theme_font_size_override("font_size", 13)
		_chat_status_label.add_theme_font_size_override("normal_font_size", 12)
		_chat_suggestions_list.add_theme_font_size_override("font_size", 11)
		_provider_select.add_theme_font_size_override("font_size", 11)
		_smart_commit_btn.add_theme_font_size_override("font_size", 11)
		_agent_mode_btn.add_theme_font_size_override("font_size", 11)
		if _status_git:
			_status_git.add_theme_font_size_override("font_size", 12)

func _on_context_chip_pressed() -> void:
	if _active_index >= 0 and _active_index < _open_files.size():
		var fname: String = _open_files[_active_index].get("path", "").get_file()
		_chat_input.text = "Review " + fname + ": "
		_chat_input.caret_column = _chat_input.text.length()
		_chat_input.grab_focus()


func _on_attach_btn_pressed() -> void:
	if _active_index >= 0 and _active_index < _open_files.size():
		var p: String = _open_files[_active_index].get("path", "")
		_chat_input.text += " @" + p.get_file() + " "
		_chat_input.caret_column = _chat_input.text.length()
		_chat_input.grab_focus()


func _on_agent_mode_pressed() -> void:
	_agent_mode = not _agent_mode
	if _agent_mode:
		_agent_mode_btn.text = "</> Agent"
		_chat_context_badge.text = "Local · Autopilot"
	else:
		_agent_mode_btn.text = "Chat"
		_chat_context_badge.text = "Local · Chat"


func _set_markdown_preview(enabled: bool, raw_md: String) -> void:
	_md_preview_active = enabled
	if enabled:
		_code_edit.visible = false
		_markdown_preview.visible = true
		_markdown_preview.clear()
		_markdown_preview.text = ""
		var bbcode: String = _markdown_to_bbcode(raw_md)
		_markdown_preview.append_text(bbcode)
	else:
		_markdown_preview.visible = false
		_code_edit.visible = true


func _markdown_to_bbcode(md: String) -> String:
	var lines: PackedStringArray = md.replace("\r\n", "\n").split("\n")
	var out: String = ""
	var in_code_block: bool = false
	var code_lang: String = ""
	var code_buffer: String = ""
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i]

		# Fenced code blocks (``` or ~~~)
		if line.strip_edges().begins_with("```") or line.strip_edges().begins_with("~~~"):
			if not in_code_block:
				in_code_block = true
				code_lang = line.strip_edges().substr(3).strip_edges()
				code_buffer = ""
			else:
				in_code_block = false
				var lang_label: String = ""
				if not code_lang.is_empty():
					lang_label = "[color=#8b949e][i]" + code_lang.to_upper() + "[/i][/color]\n"
				out += lang_label + "[bgcolor=#161b22][color=#7ee787][code]" + code_buffer.strip_edges() + "[/code][/color][/bgcolor]\n\n"
			i += 1
			continue

		if in_code_block:
			code_buffer += line + "\n"
			i += 1
			continue

		var stripped: String = line.strip_edges()

		# Tables (| col1 | col2 |)
		if _is_table_row(stripped):
			var table_lines: Array[String] = []
			while i < lines.size() and _is_table_row(lines[i]):
				table_lines.append(lines[i])
				i += 1
			out += _render_preview_table(table_lines)
			continue

		# Horizontal rules (---, ***, ___)
		if stripped.length() >= 3:
			var is_hr: bool = true
			var hr_ch: String = stripped[0]
			if hr_ch in ["-", "*", "_"]:
				for c_idx in range(stripped.length()):
					if stripped[c_idx] != hr_ch:
						is_hr = false
						break
			else:
				is_hr = false
			if is_hr and stripped.length() >= 3:
				out += "[color=#30363d]────────────────────────────────────────────────[/color]\n\n"
				i += 1
				continue

		# Headings (# to ######) - GitHub Markdown style
		if stripped.begins_with("#"):
			var level: int = 0
			while level < stripped.length() and stripped[level] == "#":
				level += 1
			if level >= 1 and level <= 6 and level < stripped.length() and stripped[level] == " ":
				var heading_text: String = _md_inline(stripped.substr(level + 1))
				var sizes: Array[int] = [24, 20, 17, 15, 14, 13]
				var sz: int = sizes[mini(level - 1, 5)]
				if level == 1:
					out += "\n[font_size=" + str(sz) + "][b][color=#f0f6fc]" + heading_text + "[/color][/b][/font_size]\n"
					out += "[color=#30363d]────────────────────────────────────────────────[/color]\n\n"
				elif level == 2:
					out += "\n[font_size=" + str(sz) + "][b][color=#58a6ff]" + heading_text + "[/color][/b][/font_size]\n"
					out += "[color=#21262d]────────────────────────────────────────────────[/color]\n\n"
				elif level == 3:
					out += "\n[font_size=" + str(sz) + "][b][color=#79c0ff]" + heading_text + "[/b][/color][/font_size]\n\n"
				else:
					out += "\n[font_size=" + str(sz) + "][b][color=#d2a8ff]" + heading_text + "[/b][/color][/font_size]\n\n"
				i += 1
				continue

		# Blockquotes (>) - GitHub style
		if stripped.begins_with(">"):
			var quote_lines: String = ""
			while i < lines.size() and lines[i].strip_edges().begins_with(">"):
				var ql: String = lines[i].strip_edges()
				if ql.begins_with("> "):
					ql = ql.substr(2)
				elif ql == ">":
					ql = ""
				else:
					ql = ql.substr(1)
				quote_lines += _md_inline(ql) + "\n"
				i += 1
			out += "[indent][color=#388bfd]▎ [/color][color=#8b949e][i]" + quote_lines.strip_edges() + "[/i][/color][/indent]\n\n"
			continue

		# Unordered lists (-, *, +) & Task lists - GitHub style
		if stripped.begins_with("- ") or stripped.begins_with("* ") or stripped.begins_with("+ "):
			while i < lines.size():
				var ul_line: String = lines[i].strip_edges()
				if ul_line.begins_with("- [ ] ") or ul_line.begins_with("- [x] ") or ul_line.begins_with("- [X] "):
					var checked: bool = ul_line.begins_with("- [x] ") or ul_line.begins_with("- [X] ")
					var task_text: String = _md_inline(ul_line.substr(6))
					var marker: String = "[color=#3fb950]☑[/color] " if checked else "[color=#8b949e]☐[/color] "
					out += "  " + marker + task_text + "\n"
				elif ul_line.begins_with("- ") or ul_line.begins_with("* ") or ul_line.begins_with("+ "):
					out += "  [color=#58a6ff]•[/color] " + _md_inline(ul_line.substr(2)) + "\n"
				else:
					break
				i += 1
			out += "\n"
			continue

		# Ordered lists (1. 2. etc)
		if stripped.length() > 2:
			var dot_pos: int = stripped.find(". ")
			if dot_pos > 0 and dot_pos <= 4 and stripped.substr(0, dot_pos).is_valid_int():
				var list_num: int = 1
				while i < lines.size():
					var ol_line: String = lines[i].strip_edges()
					var dp: int = ol_line.find(". ")
					if dp > 0 and dp <= 4 and ol_line.substr(0, dp).is_valid_int():
						out += "  [color=#58a6ff]" + str(list_num) + ".[/color] " + _md_inline(ol_line.substr(dp + 2)) + "\n"
						list_num += 1
					else:
						break
					i += 1
				out += "\n"
				continue

		# Empty line = paragraph break
		if stripped.is_empty():
			out += "\n"
			i += 1
			continue

		# Regular paragraph text with inline formatting
		out += _md_inline(stripped) + "\n\n"
		i += 1

	return out


func _is_table_row(line: String) -> bool:
	var s: String = line.strip_edges()
	return s.begins_with("|") and s.ends_with("|") and s.length() >= 3


func _is_table_separator(line: String) -> bool:
	var s: String = line.strip_edges()
	if not (s.begins_with("|") and s.ends_with("|")):
		return false
	var inner: String = s.replace(" ", "").replace(":", "").replace("-", "").replace("|", "")
	return inner.is_empty()


func _render_preview_table(table_lines: Array[String]) -> String:
	if table_lines.is_empty():
		return ""
	var header_cells: Array[String] = _split_table_row(table_lines[0])
	if header_cells.is_empty():
		return ""
	var cols: int = header_cells.size()
	
	var row_start: int = 1
	if table_lines.size() > 1 and _is_table_separator(table_lines[1]):
		row_start = 2
	
	var table_out: String = "\n[table=%d]\n" % cols
	
	# Header Row
	for h: String in header_cells:
		var formatted_h: String = _md_inline(h)
		table_out += "[cell][bgcolor=#161b22][color=#58a6ff][b]  " + formatted_h + "  [/b][/color][/bgcolor][/cell]"
	table_out += "\n"
	
	# Data Rows
	var row_count: int = 0
	for r_idx: int in range(row_start, table_lines.size()):
		var row_line: String = table_lines[r_idx]
		var cells: Array[String] = _split_table_row(row_line)
		if cells.is_empty():
			continue
		var row_bg: String = "#0d1117" if (row_count % 2 == 0) else "#161b22"
		for c_idx: int in range(cols):
			var cell_val: String = cells[c_idx] if c_idx < cells.size() else ""
			var formatted_cell: String = _md_inline(cell_val)
			table_out += "[cell][bgcolor=" + row_bg + "][color=#c9d1d9]  " + formatted_cell + "  [/color][/bgcolor][/cell]"
		table_out += "\n"
		row_count += 1
	
	table_out += "[/table]\n\n"
	return table_out


func _split_table_row(row: String) -> Array[String]:
	var trimmed: String = row.strip_edges()
	if trimmed.begins_with("|"):
		trimmed = trimmed.substr(1)
	if trimmed.ends_with("|"):
		trimmed = trimmed.substr(0, trimmed.length() - 1)
	var parts: PackedStringArray = trimmed.split("|")
	var result: Array[String] = []
	for p: String in parts:
		result.append(p.strip_edges())
	return result


func _md_inline(text: String) -> String:
	var result: String = text

	# HTML <kbd>key</kbd> -> GitHub Keyboard Badge
	var kbd_regex := RegEx.new()
	kbd_regex.compile("(?i)<kbd>(.*?)</kbd>")
	result = kbd_regex.sub(result, "[bgcolor=#21262d][color=#f0f6fc][b] $1 [/b][/color][/bgcolor]", true)

	# HTML <code>...</code>
	var html_code_regex := RegEx.new()
	html_code_regex.compile("(?i)<code>(.*?)</code>")
	result = html_code_regex.sub(result, "[bgcolor=#161b22][color=#79c0ff][code] $1 [/code][/color][/bgcolor]", true)

	# HTML <b>, <strong>, <i>, <em>, <s>, <del>, <br>
	var strong_regex := RegEx.new()
	strong_regex.compile("(?i)<(?:b|strong)>(.*?)</(?:b|strong)>")
	result = strong_regex.sub(result, "[b]$1[/b]", true)

	var em_regex := RegEx.new()
	em_regex.compile("(?i)<(?:i|em)>(.*?)</(?:i|em)>")
	result = em_regex.sub(result, "[i]$1[/i]", true)

	var del_regex := RegEx.new()
	del_regex.compile("(?i)<(?:s|del|strike)>(.*?)</(?:s|del|strike)>")
	result = del_regex.sub(result, "[s]$1[/s]", true)

	var br_regex := RegEx.new()
	br_regex.compile("(?i)<br\\s*/?>")
	result = br_regex.sub(result, "\n", true)

	# Inline code (`code`)
	var code_regex := RegEx.new()
	code_regex.compile("`([^`]+)`")
	result = code_regex.sub(result, "[bgcolor=#1f242c][color=#79c0ff][code] $1 [/code][/color][/bgcolor]", true)

	# Bold + Italic (***text*** or ___text___)
	var bold_italic_regex := RegEx.new()
	bold_italic_regex.compile("\\*\\*\\*(.+?)\\*\\*\\*")
	result = bold_italic_regex.sub(result, "[b][i]$1[/i][/b]", true)
	var bold_italic_regex2 := RegEx.new()
	bold_italic_regex2.compile("___(.+?)___")
	result = bold_italic_regex2.sub(result, "[b][i]$1[/i][/b]", true)

	# Bold (**text** or __text__)
	var bold_regex := RegEx.new()
	bold_regex.compile("\\*\\*(.+?)\\*\\*")
	result = bold_regex.sub(result, "[b]$1[/b]", true)
	var bold_regex2 := RegEx.new()
	bold_regex2.compile("__(.+?)__")
	result = bold_regex2.sub(result, "[b]$1[/b]", true)

	# Italic (*text* or _text_)
	var italic_regex := RegEx.new()
	italic_regex.compile("\\*(.+?)\\*")
	result = italic_regex.sub(result, "[i]$1[/i]", true)
	var italic_regex2 := RegEx.new()
	italic_regex2.compile("(?<![\\w])_(.+?)_(?![\\w])")
	result = italic_regex2.sub(result, "[i]$1[/i]", true)

	# Strikethrough (~~text~~)
	var strike_regex := RegEx.new()
	strike_regex.compile("~~(.+?)~~")
	result = strike_regex.sub(result, "[s]$1[/s]", true)

	# Links [text](url)
	var link_regex := RegEx.new()
	link_regex.compile("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	result = link_regex.sub(result, "[color=#58a6ff][url=$2]$1[/url][/color]", true)

	# Images ![alt](url) — show as labelled placeholder
	var img_regex := RegEx.new()
	img_regex.compile("!\\[([^\\]]*?)\\]\\(([^)]+)\\)")
	result = img_regex.sub(result, "[color=#79c0ff]🖼 $1[/color]", true)

	# Strip any remaining raw HTML tags
	var tag_strip_regex := RegEx.new()
	tag_strip_regex.compile("<[^>]+>")
	result = tag_strip_regex.sub(result, "", true)

	return result


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
	var p: Dictionary = THEMES.get(_active_theme, THEMES["adwaita_darker"])
	var hl := CodeHighlighter.new()
	hl.number_color = Color(str(p.get("hl_number", "#ffa348")))
	hl.symbol_color = Color(str(p.get("hl_symbol", "#5bc8af")))
	hl.function_color = Color(str(p.get("hl_func", "#62a0ea")))
	hl.member_variable_color = Color(str(p.get("hl_member", "#99c1f1")))
	var comment_col := Color(str(p.get("hl_comment", "#9a9996")))
	var string_col  := Color(str(p.get("hl_string",  "#57e389")))
	var kw_col      := Color(str(p.get("hl_keyword", "#dc8add")))
	var type_col    := Color(str(p.get("hl_type",    "#93ddc2")))
	var const_col   := Color(str(p.get("hl_const",   "#ffa348")))
	hl.add_color_region("#", "", comment_col, true)
	hl.add_color_region('"', '"', string_col)
	hl.add_color_region("'", "'", string_col)
	hl.add_color_region('"""', '"""', string_col)
	var kws := [
		"extends", "class_name", "var", "const", "func", "static", "signal", "enum",
		"if", "elif", "else", "for", "while", "match", "return", "pass", "break",
		"continue", "await", "self", "void", "int", "float", "bool", "String",
		"Vector2", "Vector3", "Color", "Array", "Dictionary", "true", "false", "null",
		"@onready", "@export", "preload", "load", "print", "push_error", "in", "not",
		"and", "or", "is", "as", "class", "super", "get", "set",
	]
	for kw in kws:
		hl.add_keyword_color(kw, kw_col)
	var types := ["int", "float", "bool", "String", "Vector2", "Vector3", "Color",
		"Array", "Dictionary", "void", "PackedStringArray", "PackedByteArray",
		"Variant", "Error", "NodePath", "StringName"]
	for t in types:
		hl.add_keyword_color(t, type_col)
	for c in ["true", "false", "null", "self", "PI", "TAU", "INF", "NAN"]:
		hl.add_keyword_color(c, const_col)
	return hl


func _refresh_file_tree() -> void:
	_file_tree.clear()
	var root_item: TreeItem = _file_tree.create_item()
	var root_title: String = _workspace_root.get_file()
	if root_title.is_empty():
		root_title = "WORKSPACE"
	root_item.set_text(0, root_title.to_upper())
	var folder_tex: Texture2D = FileKind.texture_for_path(_workspace_root, true, true)
	if folder_tex:
		root_item.set_icon(0, folder_tex)
		root_item.set_icon_max_width(0, 16)
	root_item.set_custom_color(0, Color("#8ec4f7"))
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
		if fname not in [".", "..", ".git", ".godot", ".gemini", "android"]:
			if dir.current_is_dir():
				dirs.append(fname)
			else:
				files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	dirs.sort()
	files.sort()
	for d: String in dirs:
		var item: TreeItem = _file_tree.create_item(parent_item)
		item.set_text(0, d)
		var item_path: String = dir_path.path_join(d)
		var folder_tex: Texture2D = FileKind.texture_for_path(item_path, true, false)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, Color("#8ec4f7"))
		item.set_metadata(0, {"path": item_path, "is_dir": true})
		item.collapsed = true
		_populate_tree_dir(item, item_path)
	for f: String in files:
		var item: TreeItem = _file_tree.create_item(parent_item)
		item.set_text(0, f)
		var item_path: String = dir_path.path_join(f)
		var file_tex: Texture2D = FileKind.texture_for_path(item_path, false, false)
		if file_tex:
			item.set_icon(0, file_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, FileKind.color_for_path(f))
		item.set_metadata(0, {"path": item_path, "is_dir": false})


func _on_tree_item_collapsed(item: TreeItem) -> void:
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		var p: String = str(meta.get("path", ""))
		var folder_tex: Texture2D = FileKind.texture_for_path(p, true, not item.collapsed)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)


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
	if not path.is_empty():
		_chat_context_chip.text = "+ " + path.get_file()
	else:
		_chat_context_chip.text = "+ Untitled"
	# Markdown preview toggle
	var is_md: bool = path.to_lower().ends_with(".md")
	_set_markdown_preview(is_md, str(info.get("content", "")))


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
	_update_git_status_bar()


func _save_as_path(path: String) -> void:
	if _active_index < 0 or _active_index >= _open_files.size():
		return
	var info: Dictionary = _open_files[_active_index]
	info["path"] = path
	info["title"] = path.get_file()
	_save_active()
	_status_lang.text = FileKind.label_for_path(path)
	_update_git_status_bar()


func _on_dir_selected(dir_path: String) -> void:
	_workspace_root = dir_path
	_refresh_file_tree()
	_status_left.text = "WORKSPACE: " + dir_path.get_file()
	_update_git_status_bar()


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
		for item: Dictionary in CHAT_SLASH_COMMANDS:
			var cmd: String = str(item.get("cmd", ""))
			if query == "/" or cmd.begins_with(query):
				_chat_suggestions_list.add_item(cmd + "  —  " + str(item.get("desc", "")))
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


func _clear_ai_busy() -> void:
	_ai_busy = false
	_stop_chat_stream()
	_chat_status_banner.visible = false
	_thinking_text = ""
	_chat_thinking_label.text = ""
	_chat_send.text = "↑"
	_status_left.text = "READY"


func _cancel_ai_request() -> void:
	var pending_smart := _is_smart_commit_pending()
	_ai_chat_http.cancel_request()
	_stop_chat_stream()
	if pending_smart:
		_fallback_smart_commit("Request cancelled.")
		return
	_smart_commit_prompt = ""
	_clear_ai_busy()
	_show_toast("Request cancelled.", false)
	_append_chat("IDE", "Request cancelled.", Color("#ffa348"))


func _on_chat_submitted(text: String) -> void:
	var prompt: String = text.strip_edges()
	if prompt.is_empty() or _ai_busy:
		return
	if _prompt_history.is_empty() or _prompt_history.back() != prompt:
		_prompt_history.append(prompt)
	_prompt_history_idx = -1
	_prompt_draft = ""
	_chat_input.text = ""
	_chat_suggestions_popup.visible = false
	_append_user_message(prompt)
	if prompt.begins_with("/"):
		_handle_slash(prompt)
		return
	_chat_history.append({"role": "user", "content": prompt})
	_ensure_api_key(func() -> void: _ask_ai(prompt))


func _handle_slash(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false, 1)
	var head: String = parts[0].to_lower()
	match head:
		"/tools":
			_show_tools_list()
		"/github":
			_show_github_info_dialog()
		"/git":
			var subcmd_raw: String = parts[1].strip_edges() if parts.size() > 1 else "status"
			var sub_parts: PackedStringArray = subcmd_raw.split(" ", false, 1)
			var subcmd: String = sub_parts[0].to_lower() if not sub_parts.is_empty() else "status"
			var sub_arg: String = sub_parts[1].strip_edges() if sub_parts.size() > 1 else ""
			
			match subcmd:
				"status":
					var st: Dictionary = GitService.get_status(_workspace_root)
					var gh: Dictionary = GitService.get_github_info(_workspace_root)
					_append_chat("GIT", GitService.format_status_bbcode(st, gh), Color("#62a0ea"))
					_update_git_status_bar()
				"diff":
					var res: Dictionary = GitService.get_diff(sub_arg, false, _workspace_root)
					_append_chat("GIT", GitService.format_diff_bbcode(str(res.get("output", ""))), Color("#62a0ea"))
				"log":
					var count: int = sub_arg.to_int() if sub_arg.to_int() > 0 else 10
					var log_entries: Array[Dictionary] = GitService.get_log(count, _workspace_root)
					_append_chat("GIT", GitService.format_log_bbcode(log_entries), Color("#62a0ea"))
				"commit":
					if sub_arg.is_empty():
						_generate_smart_commit()
					else:
						GitService.stage_all(_workspace_root)
						var commit_res: Dictionary = GitService.commit(sub_arg, _workspace_root)
						if bool(commit_res.get("success", false)):
							_append_chat("GIT", "[b][color=#57e389]Commit created successfully:[/color][/b]\n" + sub_arg, Color("#57e389"))
							_show_toast("Git commit: " + sub_arg, false)
						else:
							_append_chat("GIT", "[color=#ed333b]Git commit failed:\n" + str(commit_res.get("output", "")) + "[/color]", Color("#ed333b"))
						_update_git_status_bar()
				"push":
					var push_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = push_args[0] if push_args.size() > 0 else "origin"
					var branch_name: String = push_args[1] if push_args.size() > 1 else ""
					_git_push(remote_name, branch_name)
				"pull":
					var pull_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = pull_args[0] if pull_args.size() > 0 else "origin"
					var branch_name: String = pull_args[1] if pull_args.size() > 1 else ""
					_git_pull(remote_name, branch_name)
				"sync":
					var sync_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = sync_args[0] if sync_args.size() > 0 else "origin"
					var branch_name: String = sync_args[1] if sync_args.size() > 1 else ""
					_git_sync(remote_name, branch_name)
				"fetch":
					var remote_name: String = sub_arg if not sub_arg.is_empty() else "origin"
					_git_fetch(remote_name)
				"branch":
					if sub_arg.is_empty():
						var branches: Array[Dictionary] = GitService.get_branches(_workspace_root)
						var b_out := "[b][color=#62a0ea]Git Branches:[/color][/b]\n"
						for b in branches:
							var prefix := "● " if bool(b.get("is_current", false)) else "  "
							var col := "#57e389" if bool(b.get("is_current", false)) else "#deddda"
							b_out += "[color=%s]%s%s[/color]\n" % [col, prefix, str(b.get("display_name", ""))]
						_append_chat("GIT", b_out, Color("#62a0ea"))
					else:
						var create_res: Dictionary = GitService.create_branch(sub_arg, _workspace_root)
						if bool(create_res.get("success", false)):
							_append_chat("GIT", "[color=#57e389]Branch '%s' created successfully.[/color]" % sub_arg, Color("#57e389"))
						else:
							_append_chat("GIT", "[color=#ed333b]Failed to create branch:\n" + str(create_res.get("output", "")) + "[/color]", Color("#ed333b"))
						_update_git_status_bar()
				"checkout", "switch":
					if sub_arg.is_empty():
						_prompt_git_branch()
					else:
						var create_new := sub_arg.begins_with("-b ") or sub_arg.begins_with("+")
						var branch_target := sub_arg.trim_prefix("-b ").trim_prefix("+").strip_edges()
						var co_res: Dictionary = GitService.checkout_branch(branch_target, create_new, _workspace_root)
						if bool(co_res.get("success", false)):
							_append_chat("GIT", "[color=#57e389]Switched to branch '%s' successfully.[/color]" % branch_target, Color("#57e389"))
							_show_toast("Branch: " + branch_target, false)
						else:
							_append_chat("GIT", "[color=#ed333b]Failed to switch branch:\n" + str(co_res.get("output", "")) + "[/color]", Color("#ed333b"))
						_update_git_status_bar()
				"remote":
					var remotes: Array[Dictionary] = GitService.get_remotes(_workspace_root)
					var gh: Dictionary = GitService.get_github_info(_workspace_root)
					var r_out := "[b][color=#62a0ea]Git Remotes & GitHub:[/color][/b]\n\n"
					for r in remotes:
						r_out += "• [b]%s[/b] (%s): `%s`\n" % [str(r.get("name", "")), str(r.get("type", "")), str(r.get("url", ""))]
					if bool(gh.get("is_github", false)):
						r_out += "\n[color=#57e389]GitHub Repo:[/color] %s\n" % str(gh.get("web_url", ""))
					_append_chat("GIT", r_out, Color("#62a0ea"))
				"config":
					if sub_arg.is_empty():
						var u: Dictionary = GitService.get_user_config(_workspace_root)
						_append_chat("GIT", "Git User: `%s <%s>`" % [str(u.get("name", "")), str(u.get("email", ""))], Color("#62a0ea"))
					else:
						var name_val := sub_arg
						var email_val := ""
						if sub_arg.contains("<") and sub_arg.contains(">"):
							var s_idx := sub_arg.find("<")
							var e_idx := sub_arg.find(">")
							name_val = sub_arg.substr(0, s_idx).strip_edges()
							email_val = sub_arg.substr(s_idx + 1, e_idx - s_idx - 1).strip_edges()
						var cfg_res: Dictionary = GitService.set_user_config(name_val, email_val, false, _workspace_root)
						if bool(cfg_res.get("success", false)):
							_append_chat("GIT", "[color=#57e389]Git user configured: %s <%s>[/color]" % [name_val, email_val], Color("#57e389"))
						else:
							_append_chat("GIT", "[color=#ed333b]Failed to configure Git user.[/color]", Color("#ed333b"))
				"clone":
					if sub_arg.is_empty():
						_prompt_git_clone()
					else:
						var target_dir: String = _workspace_root.path_join(sub_arg.get_file().trim_suffix(".git"))
						_show_toast("Cloning repository…", false)
						var cl_res: Dictionary = GitService.clone_repository(sub_arg, target_dir)
						if bool(cl_res.get("success", false)):
							_append_chat("GIT", "[color=#57e389]Repository cloned to %s[/color]" % target_dir, Color("#57e389"))
							_refresh_file_tree()
						else:
							_append_chat("GIT", "[color=#ed333b]Failed to clone repository:\n" + str(cl_res.get("output", "")) + "[/color]", Color("#ed333b"))
				_:
					var res: Dictionary = _execute_git_command(subcmd_raw.split(" ", false))
					var out_txt: String = str(res.get("output", "")).strip_edges()
					if out_txt.is_empty():
						out_txt = "Git command executed."
					_append_chat("GIT", "```bash\n" + out_txt + "\n```", Color("#62a0ea"))
					_update_git_status_bar()
		"/theme":
			var theme_arg: String = parts[1].strip_edges().to_lower() if parts.size() > 1 else ""
			if theme_arg.is_empty() or theme_arg == "list":
				_show_theme_picker()
			elif theme_arg == "import":
				_import_theme_xml_dialog()
			elif _all_themes().has(theme_arg):
				_apply_theme_by_name(theme_arg)
			else:
				var names := ", ".join(_all_themes().keys())
				_append_chat("IDE", "[color=#ffa348]Theme not found:[/color] " + theme_arg + "\nAvailable themes: " + names, Color("#ffa348"))
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
		"/goto":
			if parts.size() > 1:
				var line_num: int = parts[1].strip_edges().to_int()
				if line_num > 0 and _code_edit:
					var target_idx: int = clampi(line_num - 1, 0, maxi(0, _code_edit.get_line_count() - 1))
					_code_edit.set_caret_line(target_idx)
					_code_edit.grab_focus()
					_append_tool_badge("Go to Line", str(line_num))
		"/clear":
			_chat_history.clear()
			_chat_log.clear()
			_append_chat("IDE", "Chat history and context cleared.", Color("#57e389"))
		"/compact":
			_compact_chat_history()
		"/cancel":
			_cancel_ai_request()
		"/quit", "/exit":
			get_tree().quit()
		_:
			_append_chat("IDE", "Commands: `/tools`, `/github`, `/git status`, `/git diff`, `/git log`, `/git commit`, `/git push`, `/git pull`, `/git sync`, `/git branch`, `/save`, `/files`, `/open <path>`, `/goto <line>`, `/clear`, `/compact`, `/quit`", Color("#ffa348"))


func _compact_chat_history() -> void:
	## Keep the latest turns verbatim and replace older turns with a bounded summary.
	## This is deliberately local so /compact remains useful without an API key.
	const RECENT_MESSAGES := 12
	const SUMMARY_LIMIT := 6000
	if _chat_history.size() <= RECENT_MESSAGES:
		_append_chat("IDE", "Context is already compact (%d messages)." % _chat_history.size(), Color("#9a9996"))
		return

	var compact_count := _chat_history.size() - RECENT_MESSAGES
	var summary := "Conversation summary (generated by /compact):\n"
	for i in range(compact_count):
		var entry: Dictionary = _chat_history[i]
		var role := str(entry.get("role", "message")).capitalize()
		var content := str(entry.get("content", "")).strip_edges()
		if content.is_empty():
			continue
		if content.length() > 700:
			content = content.substr(0, 700) + "…"
		summary += "%s: %s\n" % [role, content]
		if summary.length() >= SUMMARY_LIMIT:
			summary += "[Earlier details truncated.]\n"
			break

	var recent: Array[Dictionary] = []
	for i in range(compact_count, _chat_history.size()):
		recent.append(_chat_history[i])
	_chat_history.clear()
	_chat_history.append({"role": "user", "content": summary.strip_edges()})
	_chat_history.append({"role": "assistant", "content": "Summary recorded. Continue from the preserved recent context."})
	_chat_history.append_array(recent)
	_append_chat("IDE", "Context compactado: %d mensagens antigas resumidas; %d mensagens recentes preservadas." % [compact_count, RECENT_MESSAGES], Color("#57e389"))


func _show_tools_list() -> void:
	var tools_md := """Git tools and commands available in SSCodeIDE:

• **git_status**: Check repository status, current branch and changed files.
• **git_diff**: Inspect code changes (addition and deletion statistics).
• **git_log**: View recent commit history.
• **git_commit**: Generate and run smart or custom commits.
• **git_push**: Push local commits to the GitHub repository.
• **git_pull**: Fetch and merge updates from GitHub.
• **git_sync**: Automatic two-way synchronisation with GitHub (Pull & Push).
• **git_fetch**: Fetch remote branch references.
• **git_branch**: List, create or switch branches.
• **git_remote**: View remotes and GitHub URLs.
• **git_config**: Configure Git user name and e-mail for commits.
• **git_clone**: Clone a GitHub repository.
• **apply_patch**: Edit workspace files by applying patches.
• **create_file / read_file**: Create and read project files.
• **list_dir / file_search / grep_search**: Browse and search files in the directory."""
	_append_chat("AGENT", tools_md, Color("#62a0ea"))


func _execute_git_command(args: PackedStringArray) -> Dictionary:
	return GitService.execute(args, _workspace_root)


func _is_smart_commit_pending() -> bool:
	return not _smart_commit_prompt.is_empty() or _current_prompt.begins_with("__SMART_COMMIT__:")


func _finish_smart_commit(commit_msg: String, via_ai: bool, note: String = "") -> void:
	var diff_stat: String = ""
	if _current_prompt.begins_with("__SMART_COMMIT__:"):
		diff_stat = _current_prompt.trim_prefix("__SMART_COMMIT__:")
	_current_prompt = ""
	_smart_commit_prompt = ""
	_clear_ai_busy()
	var message: String = commit_msg.strip_edges()
	if message.is_empty():
		message = GitService.build_fallback_commit_message(_workspace_root)
	var commit_res: Dictionary = GitService.commit(message, _workspace_root)
	if bool(commit_res.get("success", false)):
		var headline: String = message.split("\n")[0]
		var source_label: String = "AI-generated message" if via_ai else "local Conventional Commits message"
		var commit_report := "[b]Smart Commit completed:[/b]\n"
		commit_report += "[bgcolor=#0d1a0d][color=#57e389]  " + headline + "\n[/color][/bgcolor]\n\n"
		if not note.is_empty():
			commit_report += "[color=#ffa348]%s[/color]\n\n" % note
		if not diff_stat.is_empty():
			commit_report += "[color=#9a9996]Change summary:\n" + diff_stat + "[/color]\n"
		commit_report += "\n[color=#57e389]● Git[/color] [color=#62a0ea]commit with %s[/color]" % source_label
		_append_chat("GIT", commit_report, Color("#57e389"))
		_show_toast("Smart Commit: " + headline, false)
	else:
		_append_chat("GIT", "[color=#ed333b]Commit error:[/color]\n" + str(commit_res.get("output", "")), Color("#ed333b"))
		_show_toast("Smart Commit failed.", true)
	_update_git_status_bar()


func _fallback_smart_commit(reason: String) -> void:
	var local_msg: String = GitService.build_fallback_commit_message(_workspace_root)
	_finish_smart_commit(local_msg, false, reason + " Using a local message.")


func _generate_smart_commit() -> void:
	if not GitService.is_git_repository(_workspace_root):
		_append_chat("GIT", "[color=#ffa348]Not a Git repository.[/color]", Color("#ffa348"))
		_show_toast("Not a Git repository.", true)
		return
	_continue_smart_commit()


func _continue_smart_commit() -> void:

	var st: Dictionary = GitService.get_status(_workspace_root)
	var staged: Array   = st.get("staged",    [])
	var unstaged: Array = st.get("unstaged",  [])
	var untracked: Array= st.get("untracked", [])
	if staged.is_empty() and unstaged.is_empty() and untracked.is_empty():
		_append_chat("GIT", "[color=#9a9996]Nothing to commit.[/color]", Color("#9a9996"))
		_show_toast("Git: nothing to commit.", false)
		return

	## Stage everything (git add -A)
	var stage_res: Dictionary = GitService.stage_all(_workspace_root)
	if not bool(stage_res.get("success", false)):
		_append_chat("GIT", "[color=#ed333b]Failed to run git add -A:[/color]\n" + str(stage_res.get("output", "")), Color("#ed333b"))
		return

	## Gather diff stat for context
	var diff_stat_res: Dictionary = GitService.get_diff_stat(_workspace_root)
	var diff_stat: String = str(diff_stat_res.get("output", "")).strip_edges()

	## Gather a compact diff (limit to ~3000 chars to fit model context)
	var diff_res: Dictionary = GitService.get_diff("", true, _workspace_root)
	var diff_text: String = str(diff_res.get("output", "")).strip_edges()
	if diff_text.length() > 3000:
		diff_text = diff_text.substr(0, 3000) + "\n... [diff truncated]"

	if diff_text.is_empty():
		diff_text = diff_stat

	if not AIService.has_nvidia_api_key():
		_finish_smart_commit(GitService.build_fallback_commit_message(_workspace_root), false, "No NVIDIA NIM key.")
		return

	## Show spinner while AI generates the commit message
	_show_toast("Generating commit message with AI…", false)
	_append_chat("GIT", "[color=#62a0ea]⠙ Generating commit message with AI…[/color]", Color("#62a0ea"))

	## Build AI prompt for Conventional Commits
	var commit_prompt := (
		"You are an expert software engineer. Analyse the following `git diff --cached` output " +
		"and produce ONE concise Git commit message following the Conventional Commits specification " +
		"(https://www.conventionalcommits.org).\n\n" +
		"Rules:\n" +
		"- Use one of: feat, fix, docs, style, refactor, perf, test, chore, build, ci\n" +
		"- First line: type(scope): short summary in imperative mood, max 72 chars\n" +
		"- Optionally add a blank line then a short body (max 3 lines) describing WHY\n" +
		"- Output ONLY the commit message — no explanation, no markdown fences\n\n" +
		"Git diff:\n```\n" + diff_text + "\n```"
	)

	## Send one-shot request to the AI (bypassing chat history)
	_ai_smart_commit_request(commit_prompt, diff_stat)


func _ai_smart_commit_request(prompt: String, diff_stat: String) -> void:
	## Reuse the same HTTPRequest as chat. Candidate fallback must send this
	## compact payload — not the chat workspace dump — or the retry will hang.
	if _ai_busy:
		_finish_smart_commit(GitService.build_fallback_commit_message(_workspace_root), false, "AI is busy.")
		return

	_ai_busy = true
	_request_start_time = Time.get_ticks_msec() / 1000.0
	_spinner_time = 0.0
	_chat_status_banner.visible = true
	_chat_thinking_label.text = "[color=#858585][i]Waiting for the model's reasoning…[/i][/color]"
	_chat_send.text = "■"
	_status_left.text = "Smart Commit: generating AI message…"
	_current_prompt = "__SMART_COMMIT__:" + diff_stat
	_smart_commit_prompt = prompt
	_model_candidates = AIService.get_candidate_models(_ai_provider)
	_model_candidate_index = 0
	_send_chat_completion()


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
		if _is_smart_commit_pending():
			_fallback_smart_commit("NVIDIA NIM models exhausted.")
			return
		_smart_commit_prompt = ""
		_clear_ai_busy()
		_append_chat(_ai_provider.to_upper(), "Could not retrieve response from NVIDIA NIM models. Please retry.", Color("#ed333b"))
		return

	var model_name: String = _model_candidates[_model_candidate_index]
	var target_url: String = AIService.NVIDIA_BASE_URL
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + AIService.get_nvidia_api_key(),
		"Accept: application/json"
	])
	var is_smart_commit := _current_prompt.begins_with("__SMART_COMMIT__:")
	var messages_payload: Array[Dictionary] = []
	var payload_dict: Dictionary = {}

	if is_smart_commit:
		messages_payload = [
			{"role": "system", "content": "You are an expert Git commit message writer. Output ONLY the commit message with no extra text or markdown."},
			{"role": "user", "content": _smart_commit_prompt}
		]
		payload_dict = {
			"model": model_name,
			"messages": messages_payload,
			"temperature": 0.2,
			"top_p": 0.9,
			"max_tokens": 256,
			"stream": false
		}
	else:
		var workspace_info: String = _get_workspace_context()
		var system_role_content: String = ""
		if _agent_mode:
			system_role_content = (
				"You are SSBot, an elite autonomous AI programming agent integrated directly into SSCodeIDE created by Ser Superior (SS).\n" +
				"You have direct access and visibility to the project workspace files, directory tree, and active file.\n\n" +
				"=== WORKSPACE CONTEXT ===\n" +
				workspace_info + "\n" +
				"=========================\n\n" +
				"=== CRITICAL COMMUNICATION & LANGUAGE RULES ===\n" +
				"1. You MUST ALWAYS communicate and respond in European Portuguese (pt-PT), adhering strictly to the 'norma culta' of Portugal.\n" +
				"2. Treat the user informally by 'tu' (second person singular: 'podes', 'vê', 'executa', 'fizeste').\n" +
				"3. Follow the grammatical rules of the pre-2012 orthographic agreement (preserving silent consonants, e.g., 'acção', 'directo', 'projecto', 'objectivo', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico').\n" +
				"4. However, ALL projects, source code, variable names, functions, docstrings, and technical code comments MUST ALWAYS be in technical British English (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"===============================================\n\n" +
				"Provide detailed technical guidance, plan development tasks with checklists, review code, execute slash commands, and format responses clearly with Markdown/BBCode.\n" +
				"Always consider the full workspace context and active file contents when responding."
			)
		else:
			system_role_content = (
				"You are SSBot, a helpful AI programming assistant embedded in SSCodeIDE created by Ser Superior (SS).\n\n" +
				"=== CRITICAL COMMUNICATION & LANGUAGE RULES ===\n" +
				"1. You MUST ALWAYS communicate and respond in European Portuguese (pt-PT), adhering strictly to the 'norma culta' of Portugal.\n" +
				"2. Treat the user informally by 'tu' (second person singular: 'podes', 'vê', 'executa', 'fizeste').\n" +
				"3. Follow the grammatical rules of the pre-2012 orthographic agreement (preserving silent consonants, e.g., 'acção', 'directo', 'projecto', 'objectivo', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico').\n" +
				"4. However, ALL projects, source code, variable names, functions, docstrings, and technical code comments MUST ALWAYS be in technical British English (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"===============================================\n\n" +
				"Respond concisely and helpfully to general programming questions and discussions."
			)
		messages_payload = [
			{"role": "system", "content": system_role_content}
		]
		var history_limit: int = 60 if _agent_mode else 30
		var start_idx: int = maxi(0, _chat_history.size() - history_limit)
		for i in range(start_idx, _chat_history.size()):
			messages_payload.append(_chat_history[i])
		payload_dict = {
			"model": model_name,
			"messages": messages_payload,
			"temperature": 0.7 if _agent_mode else 0.5,
			"top_p": 0.95,
			"max_tokens": 4096,
			"stream": true
		}
		if model_name.begins_with("nvidia/nemotron"):
			payload_dict["chat_template_kwargs"] = {"thinking": true}

	var payload_json := JSON.stringify(payload_dict)
	if not is_smart_commit:
		_thinking_text = ""
		_refresh_thinking_panel()
		if _start_chat_stream(payload_json):
			return
	var err: Error = _ai_chat_http.request(target_url, headers, HTTPClient.METHOD_POST, payload_json)
	if err != OK:
		if _is_smart_commit_pending():
			_fallback_smart_commit("Failed to start HTTP request (code %d)." % err)
			return
		_smart_commit_prompt = ""
		_clear_ai_busy()
		_show_toast("Failed to initiate HTTP request (Code %d)." % err, true)
		_append_chat(_ai_provider.to_upper(), "Failed to initiate HTTP request (Code %d)." % err, Color("#ed333b"))


func _show_toast(message: String, is_warning: bool = true) -> void:
	_send_os_notification("SSCodeIDE", message, is_warning)


func _send_os_notification(title: String, body: String, is_warning: bool = false) -> void:
	## Native desktop notification. Auto-dismiss after OS_NOTIFY_EXPIRE_MS.
	## GNOME ignores expire-time for urgency=critical, so warnings stay "normal"
	## and transient; CloseNotification is issued after the timeout.
	var icon := "dialog-information" if not is_warning else "dialog-warning"
	var expire_s := float(OS_NOTIFY_EXPIRE_MS) / 1000.0
	match OS.get_name():
		"Linux", "FreeBSD", "OpenBSD", "NetBSD":
			OS.execute("notify-send", [
				"--urgency=normal",
				"--icon=" + icon,
				"--app-name=SSCodeIDE",
				"--hint=int:transient:1",
				"--hint=int:resident:0",
				"--replace-id=" + str(OS_NOTIFY_REPLACE_ID),
				"--expire-time=" + str(OS_NOTIFY_EXPIRE_MS),
				title, body
			])
		"macOS":
			var script := "display notification \"%s\" with title \"%s\"" % [
				body.replace("\"", "'"), title.replace("\"", "'")
			]
			OS.execute("osascript", ["-e", script])
		"Windows":
			var ps_cmd := (
				"[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null;" +
				"$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);" +
				"$xml.GetElementsByTagName('text')[0].InnerText = '%s';" % title.replace("'", "`'") +
				"$xml.GetElementsByTagName('text')[1].InnerText = '%s';" % body.replace("'", "`'") +
				"$toast = New-Object Windows.UI.Notifications.ToastNotification($xml);" +
				"$toast.ExpirationTime = [DateTimeOffset]::Now.AddMilliseconds(%d);" % OS_NOTIFY_EXPIRE_MS +
				"[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('SSCodeIDE').Show($toast)"
			)
			OS.execute("powershell", ["-WindowStyle", "Hidden", "-Command", ps_cmd])
	_os_notify_generation += 1
	var gen := _os_notify_generation
	get_tree().create_timer(expire_s).timeout.connect(func() -> void:
		if gen == _os_notify_generation:
			_dismiss_os_notification()
	)


func _dismiss_os_notification() -> void:
	match OS.get_name():
		"Linux", "FreeBSD", "OpenBSD", "NetBSD":
			OS.execute("gdbus", [
				"call", "--session",
				"--dest", "org.freedesktop.Notifications",
				"--object-path", "/org/freedesktop/Notifications",
				"--method", "org.freedesktop.Notifications.CloseNotification",
				str(OS_NOTIFY_REPLACE_ID)
			])
		_:
			pass


func _try_next_ai_candidate(toast_message: String) -> bool:
	_model_candidate_index += 1
	if _model_candidate_index < _model_candidates.size():
		_ai_busy = true
		_chat_status_banner.visible = true
		_chat_send.text = "■"
		_show_toast(toast_message, true)
		_send_chat_completion()
		return true
	if _is_smart_commit_pending():
		_fallback_smart_commit("Todos os modelos candidatos falharam.")
		return false
	_smart_commit_prompt = ""
	_clear_ai_busy()
	return false


func _on_ai_chat_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var is_smart_commit := _current_prompt.begins_with("__SMART_COMMIT__:")
	var elapsed: float = maxf(0.1, (Time.get_ticks_msec() / 1000.0) - _request_start_time)

	if result != HTTPRequest.RESULT_SUCCESS:
		var timeout_toast := "Request timeout. Attempting candidate model…"
		if _try_next_ai_candidate(timeout_toast):
			return
		if is_smart_commit:
			_fallback_smart_commit("The model timed out.")
			return
		_show_toast("Response timeout exceeded. Request cancelled.", true)
		_append_chat(_ai_provider.to_upper(), "The model timed out. The request was cancelled automatically.", Color("#ff7800"))
		return

	if body.is_empty():
		if _try_next_ai_candidate("Empty response. Attempting candidate model…"):
			return
		if is_smart_commit:
			_fallback_smart_commit("Empty server response.")
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
			var thought := _extract_reasoning(msg)
			if not thought.is_empty():
				_thinking_text = thought
				_refresh_thinking_panel()
			var reply_text: String = str(msg.get("content", "")).strip_edges()
			if reply_text.is_empty() and not thought.is_empty():
				reply_text = thought
			if not reply_text.is_empty():

				## ── Smart Commit intercept ──────────────────────────────────────
				if _current_prompt.begins_with("__SMART_COMMIT__:"):
					var commit_msg := reply_text.strip_edges()
					commit_msg = commit_msg.trim_prefix("```").trim_suffix("```").strip_edges()
					if commit_msg.is_empty():
						_fallback_smart_commit("The AI returned an empty message.")
						return
					_finish_smart_commit(commit_msg, true)
					return
				## ── End smart commit ────────────────────────────────────────────

				_chat_history.append({"role": "assistant", "content": reply_text})
				var usage: Dictionary = parsed.get("usage", {})
				var prompt_tokens: int = int(usage.get("prompt_tokens", float(_current_prompt.length()) / 4.0))
				var completion_tokens: int = int(usage.get("completion_tokens", float(reply_text.length()) / 4.0))
				_clear_ai_busy()
				_append_ai_response(_ai_provider, reply_text, elapsed, prompt_tokens, completion_tokens)
				return
	elif response_code in [200, 201] and not text.strip_edges().is_empty() and not text.begins_with("{"):
		_chat_history.append({"role": "assistant", "content": text.strip_edges()})
		_clear_ai_busy()
		_append_ai_response(_ai_provider, text.strip_edges(), elapsed)
		return

	# 401 is the key, not the model — do not cycle candidates with the same secret.
	if response_code == 401:
		AIService.invalidate_cached_api_key()
		if is_smart_commit:
			_fallback_smart_commit("The NVIDIA NIM key was rejected (HTTP 401).")
			_prompt_api_key(true, Callable())
			return
		_smart_commit_prompt = ""
		_clear_ai_busy()
		_show_toast("NVIDIA NIM rejected the API key (HTTP 401). Enter a new key.", true)
		_append_chat(_ai_provider.to_upper(), "Could not retrieve response (HTTP 401). The API key was rejected. Paste a new NVIDIA NIM key to continue.", Color("#ed333b"))
		var retry_prompt := _current_prompt
		_prompt_api_key(true, func() -> void:
			if retry_prompt.is_empty() or retry_prompt.begins_with("__SMART_COMMIT__:"):
				return
			_ask_ai(retry_prompt)
		)
		return

	if _try_next_ai_candidate("Server busy. Attempting candidate model…"):
		return
	if is_smart_commit:
		_fallback_smart_commit("AI service error (HTTP %d)." % response_code)
		return
	var err_detail: String = ""
	if parsed is Dictionary and parsed.has("error"):
		var err_dict: Dictionary = parsed["error"] if parsed["error"] is Dictionary else {}
		err_detail = " — " + str(err_dict.get("message", parsed["error"]))
	_show_toast("AI Service Error (HTTP %d)" % response_code, true)
	_append_chat(_ai_provider.to_upper(), "Could not retrieve response (HTTP %d)%s." % [response_code, err_detail], Color("#ed333b"))


func _append_user_message(prompt: String) -> void:
	var sanitized: String = prompt.replace("[", "[lb]")
	var user_bubble := "\n[right][b]Ser Superior (SS)[/b]  [bgcolor=#62a0ea][color=#000000][b] SS [/b][/color][/bgcolor][/right]\n[right][bgcolor=#1a324b][color=#f6f5f4]   %s   [/color][/bgcolor][/right]\n\n" % sanitized
	_chat_log.append_text(user_bubble)
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _append_ai_response(_provider: String, reply_text: String, elapsed: float, tokens_in: int = 0, tokens_out: int = 0) -> void:
	var stats_header := ""
	if tokens_in > 0 and tokens_out > 0:
		stats_header = "[bgcolor=#57e389][color=#000000][b] AI [/b][/color][/bgcolor] [b]SSBot[/b] [color=#57e389]● Online[/color] [color=#ffa348]%.1fk in | %.1fk out[/color] [color=#9a9996](%.1fs)[/color]\n\n" % [tokens_in / 1000.0, tokens_out / 1000.0, elapsed]
	else:
		stats_header = "[bgcolor=#57e389][color=#000000][b] AI [/b][/color][/bgcolor] [b]SSBot[/b] [color=#57e389]● Online[/color] [color=#9a9996](%.1fs)[/color]\n\n" % elapsed

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
		elif formatted_line.begins_with("- [ ] ") or formatted_line.begins_with("* [ ] "):
			formatted_line = "  [color=#9a9996]☐[/color] " + formatted_line.substr(6)
		elif formatted_line.begins_with("- [x] ") or formatted_line.begins_with("* [x] ") or formatted_line.begins_with("- [X] "):
			formatted_line = "  [color=#57e389]✔[/color] " + formatted_line.substr(6)
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
