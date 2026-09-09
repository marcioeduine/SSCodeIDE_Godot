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

@onready var root_vbox: Control = (_find_node("AppHBox") if _find_node("AppHBox") else _find_node("RootVBox")) as Control
@onready var file_tree: Tree = _find_node("FileTree") as Tree
@onready var tab_bar: TabBar = _find_node("TabBar") as TabBar
@onready var code_edit: CodeEdit = _find_node("CodeEdit") as CodeEdit
@onready var chat_log: RichTextLabel = _find_node("ChatLog") as RichTextLabel
@onready var chat_context_badge: Label = _find_node("ChatContextBadge") as Label
@onready var chat_context_chip: Button = _find_node("ChatContextChip") as Button
@onready var chat_input: LineEdit = _find_node("ChatInput") as LineEdit
@onready var attach_btn: Button = _find_node("AttachBtn") as Button
@onready var agent_mode_btn: MenuButton = _find_node("AgentModeBtn") as MenuButton
@onready var model_badge_btn: MenuButton = _find_node("ModelBadgeBtn") as MenuButton
@onready var provider_select: OptionButton = _find_node("ProviderSelect") as OptionButton
@onready var smart_commit_btn: Button = _find_node("SmartCommitBtn") as Button
@onready var chat_send: Button = _find_node("ChatSend") as Button
@onready var status_left: Label = _find_node("StatusLeft") as Label
@onready var status_git: Button = _find_node("StatusGit") as Button
@onready var status_cursor: Label = _find_node("StatusCursor") as Label
@onready var status_lang: Label = _find_node("StatusLang") as Label
@onready var status_enc: Label = _find_node("StatusEnc") as Label
@onready var status_ai: Label = _find_node("StatusAI") as Label
@onready var main_split: HSplitContainer = _find_node("MainSplit") as HSplitContainer
@onready var center_split: HSplitContainer = _find_node("CenterSplit") as HSplitContainer
@onready var explorer_pane: PanelContainer = _find_node("ExplorerPane") as PanelContainer
@onready var chat_pane: PanelContainer = _find_node("ChatPane") as PanelContainer
@onready var explorer_rail_btn: Button = _find_node("ExplorerRailBtn") as Button
@onready var edit_rail_btn: Button = _find_node("EditRailBtn") as Button
@onready var git_rail_btn: Button = _find_node("GitRailBtn") as Button
@onready var themes_rail_btn: Button = _find_node("ThemesRailBtn") as Button
@onready var chat_rail_btn: Button = _find_node("ChatRailBtn") as Button
@onready var config_rail_btn: Button = _find_node("ConfigRailBtn") as Button
@onready var help_rail_btn: Button = _find_node("HelpRailBtn") as Button
@onready var drawer_collapse_btn: Button = _find_node("DrawerCollapseBtn") as Button
@onready var switch_workspace_btn: Button = _find_node("SwitchWorkspaceBtn") as Button
@onready var workspace_state: Label = _find_node("WorkspaceState") as Label
@onready var file_menu: PopupMenu = _find_node("File") as PopupMenu
@onready var edit_menu: PopupMenu = _find_node("Edit") as PopupMenu
@onready var git_menu: PopupMenu = _find_node("Git") as PopupMenu
@onready var config_menu: PopupMenu = _find_node("Config") as PopupMenu
@onready var help_menu: PopupMenu = _find_node("Help") as PopupMenu
@onready var about_menu: PopupMenu = _find_node("About") as PopupMenu
@onready var app_brand: MenuButton = _find_node("AppBrand") as MenuButton
@onready var theme_toggle_btn: Button = _find_node("ThemeToggleBtn") as Button
@onready var themes_menu: PopupMenu = _find_node("Themes") as PopupMenu
var open_file_dlg: FileDialog = null
var open_dir_dlg: FileDialog = null
var save_as_dlg: FileDialog = null
var open_theme_xml_dlg: FileDialog = null
@onready var overlay: ColorRect = _find_node("Overlay") as ColorRect
@onready var dialog_panel: PanelContainer = _find_node("DialogPanel") as PanelContainer
@onready var dialog_title: Label = _find_node("DialogTitle") as Label
@onready var dialog_body: RichTextLabel = _find_node("DialogBody") as RichTextLabel
@onready var dialog_input_row: HBoxContainer = _find_node("DialogInputRow") as HBoxContainer
@onready var dialog_input: LineEdit = _find_node("DialogInput") as LineEdit
@onready var dialog_action_btn: Button = _find_node("DialogActionBtn") as Button
@onready var dialog_close: Button = _find_node("DialogClose") as Button
@onready var ai_chat_http: HTTPRequest = _find_node("AIChatHttp") as HTTPRequest
@onready var chat_status_banner: PanelContainer = _find_node("ChatStatusBanner") as PanelContainer
@onready var chat_status_label: RichTextLabel = _find_node("ChatStatusLabel") as RichTextLabel
@onready var chat_thinking_label: RichTextLabel = _find_node("ChatThinkingLabel") as RichTextLabel
@onready var chat_suggestions_popup: PanelContainer = _find_node("ChatSuggestionsPopup") as PanelContainer
@onready var chat_suggestions_list: ItemList = _find_node("ChatSuggestionsList") as ItemList
@onready var find_row: HBoxContainer = _find_node("FindRow") as HBoxContainer
@onready var find_input: LineEdit = _find_node("FindInput") as LineEdit
@onready var replace_input: LineEdit = _find_node("ReplaceInput") as LineEdit
@onready var replace_all: Button = _find_node("ReplaceAll") as Button
@onready var find_next: Button = _find_node("FindNext") as Button
@onready var find_close: Button = _find_node("FindClose") as Button
@onready var markdown_preview: RichTextLabel = _find_node("MarkdownPreview") as RichTextLabel

var dialog_action_callback: Callable = Callable()

var workspace_root: String = ""
var custom_themes: Dictionary[String, Dictionary] = {}
var theme_menu_keys: Array[String] = []
var open_files: Array = []
var active_index: int = -1
var suppress_tab: bool = false
var md_preview_active: bool = false
var agent_mode: bool = true
var ai_busy: bool = false
var response_rendered: bool = false
var ai_provider: String = "nemotron"
var active_theme: String = "adwaita_darker"
var current_prompt: String = ""
var smart_commit_prompt: String = ""
var model_candidates: Array[String] = []
var model_candidate_index: int = 0
var spinner_time: float = 0.0
var request_start_time: float = 0.0
var chat_history: Array[Dictionary] = []
var prompt_history: Array[String] = []
var prompt_history_idx: int = -1
var prompt_draft: String = ""
var explorer_collapsed: bool = false
var chat_collapsed: bool = false
var explorer_split_offset: int = 0
var chat_split_offset: int = 0
var os_notify_generation: int = 0
var thinking_text: String = ""
var stream_http: HTTPClient = HTTPClient.new()
var stream_active: bool = false
var sse_buf: String = ""
var stream_reply: String = ""

enum SidebarTab { EXPLORER, SEARCH, GIT, THEMES, CONFIG, HELP }
var current_sidebar_tab: SidebarTab = SidebarTab.EXPLORER
var sidebar_search_panel: VBoxContainer = null
var sidebar_git_panel: VBoxContainer = null
var sidebar_themes_panel: VBoxContainer = null
var sidebar_config_panel: VBoxContainer = null
var sidebar_help_panel: VBoxContainer = null
var git_status_tree: Tree = null
var git_commit_msg_input: LineEdit = null
var git_commit_btn: Button = null
var git_smart_commit_btn: Button = null
var git_push_btn: Button = null
var git_pull_btn: Button = null
var git_sync_btn: Button = null
var git_progress_panel: VBoxContainer = null
var git_progress_bar: ProgressBar = null
var git_progress_label: Label = null
var git_console_panel: PanelContainer = null
var git_console_log: RichTextLabel = null
var themes_list: ItemList = null
var search_query_input: LineEdit = null
var search_replace_input: LineEdit = null
var search_match_case_btn: Button = null
var search_whole_word_btn: Button = null
var search_include_input: LineEdit = null
var search_exclude_input: LineEdit = null
var search_results_tree: Tree = null
var search_summary_label: Label = null
var clear_chat_btn: Button = null
var compact_chat_btn: Button = null
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
		workspace_root = base_res
	else:
		workspace_root = base_res.get_base_dir()
	chat.load_ai_config()
	themes.load_theme_config()
	themes.apply_kitty_fish_theme()
	_wire_signals()
	_configure_code_edit()
	files.open_untitled()
	chat.update_ai_status()
	status_left.text = "READY"
	status_enc.text = "UTF-8"
	call_deferred("_apply_split_offsets")
	call_deferred("_setup_sidebar_panels")
	call_deferred("_refresh_file_tree")
	call_deferred("_update_git_status_bar")


func _process(delta: float) -> void:
	if stream_active:
		chat.poll_chat_stream()
	if ai_busy:
		spinner_time += delta
		var frame_idx: int = int(spinner_time * 10.0) % SPINNER_FRAMES.size()
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - request_start_time
		var frame: String = SPINNER_FRAMES[frame_idx]
		if current_prompt.begins_with("__SMART_COMMIT__:"):
			if git_progress_panel:
				git_progress_panel.visible = true
			if git_progress_bar:
				var cycle_val: float = fmod(elapsed * 50.0, 100.0)
				git_progress_bar.value = cycle_val
			if git_progress_label:
				git_progress_label.text = "Generating AI commit message... (%.1fs)" % elapsed
			status_left.text = "%s Smart Commit · %s (%.1fs)" % [frame, ai_provider, elapsed]
		else:
			chat_status_label.text = "[color=#ffa348]%s[/color] [b]Thinking…[/b] [color=#858585](%.1fs)[/color]\n[color=#858585]AI thoughts (live) · Tip: Use /save, /files, /open, /cancel, /clear[/color]" % [frame, elapsed]
			status_left.text = "%s Thinking · %s (%.1fs) · esc to cancel" % [frame, ai_provider, elapsed]
			chat.refresh_thinking_panel()


func _apply_split_offsets() -> void:
	var w: float = size.x
	if w <= 1.0:
		w = get_viewport_rect().size.x
	if not explorer_collapsed:
		main_split.split_offset = int(w * 0.18)
		explorer_split_offset = main_split.split_offset
	if not chat_collapsed:
		center_split.split_offset = int(w * 0.50)
		chat_split_offset = center_split.split_offset


func toggle_explorer() -> void:
	if explorer_collapsed:
		_expand_explorer()
	else:
		_collapse_explorer(true)


func toggle_chat() -> void:
	if chat_collapsed:
		_expand_chat()
	else:
		_collapse_chat(true)


func _expand_explorer() -> void:
	explorer_collapsed = false
	explorer_pane.visible = true
	var target = explorer_split_offset if explorer_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.18)
	main_split.split_offset = target
	status_left.text = "Explorer  ▶  shown"
	_update_sidebar_tab_visibility()


func _collapse_explorer(save_offset: bool) -> void:
	if explorer_collapsed:
		return
	if save_offset and main_split.split_offset > SPLIT_COLLAPSE_PX:
		explorer_split_offset = main_split.split_offset
	explorer_collapsed = true
	explorer_pane.visible = false
	status_left.text = "Explorer  ◀  hidden  (Ctrl+B to restore)"
	_update_sidebar_tab_visibility()


func _expand_chat() -> void:
	chat_collapsed = false
	chat_pane.visible = true
	var target = chat_split_offset if chat_split_offset > SPLIT_COLLAPSE_PX else int(get_viewport_rect().size.x * 0.50)
	center_split.split_offset = target
	status_left.text = "Chat  ▶  shown"
	_update_sidebar_tab_visibility()


func _collapse_chat(save_offset: bool) -> void:
	if chat_collapsed:
		return
	if save_offset and center_split.split_offset > SPLIT_COLLAPSE_PX:
		chat_split_offset = center_split.split_offset
	chat_collapsed = true
	chat_pane.visible = false
	status_left.text = "Chat  ◀  hidden  (Ctrl+Shift+B to restore)"
	_update_sidebar_tab_visibility()


func select_sidebar_tab(tab: SidebarTab) -> void:
	if not explorer_collapsed and current_sidebar_tab == tab:
		_collapse_explorer(true)
		return
	current_sidebar_tab = tab
	_update_sidebar_tab_visibility()
	_expand_explorer()


func _update_sidebar_tab_visibility() -> void:
	file_tree.visible = (current_sidebar_tab == SidebarTab.EXPLORER)
	if switch_workspace_btn:
		switch_workspace_btn.visible = (current_sidebar_tab == SidebarTab.EXPLORER)

	if current_sidebar_tab == SidebarTab.SEARCH:
		sidebar.ensure_search_panel()
	if sidebar_search_panel:
		sidebar_search_panel.visible = (current_sidebar_tab == SidebarTab.SEARCH)

	if current_sidebar_tab == SidebarTab.GIT:
		sidebar.ensure_git_panel()
	if sidebar_git_panel:
		sidebar_git_panel.visible = (current_sidebar_tab == SidebarTab.GIT)
		if current_sidebar_tab == SidebarTab.GIT:
			git.refresh_git_panel()

	if current_sidebar_tab == SidebarTab.THEMES:
		sidebar.ensure_themes_panel()
	if sidebar_themes_panel:
		sidebar_themes_panel.visible = (current_sidebar_tab == SidebarTab.THEMES)
		if current_sidebar_tab == SidebarTab.THEMES:
			themes.refresh_themes_panel()

	if current_sidebar_tab == SidebarTab.CONFIG:
		sidebar.ensure_config_panel()
	if sidebar_config_panel:
		sidebar_config_panel.visible = (current_sidebar_tab == SidebarTab.CONFIG)

	if current_sidebar_tab == SidebarTab.HELP:
		sidebar.ensure_help_panel()
	if sidebar_help_panel:
		sidebar_help_panel.visible = (current_sidebar_tab == SidebarTab.HELP)

	var rail_buttons = [
		[explorer_rail_btn, current_sidebar_tab == SidebarTab.EXPLORER],
		[edit_rail_btn, current_sidebar_tab == SidebarTab.SEARCH],
		[git_rail_btn, current_sidebar_tab == SidebarTab.GIT],
		[themes_rail_btn, current_sidebar_tab == SidebarTab.THEMES],
		[config_rail_btn, current_sidebar_tab == SidebarTab.CONFIG],
		[help_rail_btn, current_sidebar_tab == SidebarTab.HELP],
	]
	for pair in rail_buttons:
		var btn: Button = pair[0]
		var is_active: bool = pair[1] and not explorer_collapsed
		if btn:
			btn.theme_type_variation = &"M3RailButtonActive" if is_active else &"M3RailButton"

	if chat_rail_btn:
		chat_rail_btn.theme_type_variation = &"M3RailButtonActive" if not chat_collapsed else &"M3RailButton"

	if workspace_state:
		match current_sidebar_tab:
			SidebarTab.EXPLORER:
				var root_title: String = workspace_root.get_file()
				workspace_state.text = (root_title if not root_title.is_empty() else "WORKSPACE").to_upper()
			SidebarTab.SEARCH:
				workspace_state.text = "SEARCH & REPLACE"
			SidebarTab.GIT:
				workspace_state.text = "SOURCE CONTROL"
			SidebarTab.THEMES:
				workspace_state.text = "THEMES & IMPORTS"
			SidebarTab.CONFIG:
				workspace_state.text = "SETTINGS"
			SidebarTab.HELP:
				workspace_state.text = "HELP & SHORTCUTS"


func _setup_sidebar_panels() -> void:
	sidebar.setup_sidebar_panels()


func _refresh_file_tree() -> void:
	files.refresh_file_tree()


func _update_git_status_bar() -> void:
	git.update_git_status_bar()


static var icon_cache: Dictionary = {}

static func _load_svg_icon(path: String) -> Texture2D:
	if icon_cache.has(path):
		return icon_cache[path]
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
	icon_cache[path] = tex
	return tex


func _on_main_split_dragged(offset: int) -> void:
	if explorer_collapsed:
		return
	if offset > SPLIT_COLLAPSE_PX:
		explorer_split_offset = offset
		return
	_collapse_explorer(false)


func _on_center_split_dragged(offset: int) -> void:
	if chat_collapsed:
		return
	var remaining: int = int(center_split.size.x) - offset
	if remaining > SPLIT_COLLAPSE_PX:
		chat_split_offset = offset
		return
	_collapse_chat(false)


func _wire_signals() -> void:
	file_tree.item_activated.connect(files.on_tree_item_activated)
	file_tree.item_selected.connect(files.on_tree_item_selected)
	file_tree.item_collapsed.connect(files.on_tree_item_collapsed)
	tab_bar.tab_changed.connect(files.on_tab_changed)
	tab_bar.tab_close_pressed.connect(files.on_tab_close)
	code_edit.text_changed.connect(files.on_code_changed)
	code_edit.gui_input.connect(input_handler.on_code_editor_gui_input)
	code_edit.caret_changed.connect(files.on_caret_changed)
	chat_input.text_submitted.connect(chat.on_chat_submitted)
	chat_log.meta_clicked.connect(chat.on_chat_meta_clicked)
	chat_input.text_changed.connect(chat.on_chat_input_text_changed)
	chat_input.gui_input.connect(chat.on_chat_input_gui_input)
	chat_send.pressed.connect(chat.on_chat_send_pressed)
	chat_context_chip.pressed.connect(chat.on_context_chip_pressed)
	attach_btn.pressed.connect(chat.on_attach_btn_pressed)
	chat.setup_composer_dropdowns()
	clear_chat_btn = get_node_or_null("%ClearChatBtn") as Button
	if clear_chat_btn:
		clear_chat_btn.pressed.connect(chat.on_clear_chat_pressed)
		clear_chat_btn.icon = _load_svg_icon("res://icons/clear.svg")
		clear_chat_btn.text = ""
	compact_chat_btn = get_node_or_null("%CompactChatBtn") as Button
	if compact_chat_btn:
		compact_chat_btn.pressed.connect(chat.on_compact_chat_pressed)
		compact_chat_btn.icon = _load_svg_icon("res://icons/compact.svg")
		compact_chat_btn.text = ""
	if smart_commit_btn:
		smart_commit_btn.pressed.connect(git.generate_smart_commit)
	file_menu.id_pressed.connect(_on_file_menu)
	edit_menu.id_pressed.connect(_on_edit_menu)
	if git_menu:
		git_menu.id_pressed.connect(on_git_menu)
	themes.populate_themes_menu()
	if themes_menu:
		themes_menu.id_pressed.connect(themes.on_theme_menu_id_pressed)
	if status_git:
		status_git.pressed.connect(git.show_git_status_dialog)
	config_menu.id_pressed.connect(_on_config_menu)
	help_menu.id_pressed.connect(_on_help_menu)
	if about_menu:
		about_menu.id_pressed.connect(_on_about_menu)
	if app_brand:
		themes.setup_app_brand_menu()
	if chat_history.is_empty():
		chat.show_chat_welcome()
	if open_file_dlg:
		open_file_dlg.file_selected.connect(files.open_path)
	if open_dir_dlg:
		open_dir_dlg.dir_selected.connect(files.on_dir_selected)
	if save_as_dlg:
		save_as_dlg.file_selected.connect(files.save_as_path)
	if open_theme_xml_dlg:
		open_theme_xml_dlg.file_selected.connect(themes.import_theme_from_xml)
	if dialog_close:
		dialog_close.pressed.connect(dialog.hide_overlay)
	if dialog_action_btn:
		dialog_action_btn.pressed.connect(dialog.on_dialog_action_pressed)
	if dialog_input:
		dialog_input.text_submitted.connect(func(_t: String) -> void: dialog.on_dialog_action_pressed())
	ai_chat_http.timeout = 60.0
	ai_chat_http.request_completed.connect(chat.on_ai_chat_http_completed)
	provider_select.item_selected.connect(chat.on_provider_selected)
	find_input.text_submitted.connect(files.do_find)
	find_next.pressed.connect(files.on_find_next)
	replace_all.pressed.connect(files.replace_all_matches)
	find_close.pressed.connect(func() -> void: find_row.visible = false)
	chat_suggestions_list.item_selected.connect(chat.on_chat_suggestion_selected)
	chat_suggestions_list.item_activated.connect(chat.on_chat_suggestion_selected)
	main_split.dragged.connect(_on_main_split_dragged)
	center_split.dragged.connect(_on_center_split_dragged)
	if explorer_rail_btn:
		explorer_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.EXPLORER))
	if edit_rail_btn:
		edit_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.SEARCH))
	if git_rail_btn:
		git_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.GIT))
	if themes_rail_btn:
		themes_rail_btn.visible = true
		themes_rail_btn.tooltip_text = "Themes & Import XML"
		themes_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.THEMES))
	if chat_rail_btn:
		chat_rail_btn.pressed.connect(toggle_chat)
	if config_rail_btn:
		config_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.CONFIG))
	if help_rail_btn:
		help_rail_btn.pressed.connect(func() -> void: select_sidebar_tab(SidebarTab.HELP))
	if drawer_collapse_btn:
		drawer_collapse_btn.pressed.connect(toggle_explorer)
	if switch_workspace_btn:
		switch_workspace_btn.pressed.connect(func() -> void:
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
		0: code_edit.undo()
		1: code_edit.redo()
		3: code_edit.cut()
		4: code_edit.copy()
		5: code_edit.paste()
		6: code_edit.select_all()
		7:
			find_row.visible = true
			find_input.grab_focus()


func on_git_menu(id: int) -> void:
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


func set_markdown_preview(enabled: bool, raw_md: String) -> void:
	md_preview_active = enabled
	if enabled:
		code_edit.visible = false
		markdown_preview.visible = true
		markdown_preview.clear()
		markdown_preview.text = ""
		var bbcode: String = _markdown_to_bbcode(raw_md)
		markdown_preview.append_text(bbcode)
	else:
		markdown_preview.visible = false
		code_edit.visible = true


func _markdown_to_bbcode(markdown: String) -> String:
	var is_light = ThemeColorScheme.is_light(active_theme)
	return MarkdownPreview.render(markdown, is_light)


func _configure_code_edit() -> void:
	CodeEditorTools.configure(code_edit, _active_palette(), open_files)


func update_code_completion() -> void:
	CodeEditorTools.update_completion(code_edit, open_files)


func create_adwaita_fish_highlighter() -> CodeHighlighter:
	return CodeEditorTools.create_highlighter(_active_palette())


func _active_palette() -> Dictionary:
	return themes.all_themes().get(active_theme, ThemeColorScheme.MODE_THEMES[ThemeColorScheme.MODE_DARK])
