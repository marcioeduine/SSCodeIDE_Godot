class_name EditorSidebarBuilder
extends RefCounted

## Builds the sidebar panels for the editor

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

static func _load_svg_icon(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var img = Image.new()
	if img.load_svg_from_string(FileAccess.get_file_as_string(path), 1.0) == OK:
		return ImageTexture.create_from_image(img)
	return null

func setup_sidebar_panels() -> void:
	var container: Node = _e.file_tree.get_parent()
	if not container:
		return

	# -------------------------------------------------------------
	# 1. Search Panel (VS Code Style Find/Replace in Workspace)
	# -------------------------------------------------------------
	_e.sidebar_search_panel = VBoxContainer.new()
	_e.sidebar_search_panel.name = "SidebarSearchPanel"
	_e.sidebar_search_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.sidebar_search_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.sidebar_search_panel.visible = false
	container.add_child(_e.sidebar_search_panel)

	var s_margin = MarginContainer.new()
	s_margin.add_theme_constant_override("margin_left", 8)
	s_margin.add_theme_constant_override("margin_right", 8)
	s_margin.add_theme_constant_override("margin_top", 4)
	s_margin.add_theme_constant_override("margin_bottom", 4)
	var s_vbox = VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 6)

	_e.search_query_input = LineEdit.new()
	_e.search_query_input.placeholder_text = "Search in workspace…"
	_e.search_query_input.clear_button_enabled = true
	_e.search_query_input.text_submitted.connect(func(t: String) -> void: _e.files.do_workspace_search(t))
	s_vbox.add_child(_e.search_query_input)

	_e.search_replace_input = LineEdit.new()
	_e.search_replace_input.placeholder_text = "Replace with…"
	_e.search_replace_input.clear_button_enabled = true
	s_vbox.add_child(_e.search_replace_input)

	var s_ctrl_row = HBoxContainer.new()
	s_ctrl_row.add_theme_constant_override("separation", 4)

	_e.search_match_case_btn = Button.new()
	_e.search_match_case_btn.text = "Aa"
	_e.search_match_case_btn.toggle_mode = true
	_e.search_match_case_btn.tooltip_text = "Match Case"
	s_ctrl_row.add_child(_e.search_match_case_btn)

	_e.search_whole_word_btn = Button.new()
	_e.search_whole_word_btn.text = "\\b"
	_e.search_whole_word_btn.toggle_mode = true
	_e.search_whole_word_btn.tooltip_text = "Match Whole Word"
	s_ctrl_row.add_child(_e.search_whole_word_btn)

	var search_run_btn = Button.new()
	search_run_btn.text = "Search"
	search_run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_run_btn.theme_type_variation = &"M3FilledButton"
	search_run_btn.pressed.connect(func() -> void:
		if _e.search_query_input:
			_e.files.do_workspace_search(_e.search_query_input.text)
	)
	s_ctrl_row.add_child(search_run_btn)

	var replace_all_btn = Button.new()
	replace_all_btn.text = "Replace All"
	replace_all_btn.pressed.connect(func() -> void:
		if _e.search_query_input and _e.search_replace_input:
			_e.files.replace_in_workspace(_e.search_query_input.text, _e.search_replace_input.text)
	)
	s_ctrl_row.add_child(replace_all_btn)
	s_vbox.add_child(s_ctrl_row)

	_e.search_include_input = LineEdit.new()
	_e.search_include_input.placeholder_text = "files to include (e.g. *.gd)"
	s_vbox.add_child(_e.search_include_input)

	_e.search_exclude_input = LineEdit.new()
	_e.search_exclude_input.placeholder_text = "files to exclude (e.g. .godot/*)"
	s_vbox.add_child(_e.search_exclude_input)

	_e.search_summary_label = Label.new()
	_e.search_summary_label.text = "0 results"
	_e.search_summary_label.theme_type_variation = &"M3StatusText"
	s_vbox.add_child(_e.search_summary_label)

	s_margin.add_child(s_vbox)
	_e.sidebar_search_panel.add_child(s_margin)

	_e.search_results_tree = Tree.new()
	_e.search_results_tree.hide_root = true
	_e.search_results_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.search_results_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.search_results_tree.theme_type_variation = &"M3ExplorerTree"
	_e.search_results_tree.item_activated.connect(_e.files.on_search_result_activated)
	_e.sidebar_search_panel.add_child(_e.search_results_tree)

	# -------------------------------------------------------------
	# 2. Source Control & GitHub Panel (VS Code Style, Dynamic & Spacious)
	# -------------------------------------------------------------
	_e.sidebar_git_panel = VBoxContainer.new()
	_e.sidebar_git_panel.name = "SidebarGitPanel"
	_e.sidebar_git_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.sidebar_git_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.sidebar_git_panel.visible = false
	container.add_child(_e.sidebar_git_panel)

	var git_vsplit = VSplitContainer.new()
	git_vsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	git_vsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	git_vsplit.split_offset = 240
	_e.sidebar_git_panel.add_child(git_vsplit)

	var top_git_vbox = VBoxContainer.new()
	top_git_vbox.add_theme_constant_override("separation", 8)
	top_git_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_git_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Commit Input & Actions Box
	var git_margin = MarginContainer.new()
	git_margin.add_theme_constant_override("margin_left", 8)
	git_margin.add_theme_constant_override("margin_right", 8)
	git_margin.add_theme_constant_override("margin_top", 6)
	git_margin.add_theme_constant_override("margin_bottom", 4)
	var git_vbox = VBoxContainer.new()
	git_vbox.add_theme_constant_override("separation", 8)

	_e.git_commit_msg_input = LineEdit.new()
	_e.git_commit_msg_input.placeholder_text = "Message (Ctrl+Enter to commit)"
	_e.git_commit_msg_input.custom_minimum_size = Vector2(0, 32)
	_e.git_commit_msg_input.clear_button_enabled = true
	_e.git_commit_msg_input.text_submitted.connect(func(msg: String) -> void: _e.git.commit_git_message(msg))
	git_vbox.add_child(_e.git_commit_msg_input)

	var commit_row = HBoxContainer.new()
	commit_row.add_theme_constant_override("separation", 6)

	_e.git_commit_btn = Button.new()
	_e.git_commit_btn.text = "Commit"
	_e.git_commit_btn.custom_minimum_size = Vector2(0, 32)
	var icon_commit: Texture2D = _load_svg_icon("res://icons/git_commit.svg")
	if icon_commit:
		_e.git_commit_btn.icon = icon_commit
		_e.git_commit_btn.expand_icon = true
	_e.git_commit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_commit_btn.theme_type_variation = &"M3FilledButton"
	_e.git_commit_btn.pressed.connect(func() -> void:
		if _e.git_commit_msg_input:
			_e.git.commit_git_message(_e.git_commit_msg_input.text)
	)
	commit_row.add_child(_e.git_commit_btn)

	_e.git_smart_commit_btn = Button.new()
	_e.git_smart_commit_btn.text = "Smart Commit"
	_e.git_smart_commit_btn.custom_minimum_size = Vector2(0, 32)
	var icon_sparkle: Texture2D = _load_svg_icon("res://icons/git_sparkle.svg")
	if icon_sparkle:
		_e.git_smart_commit_btn.icon = icon_sparkle
		_e.git_smart_commit_btn.expand_icon = true
	_e.git_smart_commit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_smart_commit_btn.theme_type_variation = &"M3NavPillButton"
	_e.git_smart_commit_btn.pressed.connect(_e.git.generate_smart_commit)
	commit_row.add_child(_e.git_smart_commit_btn)
	git_vbox.add_child(commit_row)

	# Emergent SmartCommit Progress UI (Sleek ProgressBar + Status Text, no heavy box)
	_e.git_progress_panel = VBoxContainer.new()
	_e.git_progress_panel.add_theme_constant_override("separation", 4)
	_e.git_progress_panel.visible = false

	var prog_status_row = HBoxContainer.new()
	prog_status_row.add_theme_constant_override("separation", 6)

	_e.git_progress_label = Label.new()
	_e.git_progress_label.text = "Generating AI commit message..."
	_e.git_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_progress_label.add_theme_font_size_override("font_size", 11)
	_e.git_progress_label.add_theme_color_override("font_color", Color("#A1A1A6"))
	prog_status_row.add_child(_e.git_progress_label)
	_e.git_progress_panel.add_child(prog_status_row)

	_e.git_progress_bar = ProgressBar.new()
	_e.git_progress_bar.show_percentage = false
	_e.git_progress_bar.custom_minimum_size = Vector2(0, 4)
	_e.git_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_progress_bar.min_value = 0.0
	_e.git_progress_bar.max_value = 100.0
	_e.git_progress_bar.value = 0.0

	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color("#222224")
	sb_bg.set_corner_radius_all(2)

	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color("#30D158")
	sb_fill.set_corner_radius_all(2)

	_e.git_progress_bar.add_theme_stylebox_override("background", sb_bg)
	_e.git_progress_bar.add_theme_stylebox_override("fill", sb_fill)

	_e.git_progress_panel.add_child(_e.git_progress_bar)
	git_vbox.add_child(_e.git_progress_panel)

	git_margin.add_child(git_vbox)
	top_git_vbox.add_child(git_margin)

	# Git Status Tree
	_e.git_status_tree = Tree.new()
	_e.git_status_tree.hide_root = true
	_e.git_status_tree.columns = 2
	_e.git_status_tree.set_column_expand(0, true)
	_e.git_status_tree.set_column_custom_minimum_width(1, 28)
	_e.git_status_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_status_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.git_status_tree.theme_type_variation = &"M3ExplorerTree"
	_e.git_status_tree.item_activated.connect(_e.git.on_git_status_item_activated)
	top_git_vbox.add_child(_e.git_status_tree)

	# Git Push, Pull, Sync Action Buttons
	var git_actions_margin = MarginContainer.new()
	git_actions_margin.add_theme_constant_override("margin_left", 8)
	git_actions_margin.add_theme_constant_override("margin_right", 8)
	git_actions_margin.add_theme_constant_override("margin_bottom", 6)
	var git_btn_box = HBoxContainer.new()
	git_btn_box.add_theme_constant_override("separation", 6)

	_e.git_push_btn = Button.new()
	_e.git_push_btn.text = "Push"
	_e.git_push_btn.custom_minimum_size = Vector2(0, 30)
	_e.git_push_btn.theme_type_variation = &"M3NavPillButton"
	var icon_push: Texture2D = _load_svg_icon("res://icons/git_push.svg")
	if icon_push:
		_e.git_push_btn.icon = icon_push
		_e.git_push_btn.expand_icon = true
	_e.git_push_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_push_btn.pressed.connect(func() -> void: _e.on_git_menu(3))
	git_btn_box.add_child(_e.git_push_btn)

	_e.git_pull_btn = Button.new()
	_e.git_pull_btn.text = "Pull"
	_e.git_pull_btn.custom_minimum_size = Vector2(0, 30)
	_e.git_pull_btn.theme_type_variation = &"M3NavPillButton"
	var icon_pull: Texture2D = _load_svg_icon("res://icons/git_pull.svg")
	if icon_pull:
		_e.git_pull_btn.icon = icon_pull
		_e.git_pull_btn.expand_icon = true
	_e.git_pull_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_pull_btn.pressed.connect(func() -> void: _e.on_git_menu(4))
	git_btn_box.add_child(_e.git_pull_btn)

	_e.git_sync_btn = Button.new()
	_e.git_sync_btn.text = "Sync"
	_e.git_sync_btn.custom_minimum_size = Vector2(0, 30)
	_e.git_sync_btn.theme_type_variation = &"M3NavPillButton"
	var icon_sync: Texture2D = _load_svg_icon("res://icons/git_sync.svg")
	if icon_sync:
		_e.git_sync_btn.icon = icon_sync
		_e.git_sync_btn.expand_icon = true
	_e.git_sync_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_sync_btn.pressed.connect(func() -> void: _e.on_git_menu(5))
	git_btn_box.add_child(_e.git_sync_btn)

	git_actions_margin.add_child(git_btn_box)
	top_git_vbox.add_child(git_actions_margin)
	git_vsplit.add_child(top_git_vbox)

	# Dedicated Git Output Console (Clean Borderless Inner Log)
	_e.git_console_panel = PanelContainer.new()
	_e.git_console_panel.custom_minimum_size = Vector2(0, 130)
	_e.git_console_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_console_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.git_console_panel.theme_type_variation = &"M3Composer"
	var console_margin = MarginContainer.new()
	console_margin.add_theme_constant_override("margin_left", 8)
	console_margin.add_theme_constant_override("margin_right", 8)
	console_margin.add_theme_constant_override("margin_top", 6)
	console_margin.add_theme_constant_override("margin_bottom", 6)
	var console_vbox = VBoxContainer.new()
	console_vbox.add_theme_constant_override("separation", 4)

	var console_hdr = HBoxContainer.new()
	var console_lbl = Label.new()
	console_lbl.text = "GIT OUTPUT LOGS"
	console_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_lbl.add_theme_color_override("font_color", Color("#A1A1A6"))
	console_lbl.add_theme_font_size_override("font_size", 11)
	console_hdr.add_child(console_lbl)

	var clear_console_b = Button.new()
	clear_console_b.text = "Clear"
	clear_console_b.flat = true
	clear_console_b.add_theme_color_override("font_color", Color("#8E8E93"))
	clear_console_b.add_theme_font_size_override("font_size", 11)
	clear_console_b.pressed.connect(func() -> void:
		if _e.git_console_log:
			_e.git_console_log.clear()
	)
	console_hdr.add_child(clear_console_b)
	console_vbox.add_child(console_hdr)

	_e.git_console_log = RichTextLabel.new()
	_e.git_console_log.bbcode_enabled = true
	_e.git_console_log.scroll_following = true
	_e.git_console_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.git_console_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var empty_box = StyleBoxEmpty.new()
	_e.git_console_log.add_theme_stylebox_override("normal", empty_box)
	_e.git_console_log.add_theme_stylebox_override("focus", empty_box)
	var fira_font: Font = load("res://fonts/FiraCodeNerdFont-Regular.ttf") as Font
	if fira_font:
		_e.git_console_log.add_theme_font_override("normal_font", fira_font)
	_e.git_console_log.add_theme_font_size_override("normal_font_size", 12)
	console_vbox.add_child(_e.git_console_log)
	console_margin.add_child(console_vbox)
	_e.git_console_panel.add_child(console_margin)
	git_vsplit.add_child(_e.git_console_panel)

	# -------------------------------------------------------------
	# 3. Themes Panel
	# -------------------------------------------------------------
	_e.sidebar_themes_panel = VBoxContainer.new()
	_e.sidebar_themes_panel.name = "SidebarThemesPanel"
	_e.sidebar_themes_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.sidebar_themes_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.sidebar_themes_panel.visible = false
	container.add_child(_e.sidebar_themes_panel)

	var th_lbl = Label.new()
	th_lbl.text = "Custom XML Themes:"
	_e.sidebar_themes_panel.add_child(th_lbl)

	_e.themes_list = ItemList.new()
	_e.themes_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.themes_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.themes_list.item_selected.connect(func(idx: int) -> void:
		var theme_name: String = str(_e.themes_list.get_item_metadata(idx))
		_e.themes.apply_theme_by_name(theme_name)
	)
	_e.sidebar_themes_panel.add_child(_e.themes_list)

	var import_xml_btn = Button.new()
	import_xml_btn.text = "Import XML Theme…"
	import_xml_btn.pressed.connect(_e.dialog.import_theme_xml_dialog)
	_e.sidebar_themes_panel.add_child(import_xml_btn)

	# -------------------------------------------------------------
	# 4. Settings Panel
	# -------------------------------------------------------------
	_e.sidebar_config_panel = VBoxContainer.new()
	_e.sidebar_config_panel.name = "SidebarConfigPanel"
	_e.sidebar_config_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.sidebar_config_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.sidebar_config_panel.visible = false
	container.add_child(_e.sidebar_config_panel)

	var cfg_info = RichTextLabel.new()
	cfg_info.bbcode_enabled = true
	cfg_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cfg_info.text = "[b]Settings & AI Config[/b]\n\n"
	cfg_info.text += "[b]AI Provider:[/b] NVIDIA NIM / Nemotron\n"
	cfg_info.text += "[b]Workspace:[/b] " + _e.workspace_root + "\n\n"
	cfg_info.text += "[color=#8E8E93]Use top menu bar for advanced options.[/color]"
	_e.sidebar_config_panel.add_child(cfg_info)

	# -------------------------------------------------------------
	# 5. Help Panel
	# -------------------------------------------------------------
	_e.sidebar_help_panel = VBoxContainer.new()
	_e.sidebar_help_panel.name = "SidebarHelpPanel"
	_e.sidebar_help_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_e.sidebar_help_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_e.sidebar_help_panel.visible = false
	container.add_child(_e.sidebar_help_panel)

	var help_info = RichTextLabel.new()
	help_info.bbcode_enabled = true
	help_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_info.text = _e.HELP_TEXT
	_e.sidebar_help_panel.add_child(help_info)
