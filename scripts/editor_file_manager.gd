class_name EditorFileManager
extends RefCounted

## Manages files, tabs, tree, and search operations

var _e  ## Reference to the main ui_editor Control node

func _init(editor: Control) -> void:
	_e = editor

func refresh_file_tree() -> void:
	_e.file_tree.clear()
	var root_item: TreeItem = _e.file_tree.create_item()
	var root_title: String = _e.workspace_root.get_file()
	if root_title.is_empty():
		root_title = "WORKSPACE"
	if _e.workspace_state:
		_e.workspace_state.text = root_title.to_upper()
	root_item.set_text(0, root_title.to_upper())
	var folder_tex: Texture2D = FileKind.texture_for_path(_e.workspace_root, true, true)
	if folder_tex:
		root_item.set_icon(0, folder_tex)
		root_item.set_icon_max_width(0, 16)
	root_item.set_custom_color(0, Color("#8ec4f7"))
	_e.file_tree.set_column_title(0, "Files")
	populate_tree_dir(root_item, _e.workspace_root)



func populate_tree_dir(parent_item: TreeItem, dir_path: String, max_depth: int = 1, current_depth: int = 0) -> void:
	if parent_item == null or _e.file_tree == null:
		return
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	var dirs: Array[String] = []
	var files: Array[String] = []
	while fname != "":
		if fname not in [".", "..", ".git", ".godot", ".gemini", "docs", "icons", "fonts", "test", "android", "build", "dist", "node_modules"]:
			if dir.current_is_dir():
				dirs.append(fname)
			else:
				files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	dirs.sort()
	files.sort()
	for d: String in dirs:
		var item: TreeItem = _e.file_tree.create_item(parent_item)
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
			populate_tree_dir(item, item_path, max_depth, current_depth + 1)
		else:
			item.set_metadata(0, {"path": item_path, "is_dir": true, "loaded": false})
			var sub_dir = DirAccess.open(item_path)
			if sub_dir:
				sub_dir.list_dir_begin()
				var sub_fname = sub_dir.get_next()
				var has_sub_content = false
				while sub_fname != "":
					if sub_fname not in [".", "..", ".git", ".godot", ".gemini", "android"]:
						has_sub_content = true
						break
					sub_fname = sub_dir.get_next()
				sub_dir.list_dir_end()
				if has_sub_content:
					var dummy: TreeItem = _e.file_tree.create_item(item)
					if dummy != null:
						dummy.set_text(0, "Loading…")
	for f: String in files:
		var item: TreeItem = _e.file_tree.create_item(parent_item)
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



func on_tree_item_collapsed(item: TreeItem) -> void:
	if not item or _e.is_queued_for_deletion():
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		var p: String = str(meta.get("path", ""))
		var folder_tex: Texture2D = FileKind.texture_for_path(p, true, not item.collapsed)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)
		if not item.collapsed and not meta.get("loaded", false):
			(func(): deferred_load_tree_dir(item, p)).call_deferred()



func deferred_load_tree_dir(item: TreeItem, p: String) -> void:
	if not is_instance_valid(item) or _e.is_queued_for_deletion():
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
	populate_tree_dir(item, p, 1, 0)



func on_tree_item_activated() -> void:
	var item: TreeItem = _e.file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and not meta.get("is_dir", false):
		open_path(str(meta.get("path", "")))



func on_tree_item_selected() -> void:
	var item: TreeItem = _e.file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		item.collapsed = not item.collapsed



func open_untitled() -> void:
	var info = {
		"path": "",
		"title": "untitled",
		"content": "",
		"dirty": false,
		"cursor_line": 0,
		"cursor_col": 0,
	}
	_e.open_files.append(info)
	_e.tab_bar.add_tab("untitled")
	_e.active_index = _e.open_files.size() - 1
	var u_tex: Texture2D = FileKind.small_texture_for_path("", 14)
	if u_tex:
		_e.tab_bar.set_tab_icon(_e.active_index, u_tex)
	_e.tab_bar.current_tab = _e.active_index
	load_active_into_editor()



func open_path(path: String) -> void:
	for i in range(_e.open_files.size()):
		if _e.open_files[i].get("path") == path:
			_e.active_index = i
			_e.tab_bar.current_tab = i
			load_active_into_editor()
			return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		_e.status_left.text = "ERR: Cannot open " + path.get_file()
		return
	var content: String = f.get_as_text()
	var title: String = path.get_file()
	var info = {
		"path": path,
		"title": title,
		"content": content,
		"dirty": false,
		"cursor_line": 0,
		"cursor_col": 0,
	}
	_e.open_files.append(info)
	_e.tab_bar.add_tab(title)
	_e.active_index = _e.open_files.size() - 1
	var f_tex: Texture2D = FileKind.small_texture_for_path(path, 14)
	if f_tex:
		_e.tab_bar.set_tab_icon(_e.active_index, f_tex)
	_e.tab_bar.current_tab = _e.active_index
	load_active_into_editor()
	_e.status_left.text = "OPEN: " + title



func load_active_into_editor() -> void:
	if _e.active_index < 0 or _e.active_index >= _e.open_files.size():
		return
	_e.suppress_tab = true
	var info: Dictionary = _e.open_files[_e.active_index]
	_e.code_edit.text = str(info.get("content", ""))
	_e.code_edit.set_caret_line(int(info.get("cursor_line", 0)))
	_e.code_edit.set_caret_column(int(info.get("cursor_col", 0)))
	_e.code_edit.clear_undo_history()
	_e.suppress_tab = false
	var path: String = str(info.get("path", ""))
	_e.status_lang.text = FileKind.label_for_path(path)
	update_cursor_status()
	if not path.is_empty():
		_e.chat_context_chip.text = "+ " + path.get_file()
		var root_name: String = _e.workspace_root.get_file() if not _e.workspace_root.is_empty() else "My Project"
		if root_name.is_empty():
			root_name = "My Project"
		var rel: String = path.replace(_e.workspace_root, "").trim_prefix("/")
		_e.status_left.text = root_name + " > " + rel.replace("/", " > ")
	else:
		_e.chat_context_chip.text = "+ Untitled"
		_e.status_left.text = "My Project > Untitled"
	# Markdown preview toggle
	var is_md: bool = path.to_lower().ends_with(".md")
	_e.set_markdown_preview(is_md, str(info.get("content", "")))



func save_active() -> void:
	if _e.active_index < 0 or _e.active_index >= _e.open_files.size():
		return
	var info: Dictionary = _e.open_files[_e.active_index]
	var path: String = str(info.get("path", ""))
	if path.is_empty():
		_e.save_as_dlg.popup_centered()
		return
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		_e.status_left.text = "ERR: Cannot save " + path.get_file()
		return
	f.store_string(_e.code_edit.text)
	info["content"] = _e.code_edit.text
	info["dirty"] = false
	_e.tab_bar.set_tab_title(_e.active_index, info.get("title", ""))
	_e.status_left.text = "SAVED: " + path.get_file()
	_e.git.update_git_status_bar()



func save_as_path(path: String) -> void:
	if _e.active_index < 0 or _e.active_index >= _e.open_files.size():
		return
	var info: Dictionary = _e.open_files[_e.active_index]
	info["path"] = path
	info["title"] = path.get_file()
	save_active()
	_e.status_lang.text = FileKind.label_for_path(path)
	_e.git.update_git_status_bar()



func on_dir_selected(dir_path: String) -> void:
	_e.workspace_root = dir_path
	refresh_file_tree()
	_e.status_left.text = "WORKSPACE: " + dir_path.get_file()
	_e.git.update_git_status_bar()



func on_tab_changed(tab_idx: int) -> void:
	if _e.suppress_tab or tab_idx == _e.active_index:
		return
	save_editor_state_to_active()
	_e.active_index = tab_idx
	load_active_into_editor()



func on_tab_close(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _e.open_files.size():
		return
	_e.suppress_tab = true
	var closing_active: bool = (tab_idx == _e.active_index)
	_e.open_files.remove_at(tab_idx)
	_e.tab_bar.remove_tab(tab_idx)

	if _e.open_files.is_empty():
		_e.active_index = -1
		_e.suppress_tab = false
		open_untitled()
		return

	if closing_active:
		_e.active_index = clamp(tab_idx, 0, _e.open_files.size() - 1)
	elif tab_idx < _e.active_index:
		_e.active_index -= 1

	_e.active_index = clamp(_e.active_index, 0, _e.open_files.size() - 1)
	_e.tab_bar.current_tab = _e.active_index
	load_active_into_editor()
	_e.suppress_tab = false



func save_editor_state_to_active() -> void:
	if _e.active_index < 0 or _e.active_index >= _e.open_files.size():
		return
	var info: Dictionary = _e.open_files[_e.active_index]
	info["content"] = _e.code_edit.text
	info["cursor_line"] = _e.code_edit.get_caret_line()
	info["cursor_col"] = _e.code_edit.get_caret_column()



func on_code_changed() -> void:
	if _e.suppress_tab or _e.active_index < 0 or _e.active_index >= _e.open_files.size():
		return
	var info: Dictionary = _e.open_files[_e.active_index]
	if not bool(info.get("dirty", false)):
		info["dirty"] = true
		var t: String = str(info.get("title", "untitled"))
		_e.tab_bar.set_tab_title(_e.active_index, t + " •")
	_e.update_code_completion()



func on_caret_changed() -> void:
	update_cursor_status()



func update_cursor_status() -> void:
	var line: int = _e.code_edit.get_caret_line() + 1
	var col: int = _e.code_edit.get_caret_column() + 1
	_e.status_cursor.text = "Ln %d, Col %d   < Code Navigation Help" % [line, col]



func select_tab(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _e.open_files.size() or tab_idx == _e.active_index:
		return
	save_editor_state_to_active()
	_e.active_index = tab_idx
	_e.tab_bar.current_tab = tab_idx
	load_active_into_editor()



func switch_tab(offset: int) -> void:
	if _e.open_files.size() <= 1:
		return
	var new_idx: int = (_e.active_index + offset) % _e.open_files.size()
	if new_idx < 0:
		new_idx += _e.open_files.size()
	select_tab(new_idx)



func delete_selected_file() -> void:
	var item = _e.file_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if not (meta is Dictionary) or bool(meta.get("is_dir", false)):
		return
	var path = str(meta.get("path", ""))
	if path.is_empty() or not path.begins_with(_e.workspace_root.simplify_path() + "/"):
		return
	if DirAccess.remove_absolute(path) == OK:
		refresh_file_tree()
		_e.status_left.text = "DELETED: " + path.get_file()



func do_find(query: String) -> void:
	if query.is_empty():
		return
	var from_line: int = _e.code_edit.get_caret_line()
	var from_col: int = _e.code_edit.get_caret_column()
	var found: Vector2i = _e.code_edit.search(query, 0, from_line, from_col)
	if found.x < 0:
		found = _e.code_edit.search(query, 0, 0, 0)
	if found.x >= 0:
		_e.code_edit.set_caret_line(found.y)
		_e.code_edit.set_caret_column(found.x)
		_e.code_edit.select(found.y, found.x, found.y, found.x + query.length())



func on_find_next() -> void:
	do_find(_e.find_input.text)



func replace_all_matches() -> void:
	var query = _e.find_input.text
	if query.is_empty():
		return
	var old_text = _e.code_edit.text
	var new_text = old_text.replace(query, _e.replace_input.text)
	if new_text != old_text:
		_e.code_edit.text = new_text



func toggle_comment() -> void:
	var line: int = _e.code_edit.get_caret_line()
	var text: String = _e.code_edit.get_line(line)
	if text.strip_edges().begins_with("#"):
		_e.code_edit.set_line(line, text.replace("# ", "").replace("#", ""))
	else:
		_e.code_edit.set_line(line, "# " + text)



func duplicate_line() -> void:
	var line: int = _e.code_edit.get_caret_line()
	_e.code_edit.insert_line_at(line + 1, _e.code_edit.get_line(line))



func move_line(delta: int) -> void:
	var line: int = _e.code_edit.get_caret_line()
	var dest: int = line + delta
	if dest < 0 or dest >= _e.code_edit.get_line_count():
		return
	var a: String = _e.code_edit.get_line(line)
	var b: String = _e.code_edit.get_line(dest)
	_e.code_edit.set_line(line, b)
	_e.code_edit.set_line(dest, a)
	_e.code_edit.set_caret_line(dest)



func do_workspace_search(query: String) -> void:
	if _e.search_results_tree == null:
		return
	_e.search_results_tree.clear()
	var root = _e.search_results_tree.create_item()
	var q = query.strip_edges()
	if q.is_empty():
		if _e.search_summary_label:
			_e.search_summary_label.text = "0 results"
		return

	var match_case: bool = _e.search_match_case_btn.button_pressed if _e.search_match_case_btn else false
	var whole_word: bool = _e.search_whole_word_btn.button_pressed if _e.search_whole_word_btn else false
	var inc_pattern: String = _e.search_include_input.text.strip_edges() if _e.search_include_input else ""
	var exc_pattern: String = _e.search_exclude_input.text.strip_edges() if _e.search_exclude_input else ""

	var results: Dictionary = search_workspace_files(_e.workspace_root, q, match_case, whole_word, inc_pattern, exc_pattern)
	var total_matches: int = 0
	var total_files: int = results.size()

	for rel_path: String in results.keys():
		var file_matches: Array = results[rel_path]
		total_matches += file_matches.size()
		var full_p: String = _e.workspace_root.path_join(rel_path)

		var file_item = _e.search_results_tree.create_item(root)
		file_item.set_text(0, "%s (%d)" % [rel_path, file_matches.size()])
		var icon_tex: Texture2D = FileKind.texture_for_path(full_p, false, false)
		if icon_tex:
			file_item.set_icon(0, icon_tex)
			file_item.set_icon_max_width(0, 16)

		for match_info: Dictionary in file_matches:
			var line_num: int = int(match_info.get("line", 1))
			var col_num: int = int(match_info.get("col", 0))
			var snippet: String = str(match_info.get("snippet", ""))

			var item = _e.search_results_tree.create_item(file_item)
			item.set_text(0, "%d: %s" % [line_num, snippet])
			item.set_metadata(0, {
				"path": full_p,
				"line": line_num,
				"col": col_num,
				"length": q.length()
			})

	if _e.search_summary_label:
		_e.search_summary_label.text = "%d results in %d files" % [total_matches, total_files]



func search_workspace_files(base_dir: String, query: String, match_case: bool, whole_word: bool, inc_glob: String, exc_glob: String) -> Dictionary:
	var results: Dictionary = {}
	var files_to_scan: Array[String] = []
	collect_search_files_recursive(base_dir, base_dir, files_to_scan, inc_glob, exc_glob)

	for full_p: String in files_to_scan:
		var f = FileAccess.open(full_p, FileAccess.READ)
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
					if pos > 0 and is_ident_char(search_line[pos - 1]):
						is_word = false
					var end_pos: int = pos + search_q.length()
					if end_pos < search_line.length() and is_ident_char(search_line[end_pos]):
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



func collect_search_files_recursive(base_dir: String, current_dir: String, out_files: Array[String], inc_glob: String, exc_glob: String) -> void:
	var dir = DirAccess.open(current_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname not in [".", "..", ".git", ".godot", ".gemini", ".import", "android"]:
			var full_path: String = current_dir.path_join(fname)
			if dir.current_is_dir():
				collect_search_files_recursive(base_dir, full_path, out_files, inc_glob, exc_glob)
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



func is_ident_char(c: String) -> bool:
	return c.is_subsequence_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")



func on_search_result_activated() -> void:
	if _e.search_results_tree == null:
		return
	var item: TreeItem = _e.search_results_tree.get_selected()
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.has("path"):
		var full_p: String = str(meta.get("path", ""))
		var line_num: int = int(meta.get("line", 1)) - 1
		var col_num: int = int(meta.get("col", 0))
		var q_len: int = int(meta.get("length", 0))

		open_path(full_p)
		if _e.code_edit:
			_e.code_edit.set_caret_line(line_num)
			_e.code_edit.set_caret_column(col_num)
			if q_len > 0:
				_e.code_edit.select(line_num, col_num, line_num, col_num + q_len)
			_e.code_edit.center_viewport_to_caret()



func replace_in_workspace(search_q: String, replace_q: String) -> void:
	var q: String = search_q.strip_edges()
	if q.is_empty():
		return
	var match_case: bool = _e.search_match_case_btn.button_pressed if _e.search_match_case_btn else false
	var whole_word: bool = _e.search_whole_word_btn.button_pressed if _e.search_whole_word_btn else false
	var inc_pattern: String = _e.search_include_input.text.strip_edges() if _e.search_include_input else ""
	var exc_pattern: String = _e.search_exclude_input.text.strip_edges() if _e.search_exclude_input else ""

	var results: Dictionary = search_workspace_files(_e.workspace_root, q, match_case, whole_word, inc_pattern, exc_pattern)
	var replaced_files: int = 0
	var total_replaced: int = 0

	for rel_path: String in results.keys():
		var full_p: String = _e.workspace_root.path_join(rel_path)
		var f = FileAccess.open(full_p, FileAccess.READ)
		if not f:
			continue
		var content: String = f.get_as_text()
		f.close()

		var new_content: String = content.replace(q, replace_q)
		if new_content != content:
			var wf = FileAccess.open(full_p, FileAccess.WRITE)
			if wf:
				wf.store_string(new_content)
				wf.close()
				replaced_files += 1
				total_replaced += results[rel_path].size()

			for tab_idx in range(_e.open_files.size()):
				var info: Dictionary = _e.open_files[tab_idx]
				if str(info.get("path", "")) == full_p:
					info["content"] = new_content
					if _e.active_index == tab_idx and _e.code_edit:
						_e.code_edit.text = new_content

	_e.dialog.send_os_notification("Workspace Replace", "Replaced %d occurrences across %d files." % [total_replaced, replaced_files])
	do_workspace_search(q)



func get_workspace_files_list() -> Array[String]:
	var list: Array[String] = []
	if _e.workspace_root.is_empty():
		return list
	collect_files_recursive(_e.workspace_root, "", list)
	return list



func collect_files_recursive(base_path: String, rel_prefix: String, out_list: Array[String]) -> void:
	var dir = DirAccess.open(base_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_item_name = dir.get_next()
	while not file_item_name.is_empty():
		if file_item_name not in [".", "..", ".git", ".godot", ".gemini", "docs", "icons", "fonts", "test", "android", "build", "dist", "node_modules"]:
			var full_path = base_path.path_join(file_item_name)
			var rel_path = rel_prefix.path_join(file_item_name) if not rel_prefix.is_empty() else file_item_name
			if dir.current_is_dir():
				if out_list.size() < 120:
					collect_files_recursive(full_path, rel_path, out_list)
			else:
				out_list.append(rel_path)
		file_item_name = dir.get_next()
	dir.list_dir_end()



