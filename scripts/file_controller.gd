class_name FileController
extends RefCounted

## Owns file-tree population, tab management, and file open/save lifecycle.

const FileKind = preload("res://scripts/file_kind.gd")

var workspace_root: String = ""
var open_files: Array = []
var active_index: int = -1
var suppress_tab: bool = false

func populate_file_tree(tree: Tree, root_path: String) -> void:
	workspace_root = root_path
	tree.clear()
	var root_item: TreeItem = tree.create_item()
	var root_title := root_path.get_file()
	if root_title.is_empty():
		root_title = "WORKSPACE"
	root_item.set_text(0, root_title.to_upper())
	var folder_tex := FileKind.texture_for_path(root_path, true, true)
	if folder_tex:
		root_item.set_icon(0, folder_tex)
		root_item.set_icon_max_width(0, 16)
	root_item.set_custom_color(0, Color("#9cdcfe"))
	tree.set_column_title(0, "Files")
	_populate_tree_dir(tree, root_item, root_path)

func _populate_tree_dir(tree: Tree, parent_item: TreeItem, dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
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
		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(0, d)
		var item_path: String = dir_path.path_join(d)
		var folder_tex := FileKind.texture_for_path(item_path, true, false)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, Color("#9cdcfe"))
		item.set_metadata(0, {"path": item_path, "is_dir": true})
		item.collapsed = true
		_populate_tree_dir(tree, item, item_path)
	for f: String in files:
		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(0, f)
		var item_path: String = dir_path.path_join(f)
		var file_tex := FileKind.texture_for_path(item_path, false, false)
		if file_tex:
			item.set_icon(0, file_tex)
			item.set_icon_max_width(0, 16)
		item.set_custom_color(0, FileKind.color_for_path(f))
		item.set_metadata(0, {"path": item_path, "is_dir": false})

func on_tree_item_collapsed(item: TreeItem) -> void:
	if not item:
		return
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		var p: String = str(meta.get("path", ""))
		var folder_tex := FileKind.texture_for_path(p, true, not item.collapsed)
		if folder_tex:
			item.set_icon(0, folder_tex)
			item.set_icon_max_width(0, 16)

func on_tree_item_activated(tree: Tree) -> String:
	var item: TreeItem = tree.get_selected()
	if not item:
		return ""
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and not meta.get("is_dir", false):
		return str(meta.get("path", ""))
	return ""

func on_tree_item_selected(tree: Tree) -> bool:
	var item: TreeItem = tree.get_selected()
	if not item:
		return false
	var meta: Variant = item.get_metadata(0)
	if meta is Dictionary and meta.get("is_dir", false):
		item.collapsed = not item.collapsed
		return true
	return false

func open_untitled(tab_bar: TabBar) -> void:
	var info := {
		"path": "",
		"title": "untitled",
		"content": "",
		"dirty": false,
		"cursor_line": 0,
		"cursor_col": 0,
	}
	open_files.append(info)
	tab_bar.add_tab("untitled")
	active_index = open_files.size() - 1
	tab_bar.current_tab = active_index

func open_path(path: String, tab_bar: TabBar) -> bool:
	if path.is_empty():
		return false
	for i in range(open_files.size()):
		if open_files[i].get("path") == path:
			active_index = i
			tab_bar.current_tab = i
			return true
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return false
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
	open_files.append(info)
	tab_bar.add_tab(title)
	active_index = open_files.size() - 1
	tab_bar.current_tab = active_index
	return true

func load_active_into_editor(code_edit: CodeEdit, status_lang: Label, context_chip: Button) -> String:
	if active_index < 0 or active_index >= open_files.size():
		return ""
	suppress_tab = true
	var info: Dictionary = open_files[active_index]
	code_edit.text = str(info.get("content", ""))
	code_edit.set_caret_line(int(info.get("cursor_line", 0)))
	code_edit.set_caret_column(int(info.get("cursor_col", 0)))
	code_edit.clear_undo_history()
	suppress_tab = false
	var path: String = str(info.get("path", ""))
	if status_lang:
		status_lang.text = FileKind.label_for_path(path)
	if context_chip:
		context_chip.text = "+ " + (path.get_file() if not path.is_empty() else "Untitled")
	return path

func save_editor_state_to_active(code_edit: CodeEdit) -> void:
	if active_index < 0 or active_index >= open_files.size():
		return
	var info: Dictionary = open_files[active_index]
	info["content"] = code_edit.text
	info["cursor_line"] = code_edit.get_caret_line()
	info["cursor_col"] = code_edit.get_caret_column()

func save_active(tab_bar: TabBar) -> String:
	if active_index < 0 or active_index >= open_files.size():
		return ""
	var info: Dictionary = open_files[active_index]
	var path: String = str(info.get("path", ""))
	if path.is_empty():
		return ""
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return "ERR: Cannot save " + path.get_file()
	f.store_string(info["content"])
	info["dirty"] = false
	tab_bar.set_tab_title(active_index, info.get("title", ""))
	return "SAVED: " + path.get_file()

func save_as_path(path: String, tab_bar: TabBar, status_lang: Label) -> void:
	if active_index < 0 or active_index >= open_files.size():
		return
	var info: Dictionary = open_files[active_index]
	info["path"] = path
	info["title"] = path.get_file()
	suppress_tab = true
	info["content"] = info.get("content", "")
	suppress_tab = false
	if status_lang:
		status_lang.text = FileKind.label_for_path(path)

func on_tab_changed(tab_idx: int, code_edit: CodeEdit) -> void:
	if suppress_tab or tab_idx == active_index:
		return
	save_editor_state_to_active(code_edit)
	active_index = tab_idx

func on_tab_close(tab_idx: int, tab_bar: TabBar) -> void:
	if tab_idx < 0 or tab_idx >= open_files.size():
		return
	open_files.remove_at(tab_idx)
	tab_bar.remove_tab(tab_idx)
	if open_files.is_empty():
		open_untitled(tab_bar)
	else:
		active_index = clamp(active_index, 0, open_files.size() - 1)
		tab_bar.current_tab = active_index

func on_code_changed(tab_bar: TabBar, code_edit: CodeEdit) -> void:
	if suppress_tab or active_index < 0 or active_index >= open_files.size():
		return
	var info: Dictionary = open_files[active_index]
	if not bool(info.get("dirty", false)):
		info["dirty"] = true
		var t: String = str(info.get("title", "untitled"))
		tab_bar.set_tab_title(active_index, t + " •")

func reload_open_file(path: String) -> void:
	for i in open_files.size():
		if str(open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			var f := FileAccess.open(str(open_files[i].get("path", "")), FileAccess.READ)
			if f:
				open_files[i]["content"] = f.get_as_text()
				open_files[i]["dirty"] = false

func close_open_file_path(path: String, tab_bar: TabBar) -> void:
	for i in range(open_files.size() - 1, -1, -1):
		if str(open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			on_tab_close(i, tab_bar)

func get_workspace_files_list() -> Array[String]:
	var list: Array[String] = []
	if workspace_root.is_empty():
		return list
	_collect_files_recursive(workspace_root, "", list)
	return list

func _collect_files_recursive(base_path: String, rel_prefix: String, out_list: Array[String]) -> void:
	var dir := DirAccess.open(base_path)
	if not dir:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if fname not in [".", "..", ".git", ".godot", "android", ".gemini"]:
			var full_path := base_path.path_join(fname)
			var rel_path := rel_prefix.path_join(fname) if not rel_prefix.is_empty() else fname
			if dir.current_is_dir():
				if out_list.size() < 120:
					_collect_files_recursive(full_path, rel_path, out_list)
			else:
				out_list.append(rel_path)
		fname = dir.get_next()
	dir.list_dir_end()
