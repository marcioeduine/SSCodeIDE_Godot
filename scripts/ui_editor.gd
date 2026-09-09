extends Control

## SSCodeIDE — root controller. All nodes live in ui_editor.tscn.
## Refactored into modular controller components for maintainability and performance.

const ChatMarkdown = preload("res://scripts/chat_markdown_renderer.gd")
const AgentWorkspace = preload("res://scripts/agent_workspace_service.gd")
const CodeEditorTools = preload("res://scripts/code_editor_service.gd")
const MarkdownPreview = preload("res://scripts/markdown_preview_renderer.gd")
const ThemeResources = preload("res://scripts/theme_resource_registry.gd")

func _find_node(node_name: String) -> Node:
	var n: Node = get_node_or_null("%" + node_name)
	if n != null:
		return n
	return find_child(node_name, true, false)

@onready var _root_vbox: Control = (_find_node("AppHBox") if _find_node("AppHBox") else _find_node("RootVBox")) as Control
@onready var _file_tree: Tree = _find_node("FileTree") as Tree
@onready var _tab_bar: TabBar = _find_node("TabBar") as TabBar
@onready var _code_edit: CodeEdit = _find_node("CodeEdit") as CodeEdit
@onready var _chat_log: RichTextLabel = _find_node("ChatLog") as RichTextLabel
@onready var _chat_context_badge: Label = _find_node("ChatContextBadge") as Label
@onready var _chat_context_chip: Button = _find_node("ChatContextChip") as Button
@onready var _chat_input: LineEdit = _find_node("ChatInput") as LineEdit
@onready var _attach_btn: Button = _find_node("AttachBtn") as Button
@onready var _agent_mode_btn: MenuButton = _find_node("AgentModeBtn") as MenuButton
@onready var _model_badge_btn: MenuButton = _find_node("ModelBadgeBtn") as MenuButton
@onready var _provider_select: OptionButton = _find_node("ProviderSelect") as OptionButton
@onready var _smart_commit_btn: Button = _find_node("SmartCommitBtn") as Button
@onready var _chat_send: Button = _find_node("ChatSend") as Button
@onready var _status_left: Label = _find_node("StatusLeft") as Label
@onready var _status_git: Button = _find_node("StatusGit") as Button
@onready var _status_cursor: Label = _find_node("StatusCursor") as Label
@onready var _status_lang: Label = _find_node("StatusLang") as Label
@onready var _status_enc: Label = _find_node("StatusEnc") as Label
@onready var _status_ai: Label = _find_node("StatusAI") as Label
@onready var _main_split: HSplitContainer = _find_node("MainSplit") as HSplitContainer
@onready var _center_split: HSplitContainer = _find_node("CenterSplit") as HSplitContainer
@onready var _explorer_pane: PanelContainer = _find_node("ExplorerPane") as PanelContainer
@onready var _chat_pane: PanelContainer = _find_node("ChatPane") as PanelContainer
@onready var _explorer_rail_btn: Button = _find_node("ExplorerRailBtn") as Button
@onready var _edit_rail_btn: Button = _find_node("EditRailBtn") as Button
@onready var _git_rail_btn: Button = _find_node("GitRailBtn") as Button
@onready var _themes_rail_btn: Button = _find_node("ThemesRailBtn") as Button
@onready var _chat_rail_btn: Button = _find_node("ChatRailBtn") as Button
@onready var _config_rail_btn: Button = _find_node("ConfigRailBtn") as Button
@onready var _help_rail_btn: Button = _find_node("HelpRailBtn") as Button
@onready var _drawer_collapse_btn: Button = _find_node("DrawerCollapseBtn") as Button
@onready var _switch_workspace_btn: Button = _find_node("SwitchWorkspaceBtn") as Button
@onready var _workspace_state: Label = _find_node("WorkspaceState") as Label
@onready var _file_menu: PopupMenu = _find_node("File") as PopupMenu
@onready var _edit_menu: PopupMenu = _find_node("Edit") as PopupMenu
@onready var _git_menu: PopupMenu = _find_node("Git") as PopupMenu
@onready var _config_menu: PopupMenu = _find_node("Config") as PopupMenu
@onready var _help_menu: PopupMenu = _find_node("Help") as PopupMenu
@onready var _about_menu: PopupMenu = _find_node("About") as PopupMenu
@onready var _app_brand: MenuButton = _find_node("AppBrand") as MenuButton
@onready var _theme_toggle_btn: Button = _find_node("ThemeToggleBtn") as Button
@onready var _themes_menu: PopupMenu = _find_node("Themes") as PopupMenu
var _open_file_dlg: FileDialog = null
var _open_dir_dlg: FileDialog = null
var _save_as_dlg: FileDialog = null
var _open_theme_xml_dlg: FileDialog = null
@onready var _overlay: ColorRect = _find_node("Overlay") as ColorRect
@onready var _dialog_panel: PanelContainer = _find_node("DialogPanel") as PanelContainer
@onready var _dialog_title: Label = _find_node("DialogTitle") as Label
@onready var _dialog_body: RichTextLabel = _find_node("DialogBody") as RichTextLabel
@onready var _dialog_input_row: HBoxContainer = _find_node("DialogInputRow") as HBoxContainer
@onready var _dialog_input: LineEdit = _find_node("DialogInput") as LineEdit
@onready var _dialog_action_btn: Button = _find_node("DialogActionBtn") as Button
@onready var _dialog_close: Button = _find_node("DialogClose") as Button
@onready var _ai_chat_http: HTTPRequest = _find_node("AIChatHttp") as HTTPRequest
@onready var _chat_status_banner: PanelContainer = _find_node("ChatStatusBanner") as PanelContainer
@onready var _chat_status_label: RichTextLabel = _find_node("ChatStatusLabel") as RichTextLabel
@onready var _chat_thinking_label: RichTextLabel = _find_node("ChatThinkingLabel") as RichTextLabel
@onready var _chat_suggestions_popup: PanelContainer = _find_node("ChatSuggestionsPopup") as PanelContainer
@onready var _chat_suggestions_list: ItemList = _find_node("ChatSuggestionsList") as ItemList
@onready var _find_row: HBoxContainer = _find_node("FindRow") as HBoxContainer
@onready var _find_input: LineEdit = _find_node("FindInput") as LineEdit
@onready var _replace_input: LineEdit = _find_node("ReplaceInput") as LineEdit
@onready var _replace_all: Button = _find_node("ReplaceAll") as Button
@onready var _find_next: Button = _find_node("FindNext") as Button
@onready var _find_close: Button = _find_node("FindClose") as Button
@onready var _markdown_preview: RichTextLabel = _find_node("MarkdownPreview") as RichTextLabel

var _dialog_action_callback: Callable = Callable()

var _workspace_root: String = ""
var _custom_themes: Dictionary[String, Dictionary] = {}
var _theme_menu_keys: Array[String] = []
var _open_files: Array = []
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
var _explorer_collapsed: bool = false
var _chat_collapsed: bool = false
var _explorer_split_offset: int = 0
var _chat_split_offset: int = 0
var _os_notify_generation: int = 0
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

## Sub-controllers
var chat: EditorChatController
var git: EditorGitController
var files: EditorFileManager
var dialog: EditorDialogController
var themes: EditorThemeManager
var sidebar: EditorSidebarBuilder
var input_handler: EditorInputHandler

func _init() -> void:
	chat = EditorChatController.new(self)
	git = EditorGitController.new(self)
	files = EditorFileManager.new(self)
	dialog = EditorDialogController.new(self)
	themes = EditorThemeManager.new(self)
	sidebar = EditorSidebarBuilder.new(self)
	input_handler = EditorInputHandler.new(self)


func _ready() -> void:
	var base_res = ProjectSettings.globalize_path("res://").rstrip("/")
	if DirAccess.dir_exists_absolute(base_res):
		_workspace_root = base_res
	else:
		_workspace_root = base_res.get_base_dir()
	chat.load_ai_config()
	themes.load_theme_config()
	themes.apply_kitty_fish_theme()
	_wire_signals()
	_configure_code_edit()
	files.open_untitled()
	chat.update_ai_status()
	_status_left.text = "READY"
	_status_enc.text = "UTF-8"
	call_deferred("_apply_split_offsets")
	call_deferred("_setup_sidebar_panels")
	call_deferred("_refresh_file_tree")
	call_deferred("_update_git_status_bar")


func _process(delta: float) -> void:
	if _stream_active:
		chat.poll_chat_stream()
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
				_git_progress_label.text = "Generating AI commit message... (%.1fs)" % elapsed
			_status_left.text = "%s Smart Commit · %s (%.1fs)" % [frame, _ai_provider, elapsed]
		else:
			_chat_status_label.text = "[color=#ffa348]%s[/color] [b]Thinking…[/b] [color=#858585](%.1fs)[/color]\n[color=#858585]AI thoughts (live) · Tip: Use /save, /files, /open, /cancel, /clear[/color]" % [frame, elapsed]
			_status_left.text = "%s Thinking · %s (%.1fs) · esc to cancel" % [frame, _ai_provider, elapsed]
			chat.refresh_thinking_panel()


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
	var target = _explorer_split_offset if _explorer_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.18)
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
	var target = _chat_split_offset if _chat_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.50)
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
			git.refresh_git_panel()
	if _sidebar_themes_panel:
		_sidebar_themes_panel.visible = (_current_sidebar_tab == SidebarTab.THEMES)
		if _current_sidebar_tab == SidebarTab.THEMES:
			themes.refresh_themes_panel()
	if _sidebar_config_panel:
		_sidebar_config_panel.visible = (_current_sidebar_tab == SidebarTab.CONFIG)
	if _sidebar_help_panel:
		_sidebar_help_panel.visible = (_current_sidebar_tab == SidebarTab.HELP)

	var rail_buttons = [
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
	sidebar.setup_sidebar_panels()


func _refresh_file_tree() -> void:
	files.refresh_file_tree()


func _update_git_status_bar() -> void:
	git.update_git_status_bar()


static var _icon_cache: Dictionary = {}

static func _load_svg_icon(path: String) -> Texture2D:
	if _icon_cache.has(path):
		return _icon_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.has_cached(path) or ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is Texture2D:
			tex = res as Texture2D
	if tex == null:
		var abs_p = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_p):
			var img = Image.load_from_file(abs_p)
			if img and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	_icon_cache[path] = tex
	return tex


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
	_file_tree.item_activated.connect(files.on_tree_item_activated)
	_file_tree.item_selected.connect(files.on_tree_item_selected)
	_file_tree.item_collapsed.connect(files.on_tree_item_collapsed)
	_tab_bar.tab_changed.connect(files.on_tab_changed)
	_tab_bar.tab_close_pressed.connect(files.on_tab_close)
	_code_edit.text_changed.connect(files.on_code_changed)
	_code_edit.gui_input.connect(input_handler.on_code_editor_gui_input)
	_code_edit.caret_changed.connect(files.on_caret_changed)
	_chat_input.text_submitted.connect(chat.on_chat_submitted)
	_chat_log.meta_clicked.connect(chat.on_chat_meta_clicked)
	_chat_input.text_changed.connect(chat.on_chat_input_text_changed)
	_chat_input.gui_input.connect(chat.on_chat_input_gui_input)
	_chat_send.pressed.connect(chat.on_chat_send_pressed)
	_chat_context_chip.pressed.connect(chat.on_context_chip_pressed)
	_attach_btn.pressed.connect(chat.on_attach_btn_pressed)
	chat.setup_composer_dropdowns()
	_clear_chat_btn = get_node_or_null("%ClearChatBtn") as Button
	if _clear_chat_btn:
		_clear_chat_btn.pressed.connect(chat.on_clear_chat_pressed)
		_clear_chat_btn.icon = _load_svg_icon("res://icons/clear.svg")
		_clear_chat_btn.text = ""
	_compact_chat_btn = get_node_or_null("%CompactChatBtn") as Button
	if _compact_chat_btn:
		_compact_chat_btn.pressed.connect(chat.on_compact_chat_pressed)
		_compact_chat_btn.icon = _load_svg_icon("res://icons/compact.svg")
		_compact_chat_btn.text = ""
	if _smart_commit_btn:
		_smart_commit_btn.pressed.connect(git.generate_smart_commit)
	_file_menu.id_pressed.connect(_on_file_menu)
	_edit_menu.id_pressed.connect(_on_edit_menu)
	if _git_menu:
		_git_menu.id_pressed.connect(_on_git_menu)
	themes.populate_themes_menu()
	if _themes_menu:
		_themes_menu.id_pressed.connect(themes.on_theme_menu_id_pressed)
	if _status_git:
		_status_git.pressed.connect(git.show_git_status_dialog)
	_config_menu.id_pressed.connect(_on_config_menu)
	_help_menu.id_pressed.connect(_on_help_menu)
	if _about_menu:
		_about_menu.id_pressed.connect(_on_about_menu)
	if _app_brand:
		themes.setup_app_brand_menu()
	if _chat_history.is_empty():
		chat.show_chat_welcome()
	if _open_file_dlg:
		_open_file_dlg.file_selected.connect(files.open_path)
	if _open_dir_dlg:
		_open_dir_dlg.dir_selected.connect(files.on_dir_selected)
	if _save_as_dlg:
		_save_as_dlg.file_selected.connect(files.save_as_path)
	if _open_theme_xml_dlg:
		_open_theme_xml_dlg.file_selected.connect(themes.import_theme_from_xml)
	_dialog_close.pressed.connect(dialog.hide_overlay)
	if _dialog_action_btn:
		_dialog_action_btn.pressed.connect(dialog.on_dialog_action_pressed)
	if _dialog_input:
		_dialog_input.text_submitted.connect(func(_t: String) -> void: dialog.on_dialog_action_pressed())
	_ai_chat_http.timeout = 60.0
	_ai_chat_http.request_completed.connect(chat.on_ai_chat_http_completed)
	_provider_select.item_selected.connect(chat.on_provider_selected)
	_find_input.text_submitted.connect(files.do_find)
	_find_next.pressed.connect(files.on_find_next)
	_replace_all.pressed.connect(files.replace_all_matches)
	_find_close.pressed.connect(func() -> void: _find_row.visible = false)
	_chat_suggestions_list.item_selected.connect(chat.on_chat_suggestion_selected)
	_chat_suggestions_list.item_activated.connect(chat.on_chat_suggestion_selected)
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
			dialog.get_open_dir_dlg().popup_centered()
		)


func _input(event: InputEvent) -> void:
	input_handler.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	input_handler.handle_unhandled_input(event)


func _on_file_menu(id: int) -> void:
	match id:
		0: dialog.get_open_file_dlg().popup_centered()
		1: dialog.get_open_dir_dlg().popup_centered()
		3: files.open_untitled()
		4: files.save_active()
		5: dialog.get_save_as_dlg().popup_centered()


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
		0: git.show_git_status_dialog()
		1: git.generate_smart_commit()
		2: git.git_push()
		3: git.git_pull()
		4: git.git_fetch()
		5: git.git_sync()
		7: git.prompt_git_branch()
		8: git.show_git_log_dialog()
		9: git.show_git_diff_dialog()
		11: git.show_github_info_dialog()
		12: git.prompt_git_config()


func _on_config_menu(id: int) -> void:
	match id:
		0: dialog.show_config()
		1: dialog.prompt_api_key(true, Callable())


func _on_help_menu(_id: int) -> void:
	dialog.show_help()


func _on_about_menu(_id: int) -> void:
	dialog.show_about()


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
	var is_light = ThemeColorScheme.is_light(_active_theme)
	return MarkdownPreview.render(markdown, is_light)


func _configure_code_edit() -> void:
	CodeEditorTools.configure(_code_edit, _active_palette(), _open_files)


func _update_code_completion() -> void:
	CodeEditorTools.update_completion(_code_edit, _open_files)


func _create_adwaita_fish_highlighter() -> CodeHighlighter:
	return CodeEditorTools.create_highlighter(_active_palette())


func _active_palette() -> Dictionary:
	return themes.all_themes().get(_active_theme, ThemeColorScheme.MODE_THEMES[ThemeColorScheme.MODE_DARK])
