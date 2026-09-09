class_name EditorGitController
extends RefCounted

## Manages Git operations and UI integration for the editor

const ChatMarkdown = preload("res://scripts/chat_markdown_renderer.gd")

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

func set_git_panel_busy(busy: bool) -> void:
	if _e.git_commit_msg_input:
		_e.git_commit_msg_input.editable = not busy
	if _e.git_commit_btn:
		_e.git_commit_btn.disabled = busy
	if _e.git_smart_commit_btn:
		_e.git_smart_commit_btn.disabled = busy
	if _e.git_push_btn:
		_e.git_push_btn.disabled = busy
	if _e.git_pull_btn:
		_e.git_pull_btn.disabled = busy
	if _e.git_sync_btn:
		_e.git_sync_btn.disabled = busy
	if _e.git_status_tree:
		_e.git_status_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE if busy else Control.MOUSE_FILTER_STOP



func append_git_output(title: String, text: String, is_error: bool = false) -> void:
	if _e.git_console_log == null:
		return
	var title_color = "#ED333B" if is_error else "#57E389"
	var text_fmt = ChatMarkdown.render(text)
	_e.git_console_log.append_text("[b][color=%s]● %s[/color][/b]\n%s\n\n" % [title_color, title, text_fmt])
	_e.git_console_log.scroll_to_line(_e.git_console_log.get_line_count() - 1)
	if _e.current_sidebar_tab != _e.SidebarTab.GIT:
		_e.select_sidebar_tab(_e.SidebarTab.GIT)



func commit_git_message(msg: String) -> void:
	var commit_text: String = msg.strip_edges()
	if commit_text.is_empty():
		self.generate_smart_commit()
		return
	if not GitService.is_git_repository(_e.workspace_root):
		self.append_git_output("Git Error", "No Git repository found in workspace.", true)
		return
	self.set_git_panel_busy(true)
	GitService.stage_all(_e.workspace_root)
	var res: Dictionary = GitService.commit(commit_text, _e.workspace_root)
	if bool(res.get("success", false)):
		self.append_git_output("Git Commit", "Commit created successfully:\n" + commit_text)
		_e.dialog.send_os_notification("Git Commit", "Committed: " + commit_text)
		if _e.git_commit_msg_input:
			_e.git_commit_msg_input.text = ""
		self.update_git_status_bar()
		self.refresh_git_panel()
	else:
		self.append_git_output("Git Commit Failed", str(res.get("output", res.get("error", "Failed to commit"))), true)
		_e.dialog.send_os_notification("Git Commit Failed", str(res.get("error", "Failed to commit")), true)
	self.set_git_panel_busy(false)



func on_git_status_item_activated() -> void:
	if _e.git_status_tree == null:
		return
	var item: TreeItem = _e.git_status_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.has("path"):
		var full_p: String = str(meta.get("path", ""))
		if FileAccess.file_exists(full_p):
			_e.files.open_path(full_p)



func refresh_git_panel() -> void:
	if _e.git_status_tree == null:
		return
	_e.git_status_tree.clear()
	var root = _e.git_status_tree.create_item()
	if not GitService.is_git_repository(_e.workspace_root):
		var item = _e.git_status_tree.create_item(root)
		item.set_text(0, "No Git repository found")
		return
	var st: Dictionary = GitService.get_status(_e.workspace_root)
	var branch: String = str(st.get("branch", "main"))
	var is_clean: bool = bool(st.get("is_clean", true))

	if _e.workspace_state and _e.current_sidebar_tab == _e.SidebarTab.GIT:
		_e.workspace_state.text = "SOURCE CONTROL: " + branch.to_upper()

	var staged: Array = st.get("staged", [])
	if not staged.is_empty():
		var staged_cat = _e.git_status_tree.create_item(root)
		staged_cat.set_text(0, "Staged Changes (%d)" % staged.size())
		staged_cat.set_custom_color(0, Color("#30d158"))
		for f in staged:
			var rel: String = str(f)
			var full_path: String = _e.workspace_root.path_join(rel)
			var item = _e.git_status_tree.create_item(staged_cat)
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
		var unstaged_cat = _e.git_status_tree.create_item(root)
		unstaged_cat.set_text(0, "Changes (%d)" % unstaged.size())
		unstaged_cat.set_custom_color(0, Color("#ffa348"))
		for f in unstaged:
			var rel: String = str(f)
			var full_path: String = _e.workspace_root.path_join(rel)
			var item = _e.git_status_tree.create_item(unstaged_cat)
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
		var untracked_cat = _e.git_status_tree.create_item(root)
		untracked_cat.set_text(0, "Untracked Files (%d)" % untracked.size())
		untracked_cat.set_custom_color(0, Color("#8e8e93"))
		for f in untracked:
			var rel: String = str(f)
			var full_path: String = _e.workspace_root.path_join(rel)
			var item = _e.git_status_tree.create_item(untracked_cat)
			item.set_text(0, rel)
			item.set_text(1, "U")
			item.set_custom_color(1, Color("#8e8e93"))
			var tex: Texture2D = FileKind.texture_for_path(full_path, false, false)
			if tex:
				item.set_icon(0, tex)
				item.set_icon_max_width(0, 16)
			item.set_metadata(0, {"path": full_path, "rel_path": rel, "type": "untracked"})

	if is_clean:
		var clean_item = _e.git_status_tree.create_item(root)
		clean_item.set_text(0, "Working tree clean")
		clean_item.set_custom_color(0, Color("#8e8e93"))



func update_git_status_bar() -> void:
	if not _e.status_git:
		return
	if not GitService.is_git_repository(_e.workspace_root):
		_e.status_git.text = "no git"
		_e.status_git.add_theme_color_override("font_color", Color("#9a9996"))
		return
	var st: Dictionary = GitService.get_status(_e.workspace_root)
	var branch: String = str(st.get("branch", "main"))
	var is_clean: bool = bool(st.get("is_clean", true))
	if is_clean:
		_e.status_git.text = branch
		_e.status_git.add_theme_color_override("font_color", Color("#57e389"))
	else:
		var staged: Array = st.get("staged", [])
		var unstaged: Array = st.get("unstaged", [])
		var untracked: Array = st.get("untracked", [])
		var total: int = staged.size() + unstaged.size() + untracked.size()
		_e.status_git.text = "%s *(%d)" % [branch, total]
		_e.status_git.add_theme_color_override("font_color", Color("#ffa348"))



func show_git_status_dialog() -> void:
	var st: Dictionary = GitService.get_status(_e.workspace_root)
	var gh: Dictionary = GitService.get_github_info(_e.workspace_root)
	_e.dialog.show_overlay("Git Repository Status", GitService.format_status_bbcode(st, gh))
	self.update_git_status_bar()



func show_git_log_dialog() -> void:
	var log_entries: Array[Dictionary] = GitService.get_log(20, _e.workspace_root)
	_e.dialog.show_overlay("Git Commit History", GitService.format_log_bbcode(log_entries))



func show_git_diff_dialog() -> void:
	var diff_res: Dictionary = GitService.get_diff("", false, _e.workspace_root)
	_e.dialog.show_overlay("Working Tree Diff", GitService.format_diff_bbcode(str(diff_res.get("output", ""))))



func show_github_info_dialog() -> void:
	var gh: Dictionary = GitService.get_github_info(_e.workspace_root)
	var body = "[b][color=#62a0ea]GitHub Repository Information[/color][/b]\n\n"
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
	_e.dialog.show_overlay("GitHub Repository", body)



func prompt_git_branch() -> void:
	var branches: Array[Dictionary] = GitService.get_branches(_e.workspace_root)
	var branch_list = ""
	for b in branches:
		var prefix = "● " if bool(b.get("is_current", false)) else "  "
		branch_list += prefix + str(b.get("display_name", "")) + "\n"
	var current: String = GitService.get_current_branch(_e.workspace_root)
	_e.dialog.show_input_dialog(
		"Switch / New Branch",
		"[b]Current Branches:[/b]\n" + branch_list + "\nEnter branch name to switch or create (prefix with '+' to create a new branch):",
		"branch-name or +new-branch",
		current,
		"Switch / Create",
		func(val: String) -> void:
			if val.is_empty():
				return
			var create_new = false
			var target_b = val
			if target_b.begins_with("+") or target_b.begins_with("-b "):
				create_new = true
				target_b = target_b.trim_prefix("+").trim_prefix("-b ").strip_edges()
			var res: Dictionary = GitService.checkout_branch(target_b, create_new, _e.workspace_root)
			if bool(res.get("success", false)):
				self.append_git_output("Git Branch", "Switched to branch '%s' successfully." % target_b)
				_e.dialog.show_toast("Switched to branch: " + target_b, false)
			else:
				self.append_git_output("Git Branch Error", "Failed to switch branch:\n" + str(res.get("output", "")), true)
				_e.dialog.show_toast("Branch switch failed.", true)
			self.update_git_status_bar()
	)



func prompt_git_config() -> void:
	var cfg: Dictionary = GitService.get_user_config(_e.workspace_root)
	var def_val: String = "%s <%s>" % [str(cfg.get("name", "")), str(cfg.get("email", ""))]
	_e.dialog.show_input_dialog(
		"Configure Git User",
		"[b]Git User Configuration[/b]\nFormat: `Your Name <your.email@example.com>`",
		"Name <email@example.com>",
		def_val if def_val != " <>" else "",
		"Save Config",
		func(val: String) -> void:
			if val.is_empty():
				return
			var name_part = val
			var email_part = ""
			if val.contains("<") and val.contains(">"):
				var start_idx = val.find("<")
				var end_idx = val.find(">")
				name_part = val.substr(0, start_idx).strip_edges()
				email_part = val.substr(start_idx + 1, end_idx - start_idx - 1).strip_edges()
			var res: Dictionary = GitService.set_user_config(name_part, email_part, false, _e.workspace_root)
			if bool(res.get("success", false)):
				self.append_git_output("Git Config", "Git user configured: %s <%s>" % [name_part, email_part])
				_e.dialog.show_toast("Git user configured.", false)
			else:
				self.append_git_output("Git Config Error", "Failed to configure Git user.", true)
				_e.dialog.show_toast("Failed to configure Git user.", true)
	)



func prompt_git_clone() -> void:
	_e.dialog.show_input_dialog(
		"Clone Repository",
		"[b]Clone a GitHub Repository[/b]\nEnter the repository URL (SSH or HTTPS):",
		"git@github.com:user/repo.git",
		"",
		"Clone",
		func(url: String) -> void:
			if url.is_empty():
				return
			var target_dir: String = _e.workspace_root.path_join(url.get_file().trim_suffix(".git"))
			_e.dialog.show_toast("Cloning repository…", false)
			self.set_git_panel_busy(true)
			var res: Dictionary = GitService.clone_repository(url, target_dir)
			if bool(res.get("success", false)):
				self.append_git_output("Git Clone", "Repository cloned to %s" % target_dir)
				_e.files.refresh_file_tree()
				self.update_git_status_bar()
			else:
				self.append_git_output("Git Clone Error", "Failed to clone repository:\n" + str(res.get("output", "")), true)
				_e.dialog.show_toast("Git clone failed.", true)
			self.set_git_panel_busy(false)
	)



func git_push(remote: String = "origin", branch: String = "") -> void:
	self.set_git_panel_busy(true)
	_e.dialog.show_toast("Pushing commits to GitHub…", false)
	var res: Dictionary = GitService.push(remote, branch, true, _e.workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Everything up-to-date."
		self.append_git_output("Push to GitHub Succeeded", out_txt)
		_e.dialog.show_toast("Push to GitHub completed successfully!", false)
	else:
		self.append_git_output("Git Push Error", str(res.get("output", "")), true)
		_e.dialog.show_toast("Git push failed.", true)
	self.set_git_panel_busy(false)
	self.update_git_status_bar()



func git_pull(remote: String = "origin", branch: String = "") -> void:
	self.set_git_panel_busy(true)
	_e.dialog.show_toast("Pulling changes from GitHub…", false)
	var res: Dictionary = GitService.pull(remote, branch, false, _e.workspace_root)
	if bool(res.get("success", false)):
		var out_txt: String = str(res.get("output", "")).strip_edges()
		if out_txt.is_empty():
			out_txt = "Already up to date."
		self.append_git_output("Pull from GitHub Succeeded", out_txt)
		_e.dialog.show_toast("Pull from GitHub completed!", false)
		_e.files.refresh_file_tree()
	else:
		self.append_git_output("Git Pull Error", str(res.get("output", "")), true)
		_e.dialog.show_toast("Git pull failed.", true)
	self.set_git_panel_busy(false)
	self.update_git_status_bar()



func git_fetch(remote: String = "origin") -> void:
	self.set_git_panel_busy(true)
	_e.dialog.show_toast("Fetching from %s…" % remote, false)
	var res: Dictionary = GitService.fetch(remote, _e.workspace_root)
	if bool(res.get("success", false)):
		self.append_git_output("Git Fetch", "Fetch completed successfully from " + remote)
		_e.dialog.show_toast("Fetch completed.", false)
	else:
		self.append_git_output("Git Fetch Error", str(res.get("output", "")), true)
	self.set_git_panel_busy(false)
	self.update_git_status_bar()



func git_sync(remote: String = "origin", branch: String = "") -> void:
	self.set_git_panel_busy(true)
	_e.dialog.show_toast("Synchronising with GitHub (Pull & Push)…", false)
	var res: Dictionary = GitService.sync(remote, branch, _e.workspace_root)
	if bool(res.get("success", false)):
		self.append_git_output("GitHub Sync Succeeded", str(res.get("output", "")))
		_e.dialog.show_toast("GitHub synchronisation completed!", false)
		_e.files.refresh_file_tree()
	else:
		self.append_git_output("GitHub Sync Error (%s)" % str(res.get("stage", "sync")), str(res.get("error", "")), true)
		_e.dialog.show_toast("Sync failed.", true)
	self.set_git_panel_busy(false)
	self.update_git_status_bar()



func generate_smart_commit() -> void:
	if not GitService.is_git_repository(_e.workspace_root):
		_e.dialog.send_os_notification("Git Error", "Not a Git repository.", true)
		return
	self.continue_smart_commit()



func continue_smart_commit() -> void:
	var st: Dictionary = GitService.get_status(_e.workspace_root)
	var staged: Array   = st.get("staged",    [])
	var unstaged: Array = st.get("unstaged",  [])
	var untracked: Array= st.get("untracked", [])
	if staged.is_empty() and unstaged.is_empty() and untracked.is_empty():
		_e.dialog.send_os_notification("Git", "Nothing to commit.", false)
		return

	var stage_res: Dictionary = GitService.stage_all(_e.workspace_root)
	if not bool(stage_res.get("success", false)):
		_e.dialog.send_os_notification("Git Error", "Failed to stage changes.", true)
		return

	var diff_stat_res: Dictionary = GitService.get_diff_stat(_e.workspace_root)
	var diff_stat: String = str(diff_stat_res.get("output", "")).strip_edges()

	var diff_res: Dictionary = GitService.get_diff("", true, _e.workspace_root)
	var diff_text: String = str(diff_res.get("output", "")).strip_edges()
	if diff_text.length() > 3000:
		diff_text = diff_text.substr(0, 3000) + "\n... [diff truncated]"

	if diff_text.is_empty():
		diff_text = diff_stat

	if not AIService.has_nvidia_api_key():
		self.finish_smart_commit(GitService.build_fallback_commit_message(_e.workspace_root), false, "No NVIDIA NIM key.")
		return

	if _e.git_progress_panel:
		_e.git_progress_panel.visible = true
	if _e.git_progress_label:
		_e.git_progress_label.text = "Generating AI commit message..."
	if _e.git_progress_bar:
		_e.git_progress_bar.value = 10.0

	var commit_prompt = (
		"You are an expert software engineer. Analyse the following `git diff --cached` output " +
		"and produce ONE concise Git commit message following the Conventional Commits specification " +
		"(https://www.conventionalcommits.org).\n\n" +
		"Rules:\n" +
		"- Use one of: feat, fix, docs, style, refactor, perf, test, chore, build, ci\n" +
		"- First line: type(scope): short summary in imperative mood, max 72 chars\n" +
		"- Output ONLY the commit message — no explanation, no markdown fences\n\n" +
		"Git diff:\n```\n" + diff_text + "\n```"
	)

	self.ai_smart_commit_request(commit_prompt, diff_stat)



func ai_smart_commit_request(prompt: String, diff_stat: String) -> void:
	if _e.ai_busy:
		self.finish_smart_commit(GitService.build_fallback_commit_message(_e.workspace_root), false, "AI is busy.")
		return

	_e.ai_busy = true
	_e.request_start_time = Time.get_ticks_msec() / 1000.0
	_e.spinner_time = 0.0
	if _e.git_progress_panel:
		_e.git_progress_panel.visible = true
	if _e.git_progress_label:
		_e.git_progress_label.text = "Analysing Git changes..."
	if _e.git_progress_bar:
		_e.git_progress_bar.value = 20.0
	_e.status_left.text = "Smart Commit: generating AI message…"
	_e.current_prompt = "__SMART_COMMIT__:" + diff_stat
	_e.smart_commit_prompt = prompt
	_e.model_candidates = AIService.get_candidate_models(_e.ai_provider)
	_e.model_candidate_index = 0
	_e.chat.send_chat_completion()



func finish_smart_commit(commit_msg: String, _via_ai: bool, _note: String = "") -> void:
	_e.current_prompt = ""
	_e.smart_commit_prompt = ""
	_e.chat.clear_ai_busy()
	if _e.git_progress_panel:
		_e.git_progress_panel.visible = false
	if _e.git_progress_bar:
		_e.git_progress_bar.value = 0.0
	var message: String = commit_msg.strip_edges()
	if message.is_empty():
		message = GitService.build_fallback_commit_message(_e.workspace_root)
	if _e.git_commit_msg_input:
		_e.git_commit_msg_input.text = message
	var headline: String = message.split("\n")[0]
	_e.dialog.send_os_notification("Smart Commit", "AI generated commit message:\n" + headline)
	self.refresh_git_panel()



func fallback_smart_commit(reason: String) -> void:
	var local_msg: String = GitService.build_fallback_commit_message(_e.workspace_root)
	self.finish_smart_commit(local_msg, false, reason + " Using local message.")



func is_smart_commit_pending() -> bool:
	return not _e.smart_commit_prompt.is_empty() or _e.current_prompt.begins_with("__SMART_COMMIT__:")



func execute_git_command(args: PackedStringArray) -> Dictionary:
	return GitService.execute(args, _e.workspace_root)



