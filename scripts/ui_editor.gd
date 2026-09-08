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
@onready var _chat_context_badge: Label = get_node_or_null("%ChatContextBadge") as Label
@onready var _chat_context_chip: Button = %ChatContextChip
@onready var _chat_input: LineEdit = %ChatInput
@onready var _attach_btn: Button = %AttachBtn
@onready var _agent_mode_btn: MenuButton = get_node_or_null("%AgentModeBtn") as MenuButton
@onready var _model_badge_btn: MenuButton = get_node_or_null("%ModelBadgeBtn") as MenuButton
@onready var _provider_select: OptionButton = %ProviderSelect
@onready var _smart_commit_btn: Button = get_node_or_null("%SmartCommitBtn") as Button
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

enum SidebarTab { EXPLORER, SEARCH, GIT, THEMES, CONFIG, HELP }
var _current_sidebar_tab: SidebarTab = SidebarTab.EXPLORER
var _sidebar_search_panel: VBoxContainer = null
var _sidebar_git_panel: VBoxContainer = null
var _sidebar_themes_panel: VBoxContainer = null
var _sidebar_config_panel: VBoxContainer = null
var _sidebar_help_panel: VBoxContainer = null
var _git_status_tree: Tree = null
var _git_commit_msg_input: LineEdit = null
var _git_commit_btn: Button = null
var _git_smart_commit_btn: Button = null
var _git_push_btn: Button = null
var _git_pull_btn: Button = null
var _git_sync_btn: Button = null
var _git_progress_panel: VBoxContainer = null
var _git_progress_bar: ProgressBar = null
var _git_progress_label: Label = null
var _git_console_panel: PanelContainer = null
var _git_console_log: RichTextLabel = null
var _themes_list: ItemList = null
var _search_query_input: LineEdit = null
var _search_replace_input: LineEdit = null
var _search_match_case_btn: Button = null
var _search_whole_word_btn: Button = null
var _search_include_input: LineEdit = null
var _search_exclude_input: LineEdit = null
var _search_results_tree: Tree = null
var _search_summary_label: Label = null
var _clear_chat_btn: Button = null
var _compact_chat_btn: Button = null
enum MdViewMode { SOURCE, PREVIEW, SPLIT }

const SPINNER_FRAMES: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
const OS_NOTIFY_EXPIRE_MS: int = 4000
const OS_NOTIFY_REPLACE_ID: int = 424242
const SPLIT_COLLAPSE_PX: int = 32
const THEME_MENU_IMPORT_ID: int = 10_000
const THEMES: Dictionary = ThemeColorScheme.MODE_THEMES

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
	{"cmd": "/search ", "desc": "Search the live Internet & web for up-to-date information (/search <query>)"},
	{"cmd": "/web ", "desc": "Search the live Internet & web for up-to-date information (/web <query>)"},
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
IDE in 100% native GDScript (Godot 4.7) — Dark and Light modes.

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
	_setup_sidebar_panels()
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
		if _current_prompt.begins_with("__SMART_COMMIT__:"):
			if _git_progress_panel:
				_git_progress_panel.visible = true
			if _git_progress_bar:
				var cycle_val: float = fmod(elapsed * 50.0, 100.0)
				_git_progress_bar.value = cycle_val
			if _git_progress_label:
				_git_progress_label.text = "⚡ A gerar mensagem de commit com IA... (%.1fs)" % elapsed
			_status_left.text = "%s Smart Commit · %s (%.1fs)" % [frame, _ai_provider, elapsed]
		else:
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
	_status_left.text = "Explorer  ▶  shown"
	_update_sidebar_tab_visibility()


func _collapse_explorer(save_offset: bool) -> void:
	if _explorer_collapsed:
		return
	if save_offset and _main_split.split_offset > SPLIT_COLLAPSE_PX:
		_explorer_split_offset = _main_split.split_offset
	_explorer_collapsed = true
	_explorer_pane.visible = false
	_status_left.text = "Explorer  ◀  hidden  (Ctrl+B to restore)"
	_update_sidebar_tab_visibility()


func _expand_chat() -> void:
	_chat_collapsed = false
	_chat_pane.visible = true
	var target := _chat_split_offset if _chat_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.50)
	_center_split.split_offset = target
	_status_left.text = "Chat  ▶  shown"
	_update_sidebar_tab_visibility()


func _collapse_chat(save_offset: bool) -> void:
	if _chat_collapsed:
		return
	if save_offset and _center_split.split_offset > SPLIT_COLLAPSE_PX:
		_chat_split_offset = _center_split.split_offset
	_chat_collapsed = true
	_chat_pane.visible = false
	_status_left.text = "Chat  ◀  hidden  (Ctrl+Shift+B to restore)"
	_update_sidebar_tab_visibility()


func _select_sidebar_tab(tab: SidebarTab) -> void:
	if not _explorer_collapsed and _current_sidebar_tab == tab:
		_collapse_explorer(true)
		return
	_current_sidebar_tab = tab
	_update_sidebar_tab_visibility()
	_expand_explorer()


func _update_sidebar_tab_visibility() -> void:
	_file_tree.visible = (_current_sidebar_tab == SidebarTab.EXPLORER)
	if _switch_workspace_btn:
		_switch_workspace_btn.visible = (_current_sidebar_tab == SidebarTab.EXPLORER)
	if _sidebar_search_panel:
		_sidebar_search_panel.visible = (_current_sidebar_tab == SidebarTab.SEARCH)
	if _sidebar_git_panel:
		_sidebar_git_panel.visible = (_current_sidebar_tab == SidebarTab.GIT)
		if _current_sidebar_tab == SidebarTab.GIT:
			_refresh_git_panel()
	if _sidebar_themes_panel:
		_sidebar_themes_panel.visible = (_current_sidebar_tab == SidebarTab.THEMES)
		if _current_sidebar_tab == SidebarTab.THEMES:
			_refresh_themes_panel()
	if _sidebar_config_panel:
		_sidebar_config_panel.visible = (_current_sidebar_tab == SidebarTab.CONFIG)
	if _sidebar_help_panel:
		_sidebar_help_panel.visible = (_current_sidebar_tab == SidebarTab.HELP)

	var rail_buttons := [
		[_explorer_rail_btn, _current_sidebar_tab == SidebarTab.EXPLORER],
		[_edit_rail_btn, _current_sidebar_tab == SidebarTab.SEARCH],
		[_git_rail_btn, _current_sidebar_tab == SidebarTab.GIT],
		[_themes_rail_btn, _current_sidebar_tab == SidebarTab.THEMES],
		[_config_rail_btn, _current_sidebar_tab == SidebarTab.CONFIG],
		[_help_rail_btn, _current_sidebar_tab == SidebarTab.HELP],
	]
	for pair in rail_buttons:
		var btn: Button = pair[0]
		var is_active: bool = pair[1] and not _explorer_collapsed
		if btn:
			btn.theme_type_variation = &"M3RailButtonActive" if is_active else &"M3RailButton"

	if _chat_rail_btn:
		_chat_rail_btn.theme_type_variation = &"M3RailButtonActive" if not _chat_collapsed else &"M3RailButton"

	if _workspace_state:
		match _current_sidebar_tab:
			SidebarTab.EXPLORER:
				var root_title: String = _workspace_root.get_file()
				_workspace_state.text = (root_title if not root_title.is_empty() else "WORKSPACE").to_upper()
			SidebarTab.SEARCH:
				_workspace_state.text = "SEARCH & REPLACE"
			SidebarTab.GIT:
				_workspace_state.text = "SOURCE CONTROL"
			SidebarTab.THEMES:
				_workspace_state.text = "THEMES & IMPORTS"
			SidebarTab.CONFIG:
				_workspace_state.text = "SETTINGS"
			SidebarTab.HELP:
				_workspace_state.text = "HELP & SHORTCUTS"


func _setup_sidebar_panels() -> void:
	var container: Node = _file_tree.get_parent()
	if not container:
		return

	# -------------------------------------------------------------
	# 1. Search Panel (VS Code Style Find/Replace in Workspace)
	# -------------------------------------------------------------
	_sidebar_search_panel = VBoxContainer.new()
	_sidebar_search_panel.name = "SidebarSearchPanel"
	_sidebar_search_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_search_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_search_panel.visible = false
	container.add_child(_sidebar_search_panel)

	var s_margin := MarginContainer.new()
	s_margin.add_theme_constant_override("margin_left", 8)
	s_margin.add_theme_constant_override("margin_right", 8)
	s_margin.add_theme_constant_override("margin_top", 4)
	s_margin.add_theme_constant_override("margin_bottom", 4)
	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 6)

	_search_query_input = LineEdit.new()
	_search_query_input.placeholder_text = "Search in workspace…"
	_search_query_input.clear_button_enabled = true
	_search_query_input.text_submitted.connect(func(t: String) -> void: _do_workspace_search(t))
	s_vbox.add_child(_search_query_input)

	_search_replace_input = LineEdit.new()
	_search_replace_input.placeholder_text = "Replace with…"
	_search_replace_input.clear_button_enabled = true
	s_vbox.add_child(_search_replace_input)

	var s_ctrl_row := HBoxContainer.new()
	s_ctrl_row.add_theme_constant_override("separation", 4)

	_search_match_case_btn = Button.new()
	_search_match_case_btn.text = "Aa"
	_search_match_case_btn.toggle_mode = true
	_search_match_case_btn.tooltip_text = "Match Case"
	s_ctrl_row.add_child(_search_match_case_btn)

	_search_whole_word_btn = Button.new()
	_search_whole_word_btn.text = "\\b"
	_search_whole_word_btn.toggle_mode = true
	_search_whole_word_btn.tooltip_text = "Match Whole Word"
	s_ctrl_row.add_child(_search_whole_word_btn)

	var search_run_btn := Button.new()
	search_run_btn.text = "Search"
	search_run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_run_btn.theme_type_variation = &"M3FilledButton"
	search_run_btn.pressed.connect(func() -> void:
		if _search_query_input:
			_do_workspace_search(_search_query_input.text)
	)
	s_ctrl_row.add_child(search_run_btn)

	var replace_all_btn := Button.new()
	replace_all_btn.text = "Replace All"
	replace_all_btn.pressed.connect(func() -> void:
		if _search_query_input and _search_replace_input:
			_replace_in_workspace(_search_query_input.text, _search_replace_input.text)
	)
	s_ctrl_row.add_child(replace_all_btn)
	s_vbox.add_child(s_ctrl_row)

	_search_include_input = LineEdit.new()
	_search_include_input.placeholder_text = "files to include (e.g. *.gd)"
	s_vbox.add_child(_search_include_input)

	_search_exclude_input = LineEdit.new()
	_search_exclude_input.placeholder_text = "files to exclude (e.g. .godot/*)"
	s_vbox.add_child(_search_exclude_input)

	_search_summary_label = Label.new()
	_search_summary_label.text = "0 results"
	_search_summary_label.theme_type_variation = &"M3StatusText"
	s_vbox.add_child(_search_summary_label)

	s_margin.add_child(s_vbox)
	_sidebar_search_panel.add_child(s_margin)

	_search_results_tree = Tree.new()
	_search_results_tree.hide_root = true
	_search_results_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_results_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_search_results_tree.theme_type_variation = &"M3ExplorerTree"
	_search_results_tree.item_activated.connect(_on_search_result_activated)
	_sidebar_search_panel.add_child(_search_results_tree)

	# -------------------------------------------------------------
	# 2. Git Panel (VS Code Style Source Control & GitHub)
	# -------------------------------------------------------------
	# 2. Source Control & GitHub Panel (VS Code Style, Dynamic & Spacious)
	# -------------------------------------------------------------
	_sidebar_git_panel = VBoxContainer.new()
	_sidebar_git_panel.name = "SidebarGitPanel"
	_sidebar_git_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_git_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_git_panel.visible = false
	container.add_child(_sidebar_git_panel)

	var git_vsplit := VSplitContainer.new()
	git_vsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	git_vsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	git_vsplit.split_offset = 240
	_sidebar_git_panel.add_child(git_vsplit)

	var top_git_vbox := VBoxContainer.new()
	top_git_vbox.add_theme_constant_override("separation", 8)
	top_git_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_git_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Commit Input & Actions Box
	var git_margin := MarginContainer.new()
	git_margin.add_theme_constant_override("margin_left", 8)
	git_margin.add_theme_constant_override("margin_right", 8)
	git_margin.add_theme_constant_override("margin_top", 6)
	git_margin.add_theme_constant_override("margin_bottom", 4)
	var git_vbox := VBoxContainer.new()
	git_vbox.add_theme_constant_override("separation", 8)

	_git_commit_msg_input = LineEdit.new()
	_git_commit_msg_input.placeholder_text = "Message (Ctrl+Enter to commit)"
	_git_commit_msg_input.custom_minimum_size = Vector2(0, 32)
	_git_commit_msg_input.clear_button_enabled = true
	_git_commit_msg_input.text_submitted.connect(func(msg: String) -> void: _commit_git_message(msg))
	git_vbox.add_child(_git_commit_msg_input)

	var commit_row := HBoxContainer.new()
	commit_row.add_theme_constant_override("separation", 6)

	_git_commit_btn = Button.new()
	_git_commit_btn.text = "Commit"
	_git_commit_btn.custom_minimum_size = Vector2(0, 32)
	var icon_commit: Texture2D = _load_svg_icon("res://icons/git_commit.svg")
	if icon_commit:
		_git_commit_btn.icon = icon_commit
		_git_commit_btn.expand_icon = true
	_git_commit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_commit_btn.theme_type_variation = &"M3FilledButton"
	_git_commit_btn.pressed.connect(func() -> void:
		if _git_commit_msg_input:
			_commit_git_message(_git_commit_msg_input.text)
	)
	commit_row.add_child(_git_commit_btn)

	_git_smart_commit_btn = Button.new()
	_git_smart_commit_btn.text = "Smart Commit"
	_git_smart_commit_btn.custom_minimum_size = Vector2(0, 32)
	var icon_sparkle: Texture2D = _load_svg_icon("res://icons/git_sparkle.svg")
	if icon_sparkle:
		_git_smart_commit_btn.icon = icon_sparkle
		_git_smart_commit_btn.expand_icon = true
	_git_smart_commit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_smart_commit_btn.theme_type_variation = &"M3NavPillButton"
	_git_smart_commit_btn.pressed.connect(_generate_smart_commit)
	commit_row.add_child(_git_smart_commit_btn)
	git_vbox.add_child(commit_row)

	# Emergent SmartCommit Progress UI (Sleek ProgressBar + Status Text, no heavy box)
	_git_progress_panel = VBoxContainer.new()
	_git_progress_panel.add_theme_constant_override("separation", 4)
	_git_progress_panel.visible = false

	var prog_status_row := HBoxContainer.new()
	prog_status_row.add_theme_constant_override("separation", 6)

	_git_progress_label = Label.new()
	_git_progress_label.text = "A gerar mensagem de commit com IA..."
	_git_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_progress_label.add_theme_font_size_override("font_size", 11)
	_git_progress_label.add_theme_color_override("font_color", Color("#A1A1A6"))
	prog_status_row.add_child(_git_progress_label)
	_git_progress_panel.add_child(prog_status_row)

	_git_progress_bar = ProgressBar.new()
	_git_progress_bar.show_percentage = false
	_git_progress_bar.custom_minimum_size = Vector2(0, 4)
	_git_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_progress_bar.min_value = 0.0
	_git_progress_bar.max_value = 100.0
	_git_progress_bar.value = 0.0

	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = Color("#222224")
	sb_bg.set_corner_radius_all(2)

	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = Color("#30D158")
	sb_fill.set_corner_radius_all(2)

	_git_progress_bar.add_theme_stylebox_override("background", sb_bg)
	_git_progress_bar.add_theme_stylebox_override("fill", sb_fill)

	_git_progress_panel.add_child(_git_progress_bar)
	git_vbox.add_child(_git_progress_panel)

	git_margin.add_child(git_vbox)
	top_git_vbox.add_child(git_margin)

	# Git Status Tree
	_git_status_tree = Tree.new()
	_git_status_tree.hide_root = true
	_git_status_tree.columns = 2
	_git_status_tree.set_column_expand(0, true)
	_git_status_tree.set_column_custom_minimum_width(1, 28)
	_git_status_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_status_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_git_status_tree.theme_type_variation = &"M3ExplorerTree"
	_git_status_tree.item_activated.connect(_on_git_status_item_activated)
	top_git_vbox.add_child(_git_status_tree)

	# Git Push, Pull, Sync Action Buttons
	var git_actions_margin := MarginContainer.new()
	git_actions_margin.add_theme_constant_override("margin_left", 8)
	git_actions_margin.add_theme_constant_override("margin_right", 8)
	git_actions_margin.add_theme_constant_override("margin_bottom", 6)
	var git_btn_box := HBoxContainer.new()
	git_btn_box.add_theme_constant_override("separation", 6)

	_git_push_btn = Button.new()
	_git_push_btn.text = "Push"
	_git_push_btn.custom_minimum_size = Vector2(0, 30)
	_git_push_btn.theme_type_variation = &"M3NavPillButton"
	var icon_push: Texture2D = _load_svg_icon("res://icons/git_push.svg")
	if icon_push:
		_git_push_btn.icon = icon_push
		_git_push_btn.expand_icon = true
	_git_push_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_push_btn.pressed.connect(func() -> void: _on_git_menu(3))
	git_btn_box.add_child(_git_push_btn)

	_git_pull_btn = Button.new()
	_git_pull_btn.text = "Pull"
	_git_pull_btn.custom_minimum_size = Vector2(0, 30)
	_git_pull_btn.theme_type_variation = &"M3NavPillButton"
	var icon_pull: Texture2D = _load_svg_icon("res://icons/git_pull.svg")
	if icon_pull:
		_git_pull_btn.icon = icon_pull
		_git_pull_btn.expand_icon = true
	_git_pull_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_pull_btn.pressed.connect(func() -> void: _on_git_menu(4))
	git_btn_box.add_child(_git_pull_btn)

	_git_sync_btn = Button.new()
	_git_sync_btn.text = "Sync"
	_git_sync_btn.custom_minimum_size = Vector2(0, 30)
	_git_sync_btn.theme_type_variation = &"M3NavPillButton"
	var icon_sync: Texture2D = _load_svg_icon("res://icons/git_sync.svg")
	if icon_sync:
		_git_sync_btn.icon = icon_sync
		_git_sync_btn.expand_icon = true
	_git_sync_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_sync_btn.pressed.connect(func() -> void: _on_git_menu(5))
	git_btn_box.add_child(_git_sync_btn)

	git_actions_margin.add_child(git_btn_box)
	top_git_vbox.add_child(git_actions_margin)
	git_vsplit.add_child(top_git_vbox)

	# Dedicated Git Output Console (Clean Borderless Inner Log)
	_git_console_panel = PanelContainer.new()
	_git_console_panel.custom_minimum_size = Vector2(0, 130)
	_git_console_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_console_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_git_console_panel.theme_type_variation = &"M3Composer"
	var console_margin := MarginContainer.new()
	console_margin.add_theme_constant_override("margin_left", 8)
	console_margin.add_theme_constant_override("margin_right", 8)
	console_margin.add_theme_constant_override("margin_top", 6)
	console_margin.add_theme_constant_override("margin_bottom", 6)
	var console_vbox := VBoxContainer.new()
	console_vbox.add_theme_constant_override("separation", 4)

	var console_hdr := HBoxContainer.new()
	var console_lbl := Label.new()
	console_lbl.text = "GIT OUTPUT LOGS"
	console_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_lbl.add_theme_color_override("font_color", Color("#A1A1A6"))
	console_lbl.add_theme_font_size_override("font_size", 11)
	console_hdr.add_child(console_lbl)

	var clear_console_b := Button.new()
	clear_console_b.text = "Clear"
	clear_console_b.flat = true
	clear_console_b.add_theme_color_override("font_color", Color("#8E8E93"))
	clear_console_b.add_theme_font_size_override("font_size", 11)
	clear_console_b.pressed.connect(func() -> void:
		if _git_console_log:
			_git_console_log.clear()
	)
	console_hdr.add_child(clear_console_b)
	console_vbox.add_child(console_hdr)

	_git_console_log = RichTextLabel.new()
	_git_console_log.bbcode_enabled = true
	_git_console_log.scroll_following = true
	_git_console_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_git_console_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var empty_box := StyleBoxEmpty.new()
	_git_console_log.add_theme_stylebox_override("normal", empty_box)
	_git_console_log.add_theme_stylebox_override("focus", empty_box)
	var fira_font: Font = load("res://fonts/FiraCodeNerdFont-Regular.ttf") as Font
	if fira_font:
		_git_console_log.add_theme_font_override("normal_font", fira_font)
	_git_console_log.add_theme_font_size_override("normal_font_size", 12)
	console_vbox.add_child(_git_console_log)
	console_margin.add_child(console_vbox)
	_git_console_panel.add_child(console_margin)
	git_vsplit.add_child(_git_console_panel)

	# -------------------------------------------------------------
	# 3. Themes Panel
	# -------------------------------------------------------------
	_sidebar_themes_panel = VBoxContainer.new()
	_sidebar_themes_panel.name = "SidebarThemesPanel"
	_sidebar_themes_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_themes_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_themes_panel.visible = false
	container.add_child(_sidebar_themes_panel)

	var th_lbl := Label.new()
	th_lbl.text = "Custom XML Themes:"
	_sidebar_themes_panel.add_child(th_lbl)

	_themes_list = ItemList.new()
	_themes_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_themes_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_themes_list.item_selected.connect(func(idx: int) -> void:
		var theme_name: String = str(_themes_list.get_item_metadata(idx))
		_apply_theme_by_name(theme_name)
	)
	_sidebar_themes_panel.add_child(_themes_list)

	var import_xml_btn := Button.new()
	import_xml_btn.text = "Import XML Theme…"
	import_xml_btn.pressed.connect(_import_theme_xml_dialog)
	_sidebar_themes_panel.add_child(import_xml_btn)

	# -------------------------------------------------------------
	# 4. Settings Panel
	# -------------------------------------------------------------
	_sidebar_config_panel = VBoxContainer.new()
	_sidebar_config_panel.name = "SidebarConfigPanel"
	_sidebar_config_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_config_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_config_panel.visible = false
	container.add_child(_sidebar_config_panel)

	var cfg_info := RichTextLabel.new()
	cfg_info.bbcode_enabled = true
	cfg_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cfg_info.text = "[b]Settings & AI Config[/b]\n\n"
	cfg_info.text += "[b]AI Provider:[/b] NVIDIA NIM / Nemotron\n"
	cfg_info.text += "[b]Workspace:[/b] " + _workspace_root + "\n\n"
	cfg_info.text += "[color=#8E8E93]Use top menu bar for advanced options.[/color]"
	_sidebar_config_panel.add_child(cfg_info)

	# -------------------------------------------------------------
	# 5. Help Panel
	# -------------------------------------------------------------
	_sidebar_help_panel = VBoxContainer.new()
	_sidebar_help_panel.name = "SidebarHelpPanel"
	_sidebar_help_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_help_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_help_panel.visible = false
	container.add_child(_sidebar_help_panel)

	var help_info := RichTextLabel.new()
	help_info.bbcode_enabled = true
	help_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_info.text = HELP_TEXT
static func _load_svg_icon(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			return res as Texture2D
	var abs_p := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _set_git_panel_busy(busy: bool) -> void:
	if _git_commit_msg_input:
		_git_commit_msg_input.editable = not busy
	if _git_commit_btn:
		_git_commit_btn.disabled = busy
	if _git_smart_commit_btn:
		_git_smart_commit_btn.disabled = busy
	if _git_push_btn:
		_git_push_btn.disabled = busy
	if _git_pull_btn:
		_git_pull_btn.disabled = busy
	if _git_sync_btn:
		_git_sync_btn.disabled = busy
	if _git_status_tree:
		_git_status_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE if busy else Control.MOUSE_FILTER_STOP


func _append_git_output(title: String, text: String, is_error: bool = false) -> void:
	if _git_console_log == null:
		return
	var title_color := "#ED333B" if is_error else "#57E389"
	var text_fmt := ChatMarkdown.render(text)
	_git_console_log.append_text("[b][color=%s]● %s[/color][/b]\n%s\n\n" % [title_color, title, text_fmt])
	_git_console_log.scroll_to_line(_git_console_log.get_line_count() - 1)
	if _current_sidebar_tab != SidebarTab.GIT:
		_select_sidebar_tab(SidebarTab.GIT)


func _commit_git_message(msg: String) -> void:
	var commit_text: String = msg.strip_edges()
	if commit_text.is_empty():
		_generate_smart_commit()
		return
	if not GitService.is_git_repository(_workspace_root):
		_append_git_output("Git Error", "No Git repository found in workspace.", true)
		return
	_set_git_panel_busy(true)
	GitService.stage_all(_workspace_root)
	var res: Dictionary = GitService.commit(commit_text, _workspace_root)
	if bool(res.get("success", false)):
		_append_git_output("Git Commit", "Commit created successfully:\n" + commit_text)
		_send_os_notification("Git Commit", "Committed: " + commit_text)
		if _git_commit_msg_input:
			_git_commit_msg_input.text = ""
		_update_git_status_bar()
		_refresh_git_panel()
	else:
		_append_git_output("Git Commit Failed", str(res.get("output", res.get("error", "Failed to commit"))), true)
		_send_os_notification("Git Commit Failed", str(res.get("error", "Failed to commit")), true)
	_set_git_panel_busy(false)


func _on_git_status_item_activated() -> void:
	if _git_status_tree == null:
		return
	var item: TreeItem = _git_status_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.has("path"):
		var full_p: String = str(meta.get("path", ""))
		if FileAccess.file_exists(full_p):
			_open_path(full_p)


func _refresh_git_panel() -> void:
	if _git_status_tree == null:
		return
	_git_status_tree.clear()
	var root := _git_status_tree.create_item()
	if not GitService.is_git_repository(_workspace_root):
		var item := _git_status_tree.create_item(root)
		item.set_text(0, "No Git repository found")
		return
	var st: Dictionary = GitService.get_status(_workspace_root)
	var branch: String = str(st.get("branch", "main"))
	var is_clean: bool = bool(st.get("is_clean", true))

	if _workspace_state and _current_sidebar_tab == SidebarTab.GIT:
		_workspace_state.text = "SOURCE CONTROL: " + branch.to_upper()

	var staged: Array = st.get("staged", [])
	if not staged.is_empty():
		var staged_cat := _git_status_tree.create_item(root)
		staged_cat.set_text(0, "Staged Changes (%d)" % staged.size())
		staged_cat.set_custom_color(0, Color("#30d158"))
		for f in staged:
			var rel: String = str(f)
			var full_path: String = _workspace_root.path_join(rel)
			var item := _git_status_tree.create_item(staged_cat)
			item.set_text(0, rel)
			item.set_text(1, "A")
			item.set_custom_color(1, Color("#30d158"))
			var tex: Texture2D = FileKind.texture_for_path(full_path, false, false)
			if tex:
				item.set_icon(0, tex)
				item.set_icon_max_width(0, 16)
			item.set_metadata(0, {"path": full_path, "rel_path": rel, "type": "staged"})

	var unstaged: Array = st.get("unstaged", [])
	if not unstaged.is_empty():
		var unstaged_cat := _git_status_tree.create_item(root)
		unstaged_cat.set_text(0, "Changes (%d)" % unstaged.size())
		unstaged_cat.set_custom_color(0, Color("#ffa348"))
		for f in unstaged:
			var rel: String = str(f)
			var full_path: String = _workspace_root.path_join(rel)
			var item := _git_status_tree.create_item(unstaged_cat)
			item.set_text(0, rel)
			item.set_text(1, "M")
			item.set_custom_color(1, Color("#ffa348"))
			var tex: Texture2D = FileKind.texture_for_path(full_path, false, false)
			if tex:
				item.set_icon(0, tex)
				item.set_icon_max_width(0, 16)
			item.set_metadata(0, {"path": full_path, "rel_path": rel, "type": "unstaged"})

	var untracked: Array = st.get("untracked", [])
	if not untracked.is_empty():
		var untracked_cat := _git_status_tree.create_item(root)
		untracked_cat.set_text(0, "Untracked Files (%d)" % untracked.size())
		untracked_cat.set_custom_color(0, Color("#8e8e93"))
		for f in untracked:
			var rel: String = str(f)
			var full_path: String = _workspace_root.path_join(rel)
			var item := _git_status_tree.create_item(untracked_cat)
			item.set_text(0, rel)
			item.set_text(1, "U")
			item.set_custom_color(1, Color("#8e8e93"))
			var tex: Texture2D = FileKind.texture_for_path(full_path, false, false)
			if tex:
				item.set_icon(0, tex)
				item.set_icon_max_width(0, 16)
			item.set_metadata(0, {"path": full_path, "rel_path": rel, "type": "untracked"})

	if is_clean:
		var clean_item := _git_status_tree.create_item(root)
		clean_item.set_text(0, "Working tree clean")
		clean_item.set_custom_color(0, Color("#8e8e93"))


func _do_workspace_search(query: String) -> void:
	if _search_results_tree == null:
		return
	_search_results_tree.clear()
	var root := _search_results_tree.create_item()
	var q := query.strip_edges()
	if q.is_empty():
		if _search_summary_label:
			_search_summary_label.text = "0 results"
		return

	var match_case: bool = _search_match_case_btn.button_pressed if _search_match_case_btn else false
	var whole_word: bool = _search_whole_word_btn.button_pressed if _search_whole_word_btn else false
	var inc_pattern: String = _search_include_input.text.strip_edges() if _search_include_input else ""
	var exc_pattern: String = _search_exclude_input.text.strip_edges() if _search_exclude_input else ""

	var results: Dictionary = _search_workspace_files(_workspace_root, q, match_case, whole_word, inc_pattern, exc_pattern)
	var total_matches: int = 0
	var total_files: int = results.size()

	for rel_path: String in results.keys():
		var file_matches: Array = results[rel_path]
		total_matches += file_matches.size()
		var full_p: String = _workspace_root.path_join(rel_path)

		var file_item := _search_results_tree.create_item(root)
		file_item.set_text(0, "%s (%d)" % [rel_path, file_matches.size()])
		var icon_tex: Texture2D = FileKind.texture_for_path(full_p, false, false)
		if icon_tex:
			file_item.set_icon(0, icon_tex)
			file_item.set_icon_max_width(0, 16)

		for match_info: Dictionary in file_matches:
			var line_num: int = int(match_info.get("line", 1))
			var col_num: int = int(match_info.get("col", 0))
			var snippet: String = str(match_info.get("snippet", ""))

			var item := _search_results_tree.create_item(file_item)
			item.set_text(0, "%d: %s" % [line_num, snippet])
			item.set_metadata(0, {
				"path": full_p,
				"line": line_num,
				"col": col_num,
				"length": q.length()
			})

	if _search_summary_label:
		_search_summary_label.text = "%d results in %d files" % [total_matches, total_files]


func _search_workspace_files(base_dir: String, query: String, match_case: bool, whole_word: bool, inc_glob: String, exc_glob: String) -> Dictionary:
	var results: Dictionary = {}
	var files_to_scan: Array[String] = []
	_collect_search_files_recursive(base_dir, base_dir, files_to_scan, inc_glob, exc_glob)

	for full_p: String in files_to_scan:
		var f := FileAccess.open(full_p, FileAccess.READ)
		if not f:
			continue
		var content: String = f.get_as_text()
		f.close()

		var lines: PackedStringArray = content.split("\n")
		var file_matches: Array = []

		for l_idx in range(lines.size()):
			var line_text: String = lines[l_idx]
			var idx: int = 0
			var search_line: String = line_text if match_case else line_text.to_lower()
			var search_q: String = query if match_case else query.to_lower()

			while idx < search_line.length():
				var pos: int = search_line.find(search_q, idx)
				if pos == -1:
					break

				var is_word: bool = true
				if whole_word:
					if pos > 0 and _is_ident_char(search_line[pos - 1]):
						is_word = false
					var end_pos: int = pos + search_q.length()
					if end_pos < search_line.length() and _is_ident_char(search_line[end_pos]):
						is_word = false

				if is_word:
					file_matches.append({
						"line": l_idx + 1,
						"col": pos,
						"snippet": line_text.strip_edges()
					})

				idx = pos + max(1, search_q.length())

		if not file_matches.is_empty():
			var rel: String = full_p.trim_prefix(base_dir).lstrip("/")
			results[rel] = file_matches

	return results


func _collect_search_files_recursive(base_dir: String, current_dir: String, out_files: Array[String], inc_glob: String, exc_glob: String) -> void:
	var dir := DirAccess.open(current_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname not in [".", "..", ".git", ".godot", ".gemini", ".import", "android"]:
			var full_path: String = current_dir.path_join(fname)
			if dir.current_is_dir():
				_collect_search_files_recursive(base_dir, full_path, out_files, inc_glob, exc_glob)
			else:
				var ext: String = fname.get_extension().to_lower()
				if ext not in ["png", "jpg", "jpeg", "webp", "res", "scn", "uid", "bin", "exe", "zip", "import"]:
					var rel: String = full_path.trim_prefix(base_dir).lstrip("/")
					var include_ok: bool = inc_glob.is_empty() or rel.match("*" + inc_glob + "*") or fname.match("*" + inc_glob + "*")
					var exclude_ok: bool = exc_glob.is_empty() or not (rel.match("*" + exc_glob + "*") or fname.match("*" + exc_glob + "*"))
					if include_ok and exclude_ok:
						out_files.append(full_path)
		fname = dir.get_next()
	dir.list_dir_end()


func _is_ident_char(c: String) -> bool:
	return c.is_subsequence_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")


func _on_search_result_activated() -> void:
	if _search_results_tree == null:
		return
	var item: TreeItem = _search_results_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.has("path"):
		var full_p: String = str(meta.get("path", ""))
		var line_num: int = int(meta.get("line", 1)) - 1
		var col_num: int = int(meta.get("col", 0))
		var q_len: int = int(meta.get("length", 0))

		_open_path(full_p)
		if _code_edit:
			_code_edit.set_caret_line(line_num)
			_code_edit.set_caret_column(col_num)
			if q_len > 0:
				_code_edit.select(line_num, col_num, line_num, col_num + q_len)
			_code_edit.center_viewport_to_caret()


func _replace_in_workspace(search_q: String, replace_q: String) -> void:
	var q: String = search_q.strip_edges()
	if q.is_empty():
		return
	var match_case: bool = _search_match_case_btn.button_pressed if _search_match_case_btn else false
	var whole_word: bool = _search_whole_word_btn.button_pressed if _search_whole_word_btn else false
	var inc_pattern: String = _search_include_input.text.strip_edges() if _search_include_input else ""
	var exc_pattern: String = _search_exclude_input.text.strip_edges() if _search_exclude_input else ""

	var results: Dictionary = _search_workspace_files(_workspace_root, q, match_case, whole_word, inc_pattern, exc_pattern)
	var replaced_files: int = 0
	var total_replaced: int = 0

	for rel_path: String in results.keys():
		var full_p: String = _workspace_root.path_join(rel_path)
		var f := FileAccess.open(full_p, FileAccess.READ)
		if not f:
			continue
		var content: String = f.get_as_text()
		f.close()

		var new_content: String = content.replace(q, replace_q)
		if new_content != content:
			var wf := FileAccess.open(full_p, FileAccess.WRITE)
			if wf:
				wf.store_string(new_content)
				wf.close()
				replaced_files += 1
				total_replaced += results[rel_path].size()

			for tab_idx in range(_open_files.size()):
				var info: Dictionary = _open_files[tab_idx]
				if str(info.get("path", "")) == full_p:
					info["content"] = new_content
					if _active_index == tab_idx and _code_edit:
						_code_edit.text = new_content

	_send_os_notification("Workspace Replace", "Replaced %d occurrences across %d files." % [total_replaced, replaced_files])
	_do_workspace_search(q)


func _refresh_themes_panel() -> void:
	if _themes_list == null:
		return
	_themes_list.clear()
	var custom_keys: Array[String] = []
	for raw_key in _custom_themes.keys():
		var key := str(raw_key)
		if not ThemeColorScheme.is_builtin_mode(key):
			custom_keys.append(key)
	custom_keys.sort()
	for key in custom_keys:
		var info: Dictionary = _custom_themes.get(key, {})
		var label: String = str(info.get("label", key))
		var idx := _themes_list.add_item(label + " (XML)")
		_themes_list.set_item_metadata(idx, key)
		if key == _active_theme:
			_themes_list.select(idx)
	if custom_keys.is_empty():
		_themes_list.add_item("No custom XML themes imported")
		_themes_list.set_item_disabled(0, true)

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
	_setup_composer_dropdowns()
	_clear_chat_btn = get_node_or_null("%ClearChatBtn") as Button
	if _clear_chat_btn:
		_clear_chat_btn.pressed.connect(_on_clear_chat_pressed)
		_clear_chat_btn.icon = _load_svg_icon("res://icons/clear.svg")
		_clear_chat_btn.text = ""
	_compact_chat_btn = get_node_or_null("%CompactChatBtn") as Button
	if _compact_chat_btn:
		_compact_chat_btn.pressed.connect(_on_compact_chat_pressed)
		_compact_chat_btn.icon = _load_svg_icon("res://icons/compact.svg")
		_compact_chat_btn.text = ""
	if _smart_commit_btn:
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
	if _chat_history.is_empty():
		_show_chat_welcome()
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
	_ai_chat_http.timeout = 60.0
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
	if _explorer_rail_btn:
		_explorer_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.EXPLORER))
	if _edit_rail_btn:
		_edit_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.SEARCH))
	if _git_rail_btn:
		_git_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.GIT))
	if _themes_rail_btn:
		_themes_rail_btn.visible = true
		_themes_rail_btn.tooltip_text = "Themes & Import XML"
		_themes_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.THEMES))
	if _chat_rail_btn:
		_chat_rail_btn.pressed.connect(_toggle_chat)
	if _config_rail_btn:
		_config_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.CONFIG))
	if _help_rail_btn:
		_help_rail_btn.pressed.connect(func() -> void: _select_sidebar_tab(SidebarTab.HELP))
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
	var is_light := _theme_is_light(_active_theme)
	_theme_toggle_btn.icon = preload("res://icons/nav_moon.svg") if is_light else preload("res://icons/nav_sun.svg")
	_theme_toggle_btn.text = ""
	_theme_toggle_btn.tooltip_text = "Switch to Dark Mode" if is_light else "Switch to Light Mode"


func _theme_is_light(theme_name: String) -> bool:
	return ThemeColorScheme.is_light(theme_name, _all_themes().get(theme_name, {}))


func _toggle_light_dark_theme() -> void:
	var target := ThemeColorScheme.MODE_DARK if _theme_is_light(_active_theme) else ThemeColorScheme.MODE_LIGHT
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
				_append_git_output("Git Branch", "Switched to branch '%s' successfully." % target_b)
				_show_toast("Switched to branch: " + target_b, false)
			else:
				_append_git_output("Git Branch Error", "Failed to switch branch:\n" + str(res.get("output", "")), true)
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
				_append_git_output("Git Config", "Git user configured: %s <%s>" % [name_part, email_part])
				_show_toast("Git user configured.", false)
			else:
				_append_git_output("Git Config Error", "Failed to configure Git user.", true)
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
			_set_git_panel_busy(true)
			var res: Dictionary = GitService.clone_repository(url, target_dir)
			if bool(res.get("success", false)):
				_append_git_output("Git Clone", "Repository cloned to %s" % target_dir)
				_refresh_file_tree()
				_update_git_status_bar()
			else:
				_append_git_output("Git Clone Error", "Failed to clone repository:\n" + str(res.get("output", "")), true)
				_show_toast("Git clone failed.", true)
			_set_git_panel_busy(false)
	)


func _git_push(remote: String = "origin", branch: String = "") -> void:
	_set_git_panel_busy(true)
	_show_toast("Pushing commits to GitHub…", false)
	var res: Dictionary = GitService.push(remote, branch, true, _workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Everything up-to-date."
		_append_git_output("Push to GitHub Succeeded", out_txt)
		_show_toast("Push to GitHub completed successfully!", false)
	else:
		_append_git_output("Git Push Error", str(res.get("output", "")), true)
		_show_toast("Git push failed.", true)
	_set_git_panel_busy(false)
	_update_git_status_bar()


func _git_pull(remote: String = "origin", branch: String = "") -> void:
	_set_git_panel_busy(true)
	_show_toast("Pulling changes from GitHub…", false)
	var res: Dictionary = GitService.pull(remote, branch, false, _workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Already up to date."
		_append_git_output("Pull from GitHub Succeeded", out_txt)
		_show_toast("Pull from GitHub completed!", false)
		_refresh_file_tree()
	else:
		_append_git_output("Git Pull Error", str(res.get("output", "")), true)
		_show_toast("Git pull failed.", true)
	_set_git_panel_busy(false)
	_update_git_status_bar()


func _git_fetch(remote: String = "origin") -> void:
	_set_git_panel_busy(true)
	_show_toast("Fetching from %s…" % remote, false)
	var res: Dictionary = GitService.fetch(remote, _workspace_root)
	if bool(res.get("success", false)):
		_append_git_output("Git Fetch", "Fetch completed successfully from " + remote)
		_show_toast("Fetch completed.", false)
	else:
		_append_git_output("Git Fetch Error", str(res.get("output", "")), true)
	_set_git_panel_busy(false)
	_update_git_status_bar()


func _git_sync(remote: String = "origin", branch: String = "") -> void:
	_set_git_panel_busy(true)
	_show_toast("Synchronising with GitHub (Pull & Push)…", false)
	var res: Dictionary = GitService.sync(remote, branch, _workspace_root)
	if bool(res.get("success", false)):
		_append_git_output("GitHub Sync Succeeded", str(res.get("output", "")))
		_show_toast("GitHub synchronisation completed!", false)
		_refresh_file_tree()
	else:
		_append_git_output("GitHub Sync Error (%s)" % str(res.get("stage", "sync")), str(res.get("error", "")), true)
		_show_toast("Sync failed.", true)
	_set_git_panel_busy(false)
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


func _setup_composer_dropdowns() -> void:
	if _agent_mode_btn:
		var agent_popup := _agent_mode_btn.get_popup()
		agent_popup.clear()
		agent_popup.add_radio_check_item("Build (Agent Autopilot)", 0)
		agent_popup.add_radio_check_item("Chat (Standard Chat)", 1)
		agent_popup.set_item_checked(0, _agent_mode)
		agent_popup.set_item_checked(1, not _agent_mode)
		if not agent_popup.id_pressed.is_connected(_on_agent_mode_popup_selected):
			agent_popup.id_pressed.connect(_on_agent_mode_popup_selected)
		_agent_mode_btn.text = "Build ⌵" if _agent_mode else "Chat ⌵"

	if _model_badge_btn:
		_model_badge_btn.icon = preload("res://icons/sparkles.svg")
		_model_badge_btn.expand_icon = true
		var model_popup := _model_badge_btn.get_popup()
		model_popup.clear()
		model_popup.add_radio_check_item("Opus-4.5 (Default)", 0)
		model_popup.add_radio_check_item("Nemotron 3.5 Lightning", 1)
		model_popup.add_radio_check_item("Kimi K3", 2)
		model_popup.add_radio_check_item("DeepSeek V4", 3)
		model_popup.add_radio_check_item("Laguna Code", 4)
		if not model_popup.id_pressed.is_connected(_on_model_badge_popup_selected):
			model_popup.id_pressed.connect(_on_model_badge_popup_selected)
		_update_model_badge_text()


func _on_agent_mode_popup_selected(id: int) -> void:
	_agent_mode = (id == 0)
	if _agent_mode_btn:
		_agent_mode_btn.text = "Build ⌵" if _agent_mode else "Chat ⌵"
		var agent_popup := _agent_mode_btn.get_popup()
		agent_popup.set_item_checked(0, _agent_mode)
		agent_popup.set_item_checked(1, not _agent_mode)
	if _agent_mode:
		_show_toast("Switched to Build (Agent Autopilot) mode", false)
	else:
		_show_toast("Switched to Chat mode", false)


func _on_model_badge_popup_selected(id: int) -> void:
	_on_provider_selected(id)


func _update_model_badge_text() -> void:
	var titles := {
		"nemotron": "Opus-4.5",
		"nemotron_lightning": "Nemotron 3.5",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_ai_provider, "Opus-4.5")
	if _model_badge_btn:
		_model_badge_btn.text = display_title + " ⌵"
		var model_popup := _model_badge_btn.get_popup()
		var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
		for i in range(names.size()):
			model_popup.set_item_checked(i, names[i] == _ai_provider)


func _on_provider_selected(index: int) -> void:
	if _ai_busy:
		_cancel_ai_request()
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	if index >= 0 and index < names.size():
		_ai_provider = names[index]
	_save_ai_config()
	_update_ai_status()
	_update_model_badge_text()


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
	var merged := ThemeColorScheme.MODE_THEMES.duplicate()
	for key in _custom_themes:
		if ThemeColorScheme.is_builtin_mode(str(key)):
			continue
		merged[key] = _custom_themes[key]
	return merged


func _resolve_theme_name(_name: String) -> String:
	if _custom_themes.has(_name) and not ThemeColorScheme.is_builtin_mode(_name):
		return _name
	if ThemeColorScheme.is_builtin_mode(_name):
		return _name
	return ThemeColorScheme.canonical_mode(_name)


func _load_theme_config() -> void:
	_load_custom_themes()
	var cfg := ConfigFile.new()
	if cfg.load("user://ui_config.cfg") == OK:
		_active_theme = str(cfg.get_value("theme", "name", ThemeColorScheme.MODE_DARK))
	_active_theme = _resolve_theme_name(_active_theme)
	if not _all_themes().has(_active_theme) or ThemeResources.load_theme(_active_theme) == null:
		_active_theme = ThemeColorScheme.MODE_DARK


func _save_theme_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ui_config.cfg")
	cfg.set_value("theme", "name", _active_theme)
	cfg.save("user://ui_config.cfg")


func _apply_theme_by_name(_name: String) -> void:
	var resolved := _resolve_theme_name(_name)
	if resolved == _active_theme:
		return
	var previous_theme := _active_theme
	_active_theme = resolved
	if not _apply_kitty_fish_theme():
		_active_theme = previous_theme
		_append_chat("IDE", "[color=#ed333b]Theme not found:[/color] " + resolved, Color("#ed333b"))
		_show_toast("Theme not found: " + resolved, true)
		return
	_save_theme_config()
	var label: String = str(_all_themes().get(resolved, {}).get("label", resolved))
	_populate_themes_menu()
	_update_app_brand_menu()
	_update_theme_toggle_btn()
	_rebuild_chat_log()
	if _md_preview_active and _active_index >= 0 and _active_index < _open_files.size():
		_set_markdown_preview(true, _code_edit.text)
	_show_toast("Theme: " + label, false)


func _populate_themes_menu() -> void:
	if _themes_menu == null:
		return
	_themes_menu.clear()
	_theme_menu_keys.clear()
	var keys: Array[String] = []
	var custom_keys: Array[String] = []
	for raw_key in _custom_themes.keys():
		var key := str(raw_key)
		if ThemeColorScheme.is_builtin_mode(key):
			continue
		if ThemeResources.load_theme(key) != null:
			custom_keys.append(key)
	custom_keys.sort_custom(func(left: String, right: String) -> bool:
		return str(_all_themes()[left].get("label", left)).naturalnocasecmp_to(str(_all_themes()[right].get("label", right))) < 0
	)
	keys.append_array(custom_keys)
	for key in keys:
		if ThemeResources.load_theme(key) == null:
			continue
		var info: Dictionary = _all_themes().get(key, {})
		var item_index := _themes_menu.item_count
		var label: String = str(info.get("label", key))
		if _custom_themes.has(key):
			label += "  (XML)"
		_themes_menu.add_radio_check_item(label, _theme_menu_keys.size())
		_themes_menu.set_item_checked(item_index, key == _active_theme)
		_themes_menu.set_item_tooltip(item_index, "Currently selected" if key == _active_theme else "Apply " + str(info.get("label", key)))
		_theme_menu_keys.append(key)
	if _theme_menu_keys.is_empty():
		_themes_menu.add_item("No custom XML themes imported")
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
				if ThemeColorScheme.is_builtin_mode(key):
					fname = dir.get_next()
					continue
				_custom_themes[key] = result
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
				var variant := parser.get_named_attribute_value_safe("variant")
				if not variant.is_empty():
					result["variant"] = variant
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
	result["variant"] = ThemeColorScheme.infer_variant(result)
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
	if ThemeColorScheme.is_builtin_mode(key):
		key = key + "_custom"
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
		"nemotron": "Opus-4.5",
		"nemotron_lightning": "Nemotron 3.5",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_ai_provider, "Opus-4.5")
	if AIService.has_nvidia_api_key():
		_status_ai.text = "AI: %s · on" % display_title
	else:
		_status_ai.text = "AI: %s · key needed" % display_title
	if _model_badge_btn:
		_model_badge_btn.text = "✴ " + display_title + " ⌵"
	_chat_input.placeholder_text = "How can i help you today?"


func _show_chat_welcome() -> void:
	_chat_log.clear()
	var welcome := "\n\n\n\n\n[center][font_size=28][color=#e2996d]✴[/color] [b]Let's Talk[/b][/font_size]\n[color=#7a7e85][font_size=13]Ask any question or start coding with AI[/font_size][/color][/center]\n"
	_chat_log.append_text(welcome)


func _on_clear_chat_pressed() -> void:
	_chat_history.clear()
	_show_chat_welcome()
	_send_os_notification("Chat", "Chat history cleared.")


func _on_compact_chat_pressed() -> void:
	_compact_chat_history()


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
		selected = ThemeResources.load_theme(ThemeColorScheme.MODE_DARK)
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
		if _chat_context_badge:
			_chat_context_badge.text = "Local · Autopilot"
	else:
		_agent_mode_btn.text = "Chat"
		if _chat_context_badge:
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
	var is_light := ThemeColorScheme.is_light(_active_theme)
	return MarkdownPreview.render(markdown, is_light)


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
	return _all_themes().get(_active_theme, ThemeColorScheme.MODE_THEMES[ThemeColorScheme.MODE_DARK])


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


func _populate_tree_dir(parent_item: TreeItem, dir_path: String, max_depth: int = 1, current_depth: int = 0) -> void:
	if parent_item == null or _file_tree == null:
		return
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
		if item == null:
			continue
		item.set_text(0, d)
		var item_path: String = dir_path.path_join(d)
		var folder_tex: Texture2D = FileKind.texture_for_path(item_path, true, false)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, Color("#8ec4f7"))
		item.collapsed = true
		if current_depth < max_depth:
			item.set_metadata(0, {"path": item_path, "is_dir": true, "loaded": true})
			_populate_tree_dir(item, item_path, max_depth, current_depth + 1)
		else:
			item.set_metadata(0, {"path": item_path, "is_dir": true, "loaded": false})
			var sub_dir := DirAccess.open(item_path)
			if sub_dir:
				sub_dir.list_dir_begin()
				var sub_fname := sub_dir.get_next()
				var has_sub_content := false
				while sub_fname != "":
					if sub_fname not in [".", "..", ".git", ".godot", ".gemini", "android"]:
						has_sub_content = true
						break
					sub_fname = sub_dir.get_next()
				sub_dir.list_dir_end()
				if has_sub_content:
					var dummy: TreeItem = _file_tree.create_item(item)
					if dummy != null:
						dummy.set_text(0, "Loading…")
	for f: String in files:
		var item: TreeItem = _file_tree.create_item(parent_item)
		if item == null:
			continue
		item.set_text(0, f)
		var item_path: String = dir_path.path_join(f)
		var file_tex: Texture2D = FileKind.texture_for_path(item_path, false, false)
		if file_tex:
			item.set_icon(0, file_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, FileKind.color_for_path(f))
		item.set_metadata(0, {"path": item_path, "is_dir": false})


func _on_tree_item_collapsed(item: TreeItem) -> void:
	if not item or is_queued_for_deletion():
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		var p: String = str(meta.get("path", ""))
		var folder_tex: Texture2D = FileKind.texture_for_path(p, true, not item.collapsed)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)
		if not item.collapsed and not meta.get("loaded", false):
			call_deferred("_deferred_load_tree_dir", item, p)


func _deferred_load_tree_dir(item: TreeItem, p: String) -> void:
	if not is_instance_valid(item) or is_queued_for_deletion():
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary:
		meta["loaded"] = true
	var child: TreeItem = item.get_first_child()
	while child != null:
		var next: TreeItem = child.get_next()
		item.remove_child(child)
		child.free()
		child = next
	_populate_tree_dir(item, p, 1, 0)


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
		var root_name: String = _workspace_root.get_file() if not _workspace_root.is_empty() else "My Project"
		if root_name.is_empty():
			root_name = "My Project"
		var rel: String = path.replace(_workspace_root, "").trim_prefix("/")
		_status_left.text = root_name + " > " + rel.replace("/", " > ")
	else:
		_chat_context_chip.text = "+ Untitled"
		_status_left.text = "My Project > Untitled"
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
	_status_cursor.text = "Ln %d, Col %d   < Code Navigation Help" % [line, col]


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
		"/search", "/web":
			var q: String = parts[1].strip_edges() if parts.size() > 1 else ""
			if q.is_empty():
				_append_chat("WEB", "[color=#ffa348]Uso:[/color] /search <termo de pesquisa> ou /web <termo>", Color("#ffa348"))
			else:
				_show_toast("A pesquisar na Internet em tempo real: " + q, false)
				var res := WebSearchService.search_web(q, 5)
				_append_chat("WEB", WebSearchService.format_search_results_bbcode(q, res), Color("#57e389"))
				var web_context := WebSearchService.format_search_context_for_prompt(q, res)
				if not web_context.is_empty():
					_chat_history.append({"role": "system", "content": web_context})
					_ensure_api_key(func() -> void: _ask_ai("Sintetiza de forma clara e actualizada os resultados da pesquisa sobre: " + q))
		"/git":
			var subcmd_raw: String = parts[1].strip_edges() if parts.size() > 1 else "status"
			var sub_parts: PackedStringArray = subcmd_raw.split(" ", false, 1)
			var subcmd: String = sub_parts[0].to_lower() if not sub_parts.is_empty() else "status"
			var sub_arg: String = sub_parts[1].strip_edges() if sub_parts.size() > 1 else ""
			
			match subcmd:
				"status":
					var st: Dictionary = GitService.get_status(_workspace_root)
					var gh: Dictionary = GitService.get_github_info(_workspace_root)
					_append_git_output("Git Status", GitService.format_status_bbcode(st, gh))
					_update_git_status_bar()
				"diff":
					var res: Dictionary = GitService.get_diff(sub_arg, false, _workspace_root)
					_append_git_output("Git Diff", GitService.format_diff_bbcode(str(res.get("output", ""))))
				"log":
					var count: int = sub_arg.to_int() if sub_arg.to_int() > 0 else 10
					var log_entries: Array[Dictionary] = GitService.get_log(count, _workspace_root)
					_append_git_output("Git Log", GitService.format_log_bbcode(log_entries))
				"commit":
					if sub_arg.is_empty():
						_generate_smart_commit()
					else:
						_set_git_panel_busy(true)
						GitService.stage_all(_workspace_root)
						var commit_res: Dictionary = GitService.commit(sub_arg, _workspace_root)
						if bool(commit_res.get("success", false)):
							_append_git_output("Git Commit", "Commit created successfully:\n" + sub_arg)
							_show_toast("Git commit: " + sub_arg, false)
						else:
							_append_git_output("Git Commit Error", str(commit_res.get("output", "")), true)
						_set_git_panel_busy(false)
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
						_append_git_output("Git Branches", b_out)
					else:
						_set_git_panel_busy(true)
						var create_res: Dictionary = GitService.create_branch(sub_arg, _workspace_root)
						if bool(create_res.get("success", false)):
							_append_git_output("Git Branch", "Branch '%s' created successfully." % sub_arg)
						else:
							_append_git_output("Git Branch Error", str(create_res.get("output", "")), true)
						_set_git_panel_busy(false)
						_update_git_status_bar()
				"checkout", "switch":
					if sub_arg.is_empty():
						_prompt_git_branch()
					else:
						_set_git_panel_busy(true)
						var create_new := sub_arg.begins_with("-b ") or sub_arg.begins_with("+")
						var branch_target := sub_arg.trim_prefix("-b ").trim_prefix("+").strip_edges()
						var co_res: Dictionary = GitService.checkout_branch(branch_target, create_new, _workspace_root)
						if bool(co_res.get("success", false)):
							_append_git_output("Git Branch", "Switched to branch '%s' successfully." % branch_target)
							_show_toast("Branch: " + branch_target, false)
						else:
							_append_git_output("Git Branch Error", str(co_res.get("output", "")), true)
						_set_git_panel_busy(false)
						_update_git_status_bar()
				"remote":
					var remotes: Array[Dictionary] = GitService.get_remotes(_workspace_root)
					var gh: Dictionary = GitService.get_github_info(_workspace_root)
					var r_out := "[b][color=#62a0ea]Git Remotes & GitHub:[/color][/b]\n\n"
					for r in remotes:
						r_out += "• [b]%s[/b] (%s): `%s`\n" % [str(r.get("name", "")), str(r.get("type", "")), str(r.get("url", ""))]
					if bool(gh.get("is_github", false)):
						r_out += "\n[color=#57e389]GitHub Repo:[/color] %s\n" % str(gh.get("web_url", ""))
					_append_git_output("Git Remotes", r_out)
				"config":
					if sub_arg.is_empty():
						var u: Dictionary = GitService.get_user_config(_workspace_root)
						_append_git_output("Git Config", "Git User: `%s <%s>`" % [str(u.get("name", "")), str(u.get("email", ""))])
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
							_append_git_output("Git Config", "Git user configured: %s <%s>" % [name_val, email_val])
						else:
							_append_git_output("Git Config Error", "Failed to configure Git user.", true)
				"clone":
					if sub_arg.is_empty():
						_prompt_git_clone()
					else:
						_set_git_panel_busy(true)
						var target_dir: String = _workspace_root.path_join(sub_arg.get_file().trim_suffix(".git"))
						_show_toast("Cloning repository…", false)
						var cl_res: Dictionary = GitService.clone_repository(sub_arg, target_dir)
						if bool(cl_res.get("success", false)):
							_append_git_output("Git Clone", "Repository cloned to %s" % target_dir)
							_refresh_file_tree()
						else:
							_append_git_output("Git Clone Error", str(cl_res.get("output", "")), true)
						_set_git_panel_busy(false)
				_:
					_set_git_panel_busy(true)
					var res: Dictionary = _execute_git_command(subcmd_raw.split(" ", false))
					var out_txt: String = str(res.get("output", "")).strip_edges()
					if out_txt.is_empty():
						out_txt = "Git command executed."
					_append_git_output("Git Command Output", out_txt, int(res.get("exit_code", 0)) != 0)
					_set_git_panel_busy(false)
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
	var desc := "[b][color=#57E389]Assistente SSBot — Capacidades do IDE[/color][/b]\n\n"
	desc += "• [b]Análise e Leitura de Código:[/b] Acesso ao workspace, estrutura de ficheiros e contexto do projecto.\n"
	desc += "• [b]Edição Autónoma de Ficheiros:[/b] Criação, modificação e refatoração de código com verificação de sintaxe.\n"
	desc += "• [b]Pesquisa na Internet (Tempo Real):[/b] Consulta de documentação actualizada e resultados da Web via `/web` ou `/search`.\n"
	desc += "• [b]Integração com Git & GitHub:[/b] Controlo de versões no painel Source Control com mensagens de commit inteligentes (Smart Commit).\n"
	desc += "\n[color=#8E8E93]Usa `/web <pesquisa>` para pesquisar na Web ou usa o chat para pedir alterações no teu projecto.[/color]"
	_append_chat("SSBot", desc, Color("#57E389"))


func _execute_git_command(args: PackedStringArray) -> Dictionary:
	return GitService.execute(args, _workspace_root)


func _is_smart_commit_pending() -> bool:
	return not _smart_commit_prompt.is_empty() or _current_prompt.begins_with("__SMART_COMMIT__:")


func _finish_smart_commit(commit_msg: String, _via_ai: bool, _note: String = "") -> void:
	_current_prompt = ""
	_smart_commit_prompt = ""
	_clear_ai_busy()
	if _git_progress_panel:
		_git_progress_panel.visible = false
	if _git_progress_bar:
		_git_progress_bar.value = 0.0
	var message: String = commit_msg.strip_edges()
	if message.is_empty():
		message = GitService.build_fallback_commit_message(_workspace_root)
	if _git_commit_msg_input:
		_git_commit_msg_input.text = message
	var headline: String = message.split("\n")[0]
	_send_os_notification("Smart Commit", "AI generated commit message:\n" + headline)
	_refresh_git_panel()


func _fallback_smart_commit(reason: String) -> void:
	var local_msg: String = GitService.build_fallback_commit_message(_workspace_root)
	_finish_smart_commit(local_msg, false, reason + " Using local message.")


func _generate_smart_commit() -> void:
	if not GitService.is_git_repository(_workspace_root):
		_send_os_notification("Git Error", "Not a Git repository.", true)
		return
	_continue_smart_commit()


func _continue_smart_commit() -> void:
	var st: Dictionary = GitService.get_status(_workspace_root)
	var staged: Array   = st.get("staged",    [])
	var unstaged: Array = st.get("unstaged",  [])
	var untracked: Array= st.get("untracked", [])
	if staged.is_empty() and unstaged.is_empty() and untracked.is_empty():
		_send_os_notification("Git", "Nothing to commit.", false)
		return

	var stage_res: Dictionary = GitService.stage_all(_workspace_root)
	if not bool(stage_res.get("success", false)):
		_send_os_notification("Git Error", "Failed to stage changes.", true)
		return

	var diff_stat_res: Dictionary = GitService.get_diff_stat(_workspace_root)
	var diff_stat: String = str(diff_stat_res.get("output", "")).strip_edges()

	var diff_res: Dictionary = GitService.get_diff("", true, _workspace_root)
	var diff_text: String = str(diff_res.get("output", "")).strip_edges()
	if diff_text.length() > 3000:
		diff_text = diff_text.substr(0, 3000) + "\n... [diff truncated]"

	if diff_text.is_empty():
		diff_text = diff_stat

	if not AIService.has_nvidia_api_key():
		_finish_smart_commit(GitService.build_fallback_commit_message(_workspace_root), false, "No NVIDIA NIM key.")
		return

	if _git_progress_panel:
		_git_progress_panel.visible = true
	if _git_progress_label:
		_git_progress_label.text = "⚡ A gerar mensagem de commit com IA..."
	if _git_progress_bar:
		_git_progress_bar.value = 10.0

	var commit_prompt := (
		"You are an expert software engineer. Analyse the following `git diff --cached` output " +
		"and produce ONE concise Git commit message following the Conventional Commits specification " +
		"(https://www.conventionalcommits.org).\n\n" +
		"Rules:\n" +
		"- Use one of: feat, fix, docs, style, refactor, perf, test, chore, build, ci\n" +
		"- First line: type(scope): short summary in imperative mood, max 72 chars\n" +
		"- Output ONLY the commit message — no explanation, no markdown fences\n\n" +
		"Git diff:\n```\n" + diff_text + "\n```"
	)

	_ai_smart_commit_request(commit_prompt, diff_stat)


func _ai_smart_commit_request(prompt: String, diff_stat: String) -> void:
	if _ai_busy:
		_finish_smart_commit(GitService.build_fallback_commit_message(_workspace_root), false, "AI is busy.")
		return

	_ai_busy = true
	_request_start_time = Time.get_ticks_msec() / 1000.0
	_spinner_time = 0.0
	if _git_progress_panel:
		_git_progress_panel.visible = true
	if _git_progress_label:
		_git_progress_label.text = "⚡ A analisar alterações do Git..."
	if _git_progress_bar:
		_git_progress_bar.value = 20.0
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

	# Auto-fetch live internet search context if requested
	var lower := prompt.to_lower()
	var needs_web := (
		lower.contains("pesquisa") or lower.contains("busca") or lower.contains("internet")
		or lower.contains("web") or lower.contains("notícia") or lower.contains("noticia")
		or lower.contains("última") or lower.contains("recente") or lower.contains("novidade")
		or lower.contains("versão actual") or lower.contains("versao actual") or lower.contains("online")
	)
	if needs_web:
		var search_q := prompt.replace("pesquisa na web", "").replace("pesquisa na internet", "").replace("busca na internet", "").replace("procura na internet", "").strip_edges()
		if search_q.length() > 2:
			var web_res := WebSearchService.search_web(search_q, 4)
			if not web_res.is_empty():
				var web_context := WebSearchService.format_search_context_for_prompt(search_q, web_res)
				_chat_history.append({"role": "system", "content": web_context})

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
		var current_datetime: String = Time.get_datetime_string_from_system(false, true)
		var current_year: String = str(Time.get_date_dict_from_system().get("year", 2026))
		var workspace_info: String = _get_workspace_context()
		var system_role_content: String = ""
		if _agent_mode:
			system_role_content = (
				"You are SSBot, an elite autonomous AI programming partner and agent integrated directly into SSCodeIDE created by Ser Superior (SS).\n" +
				"You have direct access and visibility to the project workspace files, directory tree, active file, and real-time Internet search capabilities.\n\n" +
				"=== CONTEXTO TEMPORAL & ACESSO À INTERNET (TEMPO REAL) ===\n" +
				"Data e Hora Actual: " + current_datetime + " (Ano: " + current_year + ")\n" +
				"Ambiente: SSCodeIDE sobre Godot Engine nativo em GDScript.\n" +
				"Tens acesso total a informações actualizadas em tempo real da Internet através do WebSearchService do SSCodeIDE. Responde sempre com conhecimento moderno, rigoroso e actualizado.\n\n" +
				"=== WORKSPACE CONTEXT ===\n" +
				workspace_info + "\n" +
				"=========================\n\n" +
				"=== REGRAS CRÍTICAS DE COMUNICAÇÃO, TRATAMENTO E LINGUAGEM ===\n" +
				"1. VARIEDADE LINGUÍSTICA E NORMA CULTA (PORTUGUÊS DE ANGOLA - pt-AO):\n" +
				"   - DEVES SEMPRE comunicar e responder em Português de Angola (pt-AO), aderindo estritamente à norma culta.\n" +
				"   - Aplica com rigor absoluto as regras ortográficas anteriores ao acordo de 2012, preservando as consoantes mudas em palavras como 'acção', 'directo', 'projecto', 'objecto', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico', 'consecutivamente', 'exacto', 'redacção', 'arquitectura'.\n" +
				"2. TRATAMENTO SEGUNDO O PRONOME PESSOAL 'TU' (RIGOR GRAMATICAL):\n" +
				"   - Trata SEMPRE o utilizador pela segunda pessoa do singular ('tu').\n" +
				"   - Usa obrigatoriamente a regência pronominal e as formas corretas em Português: usa 'contigo' (NUNCA digas 'com tu'), 'teu/tua/teus/tuas', 'te' (e.g. 'estou contigo', 'como estás?', 'o que precisas para o teu projecto?').\n" +
				"   - NUNCA uses construções brasileiras como 'você' ou 'com tu'.\n" +
				"3. PROIBIÇÃO ABSOLUTA DE EMOJIS E GÍRIAS:\n" +
				"   - NUNCA uses emojis ou bonecos gráficos nas tuas respostas. Mantém um tom altamente culto, sóbrio, cortês, elegante e profissional.\n" +
				"4. CÓDIGO E IDENTIFICADORES TÉCNICOS EM INGLÊS BRITÂNICO (en-GB):\n" +
				"   - Todo o código-fonte, nomes de variáveis, funções, classes, docstrings e comentários técnicos no código DEVEM SEMPRE estar em Inglês Britânico técnico (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"5. PRIVACIDADE E SEGREDOS DE FERRAMENTAS INTERNAS (TOOLS):\n" +
				"   - NUNCA listes, reveles ou exibas as tuas tags de ferramentas internas (como `<sscode-write>`, `<sscode-delete>`), nem esquemas ou especificações internas de ferramentas ao utilizador. Se o utilizador perguntar quais são as tuas ferramentas ou como funcionas, resume apenas as tuas capacidades em linguagem natural amigável.\n" +
				"==============================================================\n\n" +
				"Provide detailed technical guidance, plan development tasks with checklists, review code, execute slash commands, and format responses clearly with Markdown/BBCode.\n" +
				"When you need to create or edit a workspace file, emit one or more blocks exactly as `<sscode-write path=\"relative/path\">file contents</sscode-write>`. Use workspace-relative paths only. The IDE executes these blocks; do not merely describe the change.\n" +
				"To delete a file, emit `<sscode-delete path=\"relative/path\"/>`. Use this only when the user explicitly requests deletion.\n" +
				"Always consider the full workspace context, active file contents, and current real-time data when responding."
			)
		else:
			system_role_content = (
				"You are SSBot, a helpful AI programming partner embedded in SSCodeIDE created by Ser Superior (SS).\n\n" +
				"=== CONTEXTO TEMPORAL & ACESSO À INTERNET (TEMPO REAL) ===\n" +
				"Data e Hora Actual: " + current_datetime + " (Ano: " + current_year + ")\n" +
				"Ambiente: SSCodeIDE sobre Godot Engine nativo em GDScript.\n" +
				"Tens acesso total a informações actualizadas em tempo real da Internet através do WebSearchService do SSCodeIDE.\n\n" +
				"=== REGRAS CRÍTICAS DE COMUNICAÇÃO, TRATAMENTO E LINGUAGEM ===\n" +
				"1. VARIEDADE LINGUÍSTICA E NORMA CULTA (PORTUGUÊS DE ANGOLA - pt-AO):\n" +
				"   - DEVES SEMPRE comunicar e responder em Português de Angola (pt-AO), aderindo estritamente à norma culta.\n" +
				"   - Segue as regras ortográficas anteriores ao acordo de 2012, preservando as consoantes mudas em palavras como 'acção', 'directo', 'projecto', 'objecto', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico', 'consecutivamente', 'exacto', 'redacção'.\n" +
				"2. TRATAMENTO SEGUNDO O PRONOME 'TU' (RIGOR GRAMATICAL):\n" +
				"   - Trata SEMPRE o utilizador por 'tu'. Usa obrigatoriamente 'contigo' (NUNCA digas 'com tu'), 'teu/tua', 'te'.\n" +
				"3. PROIBIÇÃO DE EMOJIS:\n" +
				"   - NUNCA uses emojis nas tuas respostas. Mantém um tom sóbrio, culto e profissional.\n" +
				"4. CÓDIGO E IDENTIFICADORES TÉCNICOS EM INGLÊS BRITÂNICO (en-GB):\n" +
				"   - Todo o código-fonte, nomes de variáveis, funções, docstrings e comentários técnicos DEVEM SEMPRE estar em Inglês Britânico técnico (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"==============================================================\n\n" +
				"Responde de forma clara, prestativa e amigável às questões e tarefas de programação."
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
			"stream": false
		}
		if model_name.begins_with("nvidia/nemotron"):
			payload_dict["chat_template_kwargs"] = {"thinking": true}

	var payload_json := JSON.stringify(payload_dict)
	if not is_smart_commit:
		_thinking_text = ""
		_refresh_thinking_panel()
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


func _rebuild_chat_log() -> void:
	if _chat_log == null:
		return
	_chat_log.clear()
	if _chat_history.is_empty():
		_show_chat_welcome()
		return
	for entry in _chat_history:
		var role: String = str(entry.get("role", "assistant"))
		var content: String = str(entry.get("content", ""))
		if role == "user":
			_append_user_message_to_log(content)
		elif role == "system":
			var sys_col := "#6c6c70" if _theme_is_light(_active_theme) else "#8e8e93"
			_chat_log.append_text("[color=%s]%s[/color]\n\n" % [sys_col, _format_markdown_to_bbcode(content)])
		else:
			_append_ai_response_to_log(content)


func _append_user_message(prompt: String) -> void:
	if _chat_history.is_empty():
		_chat_log.clear()
	_append_user_message_to_log(prompt)


func _append_user_message_to_log(prompt: String) -> void:
	var sanitized: String = prompt.replace("[", "[lb]")
	var is_light := _theme_is_light(_active_theme)
	var bg_col := "#252830" if not is_light else "#e2e4e9"
	var fg_col := "#ffffff" if not is_light else "#111113"
	var user_bubble := "\n[right][bgcolor=%s][color=%s]  %s  [/color][/bgcolor][/right]\n\n" % [bg_col, fg_col, sanitized.replace("\n", "\n  ")]
	_chat_log.append_text(user_bubble)
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _on_chat_meta_clicked(meta: Variant) -> void:
	var value := str(meta)
	if value.begins_with("copy:"):
		DisplayServer.clipboard_set(Marshalls.base64_to_raw(value.trim_prefix("copy:")).get_string_from_utf8())
		_show_toast("Code copied to clipboard.", false)
	elif value == "action_like":
		_show_toast("Feedback received: Liked!", false)
	elif value == "action_dislike":
		_show_toast("Feedback received: Disliked.", false)
	elif value == "action_pin":
		_show_toast("Message pinned to context.", false)
	elif value.begins_with("action_download:"):
		var text := Marshalls.base64_to_raw(value.trim_prefix("action_download:")).get_string_from_utf8()
		DisplayServer.clipboard_set(text)
		_show_toast("Response text copied for export.", false)
	elif value == "action_retry":
		if not _chat_history.is_empty():
			var last_user_prompt := ""
			for entry in _chat_history:
				if entry.get("role") == "user":
					last_user_prompt = str(entry.get("content", ""))
			if not last_user_prompt.is_empty():
				_ask_ai(last_user_prompt)


func _append_ai_response(_provider: String, reply_text: String, _elapsed: float = 0.0, _tokens_in: int = 0, _tokens_out: int = 0) -> void:
	_append_ai_response_to_log(reply_text)


func _append_ai_response_to_log(reply_text: String) -> void:
	var is_light := _theme_is_light(_active_theme)
	var formatted_body := _format_markdown_to_bbcode(reply_text)
	var copy_id := Marshalls.raw_to_base64(reply_text.to_utf8_buffer())
	var action_col := "#6c6c70" if is_light else "#8e8e93"
	var action_bar := "[color=%s][url=copy:%s]📋 Copy[/url]   [url=action_like]👍[/url]   [url=action_dislike]👎[/url]   [url=action_pin]📌 Pin[/url]   [url=action_download:%s]📥 Export[/url]   [url=action_retry]🔄 Regenerate[/url][/color]" % [action_col, copy_id, copy_id]

	_chat_log.append_text("\n%s\n\n%s\n\n" % [formatted_body, action_bar])
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


func _append_chat(who: String, msg_body: String, _color: Color = Color()) -> void:
	var tag := who.to_upper()
	if tag in ["YOU", "USER"]:
		_append_user_message_to_log(msg_body)
	elif tag in ["SYSTEM", "TOOL", "IDE", "WEB"]:
		var sys_col := "#6c6c70" if _theme_is_light(_active_theme) else "#8e8e93"
		_chat_log.append_text("[color=%s]%s[/color]\n\n" % [sys_col, _format_markdown_to_bbcode(msg_body)])
	else:
		_append_ai_response_to_log(msg_body)
	_chat_log.scroll_to_line(_chat_log.get_line_count() - 1)


func _format_markdown_to_bbcode(raw_text: String) -> String:
	var is_light := _theme_is_light(_active_theme)
	return ChatMarkdown.render(raw_text, is_light)


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
