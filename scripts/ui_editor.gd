extends Control

## SSCodeIDE — root controller. All nodes live in ui_editor.tscn.

const ChatMarkdown = preload("res://scripts/chat_markdown_renderer.gd")
const AgentWorkspace = preload("res://scripts/agent_workspace_service.gd")
const CodeEditorTools = preload("res://scripts/code_editor_service.gd")
const MarkdownPreview = preload("res://scripts/markdown_preview_renderer.gd")
const ThemeResources = preload("res://scripts/theme_resource_registry.gd")

@onready var _root_vbox: Control = (get_node_or_null("%AppHBox") if get_node_or_null("%AppHBox") else get_node_or_null("%RootVBox")) as Control
@onready var _file_tree: Tree = %FileTree
@onready var _tab_bar: TabBar = %TabBar
@onready var _code_edit: CodeEdit = %CodeEdit
@onready var _chat_log: RichTextLabel = %ChatLog
@onready var _chat_context_badge: Label = %ChatContextBadge
@onready var _chat_context_chip: Button = %ChatContextChip
@onready var _chat_input: LineEdit = %ChatInput
@onready var _attach_btn: Button = %AttachBtn
@onready var _agent_mode_btn: Button = %AgentModeBtn
@onready var _provider_select: OptionButton = %ProviderSelect
@onready var _smart_commit_btn: Button = %SmartCommitBtn
@onready var _chat_send: Button = %ChatSend
@onready var _status_left: Label = %StatusLeft
@onready var _status_git: Button = %StatusGit
@onready var _status_cursor: Label = %StatusCursor
@onready var _status_lang: Label = %StatusLang
@onready var _status_enc: Label = %StatusEnc
@onready var _status_ai: Label = %StatusAI
@onready var _main_split: HSplitContainer = %MainSplit
@onready var _center_split: HSplitContainer = %CenterSplit
@onready var _explorer_pane: PanelContainer = %ExplorerPane
@onready var _chat_pane: PanelContainer = %ChatPane
@onready var _explorer_toggle_btn: Button = %ExplorerToggleBtn
@onready var _chat_toggle_btn: Button = %ChatToggleBtn
@onready var _explorer_rail_btn: Button = get_node_or_null("%ExplorerRailBtn") as Button
@onready var _edit_rail_btn: Button = get_node_or_null("%EditRailBtn") as Button
@onready var _git_rail_btn: Button = get_node_or_null("%GitRailBtn") as Button
@onready var _themes_rail_btn: Button = get_node_or_null("%ThemesRailBtn") as Button
@onready var _chat_rail_btn: Button = get_node_or_null("%ChatRailBtn") as Button
@onready var _config_rail_btn: Button = get_node_or_null("%ConfigRailBtn") as Button
@onready var _help_rail_btn: Button = get_node_or_null("%HelpRailBtn") as Button
@onready var _drawer_collapse_btn: Button = get_node_or_null("%DrawerCollapseBtn") as Button
@onready var _switch_workspace_btn: Button = get_node_or_null("%SwitchWorkspaceBtn") as Button
@onready var _workspace_state: Label = get_node_or_null("%WorkspaceState") as Label
@onready var _file_menu: PopupMenu = %File
@onready var _edit_menu: PopupMenu = %Edit
@onready var _git_menu: PopupMenu = %Git
@onready var _config_menu: PopupMenu = %Config
@onready var _help_menu: PopupMenu = %Help
@onready var _about_menu: PopupMenu = get_node_or_null("%About") as PopupMenu
@onready var _app_brand: MenuButton = get_node_or_null("%AppBrand") as MenuButton
@onready var _theme_toggle_btn: Button = get_node_or_null("%ThemeToggleBtn") as Button
@onready var _themes_menu: PopupMenu = %Themes
@onready var _open_file_dlg: FileDialog = %OpenFileDialog
@onready var _open_dir_dlg: FileDialog = %OpenDirDialog
@onready var _save_as_dlg: FileDialog = %SaveAsDialog
@onready var _open_theme_xml_dlg: FileDialog = %OpenThemeXmlDialog
@onready var _overlay: ColorRect = %Overlay
@onready var _dialog_panel: PanelContainer = %DialogPanel
@onready var _dialog_title: Label = %DialogTitle
@onready var _dialog_body: RichTextLabel = %DialogBody
@onready var _dialog_input_row: HBoxContainer = %DialogInputRow
@onready var _dialog_input: LineEdit = %DialogInput
@onready var _dialog_action_btn: Button = %DialogActionBtn
@onready var _dialog_close: Button = %DialogClose
@onready var _ai_chat_http: HTTPRequest = %AIChatHttp
@onready var _chat_status_banner: PanelContainer = %ChatStatusBanner
@onready var _chat_status_label: RichTextLabel = %ChatStatusLabel
@onready var _chat_thinking_label: RichTextLabel = %ChatThinkingLabel
@onready var _chat_suggestions_popup: PanelContainer = %ChatSuggestionsPopup
@onready var _chat_suggestions_list: ItemList = %ChatSuggestionsList
@onready var _find_row: HBoxContainer = %FindRow
@onready var _find_input: LineEdit = %FindInput
@onready var _replace_input: LineEdit = %ReplaceInput
@onready var _replace_all: Button = %ReplaceAll
@onready var _find_next: Button = %FindNext
@onready var _find_close: Button = %FindClose
@onready var _markdown_preview: RichTextLabel = %MarkdownPreview

var _dialog_action_callback: Callable = Callable()

var _workspace_root: String = ""
var _custom_themes: Dictionary[String, Dictionary] = {}  ## User-installed themes loaded from XML files
var _theme_menu_keys: Array[String] = []
var _open_files: Array = []  ## Publicly mutable; entries are normalised as Dictionary on use.
var _active_index: int = -1
var _suppress_tab: bool = false
var _md_preview_active: bool = false
var _agent_mode: bool = true
var _ai_busy: bool = false
var _response_rendered: bool = false
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
const THEME_MENU_IMPORT_ID: int = 10_000

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
	"jakes_theme": {
		"label": "Jake's Theme",
		"bg_black": "#000000", "bg_darker": "#000000", "bg_surface": "#000000",
		"bg_card": "#0a0a0a", "bg_lighter": "#080808",
		"fg": "#e0e0e0", "fg_bright": "#ffffff", "muted": "#858585",
		"blue": "#8be9fd", "green": "#57e389", "cyan": "#62a0ea", "red": "#ed333b",
		"hl_number": "#ffa348", "hl_symbol": "#9a9996", "hl_func": "#62a0ea",
		"hl_member": "#99c1f1", "hl_comment": "#9a9996", "hl_string": "#57e389",
		"hl_keyword": "#8be9fd", "hl_type": "#62a0ea", "hl_const": "#ffa348",
	},
	"terminal": {
		"label": "Terminal (Antigravity)",
		"bg_black": "#000000", "bg_darker": "#050505", "bg_surface": "#0a0a0c",
		"bg_card": "#121216", "bg_lighter": "#1a1a20",
		"fg": "#deddda", "fg_bright": "#ffffff", "muted": "#9a9996",
		"blue": "#62a0ea", "green": "#57e389", "cyan": "#5bc8af", "red": "#ed333b",
		"hl_number": "#ffa348", "hl_symbol": "#5bc8af", "hl_func": "#62a0ea",
		"hl_member": "#99c1f1", "hl_comment": "#9a9996", "hl_string": "#57e389",
		"hl_keyword": "#62a0ea", "hl_type": "#5bc8af", "hl_const": "#ffa348",
	},
	"solarized_dark": {
		"label": "Solarized Dark",
		"bg_black": "#001e26", "bg_darker": "#002731", "bg_surface": "#002b36",
		"bg_card": "#073642", "bg_lighter": "#0e4a5a",
		"fg": "#839496", "fg_bright": "#fdf6e3", "muted": "#586e75",
		"blue": "#268bd2", "green": "#859900", "cyan": "#2aa198", "red": "#dc322f",
		"hl_number": "#d33682", "hl_symbol": "#657b83", "hl_func": "#268bd2",
		"hl_member": "#b58900", "hl_comment": "#586e75", "hl_string": "#859900",
		"hl_keyword": "#cb4b16", "hl_type": "#2aa198", "hl_const": "#6c71c4",
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
	{"cmd": "/quit", "desc": "Quit SSCodeIDE"},
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

Interface: system sans-serif · Code editor: FiraCode Nerd Font
AI Chat: Nemotron · Kimi K3 · DeepSeek V4 · Laguna Code via NVIDIA NIM API
Automatic Toast · Multi-Turn Context Memory · Intelligent Candidate Fallback

© Ser Superior (SS)
"""


func _ready() -> void:
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
	var body: String = _format_thinking_text(_thinking_text)
	if body.is_empty():
		body = "Waiting for the model’s reasoning tokens…"
	_chat_thinking_label.text = "[color=#9a9996][i]%s[/i][/color]" % body.replace("[", "[lb]")


func _format_thinking_text(raw: String) -> String:
	## Reasoning streams often contain Markdown, XML tags and excessive whitespace.
	## Keep this preview short and readable; the final answer remains untouched.
	var body := raw.replace("\r\n", "\n").replace("\r", "\n")
	body = body.replace("<think>", "").replace("</think>", "")
	var lines: PackedStringArray = []
	for line in body.split("\n"):
		var clean := line.strip_edges()
		clean = clean.trim_prefix("###").strip_edges()
		clean = clean.trim_prefix("**").trim_suffix("**").strip_edges()
		if clean.is_empty() or (not lines.is_empty() and lines[-1] == clean):
			continue
		lines.append(clean)
	var result := "\n".join(lines)
	# Some providers omit whitespace between streamed reasoning tokens.
	var spacing := RegEx.new()
	spacing.compile("([a-z])([A-Z])")
	result = spacing.sub(result, "$1 $2", true)
	if result.length() > 1800:
		result = result.substr(result.length() - 1800, 1800)
		result = "… " + result
	return result


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
					var separator := "" if _thinking_text.is_empty() or _thinking_text.ends_with(" ") or thought.begins_with(" ") else " "
					_thinking_text += separator + thought
			var piece := str(src.get("content", ""))
			if not piece.is_empty() and piece != "<null>":
				_stream_reply += piece


func _finish_chat_stream() -> void:
	if _response_rendered:
		return
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
	_response_rendered = true
	reply = _execute_agent_file_writes(reply)
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
	if _explorer_toggle_btn:
		_explorer_toggle_btn.text = "◀"
	_status_left.text = "Explorer  ▶  shown"


func _collapse_explorer(save_offset: bool) -> void:
	if _explorer_collapsed:
		return
	if save_offset and _main_split.split_offset > SPLIT_COLLAPSE_PX:
		_explorer_split_offset = _main_split.split_offset
	_explorer_collapsed = true
	_explorer_pane.visible = false
	if _explorer_toggle_btn:
		_explorer_toggle_btn.text = "▶"
	_status_left.text = "Explorer  ◀  hidden  (Ctrl+B to restore)"


func _expand_chat() -> void:
	_chat_collapsed = false
	_chat_pane.visible = true
	var target := _chat_split_offset if _chat_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.50)
	_center_split.split_offset = target
	if _chat_toggle_btn:
		_chat_toggle_btn.text = "▶"
	_status_left.text = "Chat  ▶  shown"


func _collapse_chat(save_offset: bool) -> void:
	if _chat_collapsed:
		return
	if save_offset and _center_split.split_offset > SPLIT_COLLAPSE_PX:
		_chat_split_offset = _center_split.split_offset
	_chat_collapsed = true
	_chat_pane.visible = false
	if _chat_toggle_btn:
		_chat_toggle_btn.text = "◀"
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
	_code_edit.gui_input.connect(_on_code_editor_gui_input)
	_code_edit.caret_changed.connect(_on_caret_changed)
	_chat_input.text_submitted.connect(_on_chat_submitted)
	_chat_log.meta_clicked.connect(_on_chat_meta_clicked)
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
	_populate_themes_menu()
	if _themes_menu:
		_themes_menu.id_pressed.connect(_on_theme_menu_id_pressed)
	if _status_git:
		_status_git.pressed.connect(_show_git_status_dialog)
	_config_menu.id_pressed.connect(_on_config_menu)
	_help_menu.id_pressed.connect(_on_help_menu)
	if _about_menu:
		_about_menu.id_pressed.connect(_on_about_menu)
	if _app_brand:
		_setup_app_brand_menu()
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
	_replace_all.pressed.connect(_replace_all_matches)
	_find_close.pressed.connect(func() -> void: _find_row.visible = false)
	_chat_suggestions_list.item_selected.connect(_on_chat_suggestion_selected)
	_chat_suggestions_list.item_activated.connect(_on_chat_suggestion_selected)
	_main_split.dragged.connect(_on_main_split_dragged)
	_center_split.dragged.connect(_on_center_split_dragged)
	_explorer_toggle_btn.pressed.connect(_toggle_explorer)
	_chat_toggle_btn.pressed.connect(_toggle_chat)
	if _explorer_rail_btn:
		_explorer_rail_btn.pressed.connect(_toggle_explorer)
	if _edit_rail_btn:
		_edit_rail_btn.pressed.connect(func() -> void:
			if _edit_menu:
				_edit_menu.popup_on_parent(Rect2i(_edit_rail_btn.get_global_rect()))
		)
	if _git_rail_btn:
		_git_rail_btn.pressed.connect(func() -> void:
			if _git_menu:
				_git_menu.popup_on_parent(Rect2i(_git_rail_btn.get_global_rect()))
		)
	if _themes_rail_btn:
		_themes_rail_btn.pressed.connect(func() -> void:
			if _themes_menu:
				_themes_menu.popup_on_parent(Rect2i(_themes_rail_btn.get_global_rect()))
		)
	if _chat_rail_btn:
		_chat_rail_btn.pressed.connect(_toggle_chat)
	if _config_rail_btn:
		_config_rail_btn.pressed.connect(func() -> void:
			if _config_menu:
				_config_menu.popup_on_parent(Rect2i(_config_rail_btn.get_global_rect()))
		)
	if _help_rail_btn:
		_help_rail_btn.pressed.connect(func() -> void:
			if _help_menu:
				_help_menu.popup_on_parent(Rect2i(_help_rail_btn.get_global_rect()))
		)
	if _drawer_collapse_btn:
		_drawer_collapse_btn.pressed.connect(_toggle_explorer)
	if _switch_workspace_btn:
		_switch_workspace_btn.pressed.connect(func() -> void:
			_open_dir_dlg.popup_centered()
		)


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
	if key.keycode == KEY_DELETE and _file_tree.has_focus():
		_delete_selected_file()
		get_viewport().set_input_as_handled()
		return

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
	if ctrl and key.keycode == KEY_H:
		_find_row.visible = true
		_replace_input.visible = true
		_replace_all.visible = true
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


func _on_code_editor_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.ctrl_pressed and key.keycode == KEY_F:
		_find_row.visible = true
		_find_input.grab_focus()
		get_viewport().set_input_as_handled()
	elif key.ctrl_pressed and key.keycode == KEY_H:
		_find_row.visible = true
		_replace_input.visible = true
		_replace_all.visible = true
		_find_input.grab_focus()
		get_viewport().set_input_as_handled()


func _delete_selected_file() -> void:
	var item := _file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if not (meta is Dictionary) or bool(meta.get("is_dir", false)):
		return
	var path := str(meta.get("path", ""))
	if path.is_empty() or not path.begins_with(_workspace_root.simplify_path() + "/"):
		return
	if DirAccess.remove_absolute(path) == OK:
		_refresh_file_tree()
		_status_left.text = "DELETED: " + path.get_file()


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


func _setup_app_brand_menu() -> void:
	if _app_brand == null:
		return
	var popup := _app_brand.get_popup()
	if not popup.id_pressed.is_connected(_on_app_brand_menu_id_pressed):
		popup.id_pressed.connect(_on_app_brand_menu_id_pressed)
	if _theme_toggle_btn and not _theme_toggle_btn.pressed.is_connected(_toggle_light_dark_theme):
		_theme_toggle_btn.pressed.connect(_toggle_light_dark_theme)
	_update_app_brand_menu()
	_update_theme_toggle_btn()


func _update_app_brand_menu() -> void:
	if _app_brand == null:
		return
	var popup := _app_brand.get_popup()
	popup.clear()
	popup.add_item("About SSCodeIDE", 1)
	popup.add_item("Close\tCtrl+Q", 2)


func _update_theme_toggle_btn() -> void:
	if _theme_toggle_btn == null:
		return
	var is_light := ThemeColorScheme.is_light(_active_theme)
	# In light mode, show moon icon to switch to dark; in dark mode, show sun icon to switch to light
	_theme_toggle_btn.icon = preload("res://icons/nav_moon.svg") if is_light else preload("res://icons/nav_sun.svg")
	_theme_toggle_btn.text = ""
	_theme_toggle_btn.tooltip_text = "Switch to Dark Mode" if is_light else "Switch to Light Mode"


func _toggle_light_dark_theme() -> void:
	var is_light := ThemeColorScheme.is_light(_active_theme)
	var target := ""
	if is_light:
		target = ThemeColorScheme.get_dark_variant(_active_theme)
		if target.is_empty():
			target = "adwaita_darker"
	else:
		target = ThemeColorScheme.get_light_variant(_active_theme)
		if target.is_empty():
			target = "adwaita_lighter"
	_apply_theme_by_name(target)


func _on_app_brand_menu_id_pressed(id: int) -> void:
	match id:
		1:
			_show_about()
		2:
			get_tree().quit()


func _on_file_menu(id: int) -> void:
	match id:
		0: _open_file_dlg.popup_centered()
		1: _open_dir_dlg.popup_centered()
		3: _open_untitled()
		4: _save_active()
		5: _save_as_dlg.popup_centered()


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
	var body := "[b]Settings[/b]\n\n• [b]Typography:[/b] system interface font · FiraCode in editor\n• [b]Workspace:[/b] %s\n• [b]Active Model:[/b] %s (NVIDIA NIM)\n• [b]API key:[/b] %s\n• [b]Status:[/b] %s\n\nUse Config → NVIDIA NIM API key… to change the stored key." % [
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
	if not _all_themes().has(_active_theme) or ThemeResources.load_theme(_active_theme) == null:
		_active_theme = "adwaita_darker"


func _save_theme_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ui_config.cfg")
	cfg.set_value("theme", "name", _active_theme)
	cfg.save("user://ui_config.cfg")


func _apply_theme_by_name(_name: String) -> void:
	if _name == _active_theme:
		return
	var previous_theme := _active_theme
	_active_theme = _name
	if not _apply_kitty_fish_theme():
		_active_theme = previous_theme
		_append_chat("IDE", "[color=#ed333b]Theme not found:[/color] " + _name, Color("#ed333b"))
		_show_toast("Theme not found: " + _name, true)
		return
	_save_theme_config()
	var label: String = str(_all_themes().get(_name, {}).get("label", _name))
	_populate_themes_menu()
	_update_app_brand_menu()
	_update_theme_toggle_btn()
	_append_chat("IDE", "[color=#57e389]Theme applied:[/color] [b]" + label + "[/b]", Color("#57e389"))
	_show_toast("Theme: " + label, false)


func _populate_themes_menu() -> void:
	## The NavBar is the single visible theme selector. Theme resources supply
	## their visual treatment, including this popup, rather than runtime styles.
	if _themes_menu == null:
		return
	_themes_menu.clear()
	_theme_menu_keys.clear()
	var keys: Array[String] = []
	for raw_key in _all_themes().keys():
		var key := str(raw_key)
		if ThemeResources.load_theme(key) != null:
			keys.append(key)
	keys.sort_custom(func(left: String, right: String) -> bool:
		return str(_all_themes()[left].get("label", left)).naturalnocasecmp_to(str(_all_themes()[right].get("label", right))) < 0
	)
	for key in keys:
		var info: Dictionary = _all_themes()[key]
		var item_index := _themes_menu.item_count
		var label: String = str(info.get("label", key))
		if _custom_themes.has(key):
			label += "  (XML)"
		_themes_menu.add_radio_check_item(label, _theme_menu_keys.size())
		_themes_menu.set_item_checked(item_index, key == _active_theme)
		_themes_menu.set_item_tooltip(item_index, "Currently selected" if key == _active_theme else "Apply " + str(info.get("label", key)))
		_theme_menu_keys.append(key)
	if _theme_menu_keys.is_empty():
		_themes_menu.add_item("No theme resources available")
		_themes_menu.set_item_disabled(0, true)
	_themes_menu.add_separator()
	_themes_menu.add_item("Import XML theme…", THEME_MENU_IMPORT_ID)


func _on_theme_menu_id_pressed(id: int) -> void:
	if id == THEME_MENU_IMPORT_ID:
		_import_theme_xml_dialog()
		return
	if id >= 0 and id < _theme_menu_keys.size():
		_apply_theme_by_name(_theme_menu_keys[id])


func _load_custom_themes() -> void:
	## Scans user://themes/ and loads all valid .xml theme files into _custom_themes
	_custom_themes.clear()
	var dir := DirAccess.open("user://themes")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir() and fname.ends_with(".xml"):
			var path := "user://themes/" + fname
			var result := _parse_theme_xml(path)
			if not result.is_empty():
				var key: String = ThemeResources.safe_key(str(result.get("key", fname.trim_suffix(".xml"))))
				result["key"] = key
				_custom_themes[key] = result
				if ThemeResources.load_theme(key) == null:
					ThemeResources.save_custom_theme(key, result)
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
	var key: String = ThemeResources.safe_key(str(parsed.get("key", "custom")))
	parsed["key"] = key
	var dest_name: String = key + ".xml"
	var dest_path := "user://themes/" + dest_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://themes"))
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
	if ThemeResources.save_custom_theme(key, parsed) != OK:
		_append_chat("IDE", "[color=#ed333b]Could not compile the imported theme resource.[/color]", Color("#ed333b"))
		_show_toast("Theme import failed.", true)
		return
	## Reload and apply
	_load_custom_themes()
	_populate_themes_menu()
	var label: String = str(parsed.get("label", key))
	_apply_theme_by_name(key)
	_append_chat("IDE", "[color=#57e389]Theme imported:[/color] [b]" + label + "[/b]\nSaved as XML and Theme resource in: [color=#9a9996]user://themes/[/color]", Color("#57e389"))
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


func _apply_kitty_fish_theme() -> bool:
	## Theme assets are authored in Godot resources. This only selects one;
	## it deliberately does not build or override any visual styles at runtime.
	if not _apply_theme_resource(_active_theme):
		return false
	_code_edit.syntax_highlighter = _create_adwaita_fish_highlighter()
	return true


func _apply_theme_resource(theme_name: String) -> bool:
	var selected := ThemeResources.load_theme(theme_name)
	if selected == null:
		return false
	theme = selected
	_root_vbox.theme = selected
	return true

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


func _markdown_to_bbcode(markdown: String) -> String:
	return MarkdownPreview.render(markdown)


func _is_table_row(line: String) -> bool:
	return MarkdownPreview.is_table_row(line)


func _is_table_separator(line: String) -> bool:
	return MarkdownPreview.is_table_separator(line)


func _render_preview_table(rows: Array[String]) -> String:
	return MarkdownPreview.render_table(rows)


func _split_table_row(row: String) -> Array[String]:
	return MarkdownPreview.split_table_row(row)


func _md_inline(text: String) -> String:
	return MarkdownPreview.inline(text)


func _configure_code_edit() -> void:
	CodeEditorTools.configure(_code_edit, _active_palette(), _open_files)


func _update_code_completion() -> void:
	CodeEditorTools.update_completion(_code_edit, _open_files)


func _create_adwaita_fish_highlighter() -> CodeHighlighter:
	return CodeEditorTools.create_highlighter(_active_palette())


func _active_palette() -> Dictionary:
	## XML themes carry the same palette schema as built-ins, so syntax and
	## editor affordances follow the visual resource selected from the NavBar.
	return _all_themes().get(_active_theme, THEMES["adwaita_darker"])


func _refresh_file_tree() -> void:
	_file_tree.clear()
	var root_item: TreeItem = _file_tree.create_item()
	var root_title: String = _workspace_root.get_file()
	if root_title.is_empty():
		root_title = "WORKSPACE"
	if _workspace_state:
		_workspace_state.text = root_title.to_upper()
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


func _replace_all_matches() -> void:
	var query := _find_input.text
	if query.is_empty():
		return
	var old_text := _code_edit.text
	var new_text := old_text.replace(query, _replace_input.text)
	if new_text != old_text:
		_code_edit.text = new_text


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
			_append_chat("IDE", "[color=#9a9996]Themes are now selected from the [b]Themes[/b] menu in the navigation bar.[/color]", Color("#9a9996"))
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
	_response_rendered = false
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
				"When you need to create or edit a workspace file, emit one or more blocks exactly as `<sscode-write path=\"relative/path\">file contents</sscode-write>`. Use workspace-relative paths only. The IDE executes these blocks; do not merely describe the change.\n" +
				"To delete a file, emit `<sscode-delete path=\"relative/path\"/>`. Use this only when the user explicitly requests deletion.\n" +
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
	if _response_rendered:
		return
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
				reply_text = _execute_agent_file_writes(reply_text)

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
		var plain_reply := _execute_agent_file_writes(text.strip_edges())
		_chat_history.append({"role": "assistant", "content": plain_reply})
		_clear_ai_busy()
		_append_ai_response(_ai_provider, plain_reply, elapsed)
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


func _on_chat_meta_clicked(meta: Variant) -> void:
	var value := str(meta)
	if value.begins_with("copy:"):
		DisplayServer.clipboard_set(Marshalls.base64_to_raw(value.trim_prefix("copy:")).get_string_from_utf8())
		_show_toast("Code copied to clipboard.", false)


func _append_ai_response(_provider: String, reply_text: String, elapsed: float, tokens_in: int = 0, tokens_out: int = 0) -> void:
	var stats_header := ""
	if tokens_in > 0 and tokens_out > 0:
		stats_header = "[bgcolor=#57e389][color=#000000][b] AI [/b][/color][/bgcolor] [b]SSBot[/b] [color=#57e389]● Online[/color] [color=#ffa348]%.1fk in | %.1fk out[/color] [color=#9a9996](%.1fs)[/color]\n\n" % [tokens_in / 1000.0, tokens_out / 1000.0, elapsed]
	else:
		stats_header = "[bgcolor=#57e389][color=#000000][b] AI [/b][/color][/bgcolor] [b]SSBot[/b] [color=#57e389]● Online[/color] [color=#9a9996](%.1fs)[/color]\n\n" % elapsed

	var formatted_body := _format_markdown_to_bbcode(reply_text)
	_chat_log.append_text("%s%s\n\n[color=#202024]────────────────────────────────────────────────[/color]\n\n" % [stats_header, formatted_body])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _execute_agent_file_writes(reply: String) -> String:
	var result := AgentWorkspace.execute_markup(reply, _workspace_root)
	for path: String in result.written_paths:
		_reload_open_file(path)
	for path: String in result.deleted_paths:
		_close_open_file_path(path)
	if not result.written_paths.is_empty() or not result.deleted_paths.is_empty():
		_refresh_file_tree()
	return str(result.reply) + str(result.report)


func _reload_open_file(path: String) -> void:
	for i in _open_files.size():
		if str(_open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				_open_files[i]["content"] = f.get_as_text()
				_open_files[i]["dirty"] = false
				if i == _active_index:
					_suppress_tab = true
					_code_edit.text = _open_files[i]["content"]
					_suppress_tab = false
					_update_cursor_status()
				_tab_bar.set_tab_title(i, str(_open_files[i].get("title", "")))


func _close_open_file_path(path: String) -> void:
	for i in range(_open_files.size() - 1, -1, -1):
		if str(_open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			_on_tab_close(i)


func _append_tool_badge(action: String, target: String) -> void:
	_chat_log.append_text("[color=#57e389]●[/color] [b]%s[/b][color=#9a9996](%s)[/color]\n\n" % [action, target])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _append_chat(who: String, msg_body: String, color: Color) -> void:
	var formatted := _format_markdown_to_bbcode(msg_body)
	_chat_log.append_text("[color=#%s][b]● %s[/b][/color] %s\n\n[color=#202024]────────────────────────────────────────────────[/color]\n\n" % [color.to_html(false), who, formatted])
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _format_markdown_to_bbcode(raw_text: String) -> String:
	return ChatMarkdown.render(raw_text)


func _format_code_block(code: String, language: String) -> String:
	return ChatMarkdown.format_code_block(code, language)


func _replace_bold(text: String) -> String:
	return ChatMarkdown.replace_bold(text)


func _replace_inline_code(text: String) -> String:
	return ChatMarkdown.replace_inline_code(text)


func _replace_italic(text: String) -> String:
	return ChatMarkdown.replace_italic(text)


func _replace_links(text: String) -> String:
	return ChatMarkdown.replace_links(text)
