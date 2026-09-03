class_name AgentWorkspaceService
extends RefCounted

## Safely executes the file-operation markup emitted by the embedded Agent.


static func execute_markup(reply: String, workspace_root: String) -> Dictionary:
	var root := workspace_root.simplify_path()
	var report := ""
	var written_paths: Array[String] = []
	var deleted_paths: Array[String] = []
	var write_regex := RegEx.new()
	write_regex.compile("(?s)<sscode-write\\s+path=\\\"([^\\\"]+)\\\">(.*?)</sscode-write>")

	for match: RegExMatch in write_regex.search_all(reply):
		var relative := match.get_string(1).strip_edges().replace("\\", "/")
		var target := _safe_path(root, relative)
		if target.is_empty():
			report += "\n[color=#ed333b]Rejected unsafe path: %s[/color]" % relative
			continue
		var parent := target.get_base_dir()
		if not DirAccess.dir_exists_absolute(parent):
			DirAccess.make_dir_recursive_absolute(parent)
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			report += "\n[color=#ed333b]Could not write: %s[/color]" % relative
			continue
		file.store_string(match.get_string(2).trim_prefix("\n"))
		file.close()
		written_paths.append(target)
		report += "\n[color=#57e389]Written: %s[/color]" % relative

	var delete_regex := RegEx.new()
	delete_regex.compile("<sscode-delete\\s+path=\\\"([^\\\"]+)\\\"\\s*/?>")
	for match: RegExMatch in delete_regex.search_all(reply):
		var relative := match.get_string(1).strip_edges().replace("\\", "/")
		var target := _safe_path(root, relative)
		if target.is_empty():
			report += "\n[color=#ed333b]Rejected unsafe delete path: %s[/color]" % relative
		elif FileAccess.file_exists(target) and DirAccess.remove_absolute(target) == OK:
			deleted_paths.append(target)
			report += "\n[color=#57e389]Deleted: %s[/color]" % relative
		else:
			report += "\n[color=#ed333b]Could not delete: %s[/color]" % relative

	var visible_reply := delete_regex.sub(write_regex.sub(reply, "", true), "", true).strip_edges()
	return {
		"reply": visible_reply,
		"report": report,
		"written_paths": written_paths,
		"deleted_paths": deleted_paths,
	}


static func _safe_path(root: String, relative: String) -> String:
	if relative.is_empty() or relative.begins_with("/") or relative.contains(".."):
		return ""
	var target := root.path_join(relative).simplify_path()
	return target if target.begins_with(root + "/") else ""
