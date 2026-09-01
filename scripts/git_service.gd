class_name GitService
extends RefCounted

## GitService — Native GDScript Git and GitHub Integration Service
## Provides workspace Git version control, branch management, diffs, commits,
## and GitHub repository synchronisation (pull, push, fetch, remotes, clone).


static func execute(args: PackedStringArray, working_dir: String = "") -> Dictionary:
	var final_args: PackedStringArray = PackedStringArray()
	if not working_dir.is_empty():
		final_args.append("-C")
		final_args.append(working_dir)
	final_args.append_array(args)
	
	var output: Array = []
	var exit_code: int = OS.execute("git", final_args, output, true)
	var out_text: String = output[0] if output.size() > 0 else ""
	return {
		"exit_code": exit_code,
		"output": out_text,
		"error": out_text if exit_code != 0 else "",
		"success": exit_code == 0,
	}


static func is_git_repository(working_dir: String = "") -> bool:
	var res: Dictionary = execute(PackedStringArray(["rev-parse", "--is-inside-work-tree"]), working_dir)
	return bool(res.get("success", false)) and str(res.get("output", "")).strip_edges() == "true"


static func get_current_branch(working_dir: String = "") -> String:
	var res: Dictionary = execute(PackedStringArray(["branch", "--show-current"]), working_dir)
	var branch: String = str(res.get("output", "")).strip_edges()
	if branch.is_empty():
		var head_res: Dictionary = execute(PackedStringArray(["rev-parse", "--short", "HEAD"]), working_dir)
		branch = str(head_res.get("output", "")).strip_edges()
		if not branch.is_empty():
			branch = "HEAD (" + branch + ")"
	return branch if not branch.is_empty() else "main"


static func get_branches(working_dir: String = "") -> Array[Dictionary]:
	var branches: Array[Dictionary] = []
	var res: Dictionary = execute(PackedStringArray(["branch", "-a", "--no-color"]), working_dir)
	if not bool(res.get("success", false)):
		return branches
	
	var lines: PackedStringArray = str(res.get("output", "")).split("\n", false)
	for raw_line: String in lines:
		var line: String = raw_line.strip_edges()
		if line.is_empty():
			continue
		var is_current: bool = raw_line.begins_with("*")
		var clean_name: String = line.trim_prefix("*").strip_edges()
		var is_remote: bool = clean_name.begins_with("remotes/")
		var display_name: String = clean_name
		if is_remote:
			display_name = clean_name.trim_prefix("remotes/")
		
		# Skip symbolic HEAD pointers
		if clean_name.contains(" -> "):
			continue
			
		branches.append({
			"name": clean_name,
			"display_name": display_name,
			"is_current": is_current,
			"is_remote": is_remote,
		})
	return branches


static func get_status(working_dir: String = "") -> Dictionary:
	var result: Dictionary = {
		"branch": get_current_branch(working_dir),
		"ahead": 0,
		"behind": 0,
		"is_clean": true,
		"staged": [] as Array[String],
		"unstaged": [] as Array[String],
		"untracked": [] as Array[String],
		"raw_output": "",
	}
	
	var res: Dictionary = execute(PackedStringArray(["status", "--porcelain=v1", "-b"]), working_dir)
	if not bool(res.get("success", false)):
		return result
		
	var raw_out: String = str(res.get("output", ""))
	result["raw_output"] = raw_out
	var lines: PackedStringArray = raw_out.split("\n", false)
	
	for i in range(lines.size()):
		var line: String = lines[i]
		if i == 0 and line.begins_with("##"):
			# Parse branch header, e.g. ## main...origin/main [ahead 1, behind 2]
			if line.contains("[ahead "):
				var ahead_part: String = line.substr(line.find("[ahead ") + 7)
				result["ahead"] = ahead_part.to_int()
			if line.contains("behind "):
				var behind_part: String = line.substr(line.find("behind ") + 7)
				result["behind"] = behind_part.to_int()
			continue
			
		if line.length() < 3:
			continue
			
		var index_code: String = line.substr(0, 1)
		var worktree_code: String = line.substr(1, 1)
		var file_path: String = line.substr(3).strip_edges()
		
		if index_code == "?" and worktree_code == "?":
			(result["untracked"] as Array[String]).append(file_path)
			result["is_clean"] = false
		else:
			if index_code in ["M", "A", "D", "R", "C"]:
				(result["staged"] as Array[String]).append(file_path)
				result["is_clean"] = false
			if worktree_code in ["M", "D"]:
				(result["unstaged"] as Array[String]).append(file_path)
				result["is_clean"] = false
				
	return result


static func get_remotes(working_dir: String = "") -> Array[Dictionary]:
	var remotes: Array[Dictionary] = []
	var res: Dictionary = execute(PackedStringArray(["remote", "-v"]), working_dir)
	if not bool(res.get("success", false)):
		return remotes
		
	var lines: PackedStringArray = str(res.get("output", "")).split("\n", false)
	var seen: Dictionary = {}
	for line in lines:
		var parts: PackedStringArray = line.strip_edges().split("\t", false)
		if parts.size() >= 2:
			var r_name: String = parts[0]
			var url_and_type: PackedStringArray = parts[1].split(" ", false)
			var r_url: String = url_and_type[0]
			var r_type: String = url_and_type[1].replace("(", "").replace(")", "") if url_and_type.size() > 1 else "fetch"
			
			if not seen.has(r_name + "_" + r_type):
				seen[r_name + "_" + r_type] = true
				remotes.append({
					"name": r_name,
					"url": r_url,
					"type": r_type,
				})
	return remotes


static func get_remote_url(remote_name: String = "origin", working_dir: String = "") -> String:
	var res: Dictionary = execute(PackedStringArray(["remote", "get-url", remote_name]), working_dir)
	if bool(res.get("success", false)):
		return str(res.get("output", "")).strip_edges()
	var all_remotes: Array[Dictionary] = get_remotes(working_dir)
	for r: Dictionary in all_remotes:
		if str(r.get("name", "")) == remote_name:
			return str(r.get("url", ""))
	return ""


static func set_remote_url(remote_name: String, url: String, working_dir: String = "") -> Dictionary:
	var remotes: Array[Dictionary] = get_remotes(working_dir)
	var exists: bool = false
	for r: Dictionary in remotes:
		if str(r.get("name", "")) == remote_name:
			exists = true
			break
	if exists:
		return execute(PackedStringArray(["remote", "set-url", remote_name, url]), working_dir)
	else:
		return execute(PackedStringArray(["remote", "add", remote_name, url]), working_dir)


static func add_remote(remote_name: String, url: String, working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["remote", "add", remote_name, url]), working_dir)


static func parse_github_url(raw_url: String) -> Dictionary:
	var result: Dictionary = {
		"is_github": false,
		"owner": "",
		"repo": "",
		"full_name": "",
		"web_url": "",
		"commits_url": "",
		"pulls_url": "",
		"issues_url": "",
		"branches_url": "",
	}
	var clean: String = raw_url.strip_edges()
	if clean.is_empty():
		return result
		
	var path_part: String = ""
	if clean.begins_with("git@github.com:"):
		# SSH: git@github.com:owner/repo.git
		path_part = clean.trim_prefix("git@github.com:")
	elif clean.contains("github.com/"):
		# HTTPS or SSH URL: https://github.com/owner/repo.git or https://token@github.com/owner/repo.git
		var idx: int = clean.find("github.com/")
		path_part = clean.substr(idx + 11)
	elif clean.contains("github.com:"):
		var idx: int = clean.find("github.com:")
		path_part = clean.substr(idx + 11)
		
	if path_part.is_empty():
		return result
		
	path_part = path_part.trim_suffix(".git").strip_edges()
	var segments: PackedStringArray = path_part.split("/", false)
	if segments.size() >= 2:
		var owner: String = segments[0]
		var repo: String = segments[1]
		var full_name: String = owner + "/" + repo
		var web_url: String = "https://github.com/" + full_name
		result["is_github"] = true
		result["owner"] = owner
		result["repo"] = repo
		result["full_name"] = full_name
		result["web_url"] = web_url
		result["commits_url"] = web_url + "/commits"
		result["pulls_url"] = web_url + "/pulls"
		result["issues_url"] = web_url + "/issues"
		result["branches_url"] = web_url + "/branches"
		
	return result


static func get_github_info(working_dir: String = "") -> Dictionary:
	var origin_url: String = get_remote_url("origin", working_dir)
	var info: Dictionary = parse_github_url(origin_url)
	info["remote_url"] = origin_url
	info["current_branch"] = get_current_branch(working_dir)
	return info


static func get_diff(file_path: String = "", staged: bool = false, working_dir: String = "") -> Dictionary:
	var args: PackedStringArray = PackedStringArray(["diff"])
	if staged:
		args.append("--staged")
	if not file_path.is_empty():
		args.append("--")
		args.append(file_path)
	return execute(args, working_dir)


static func get_diff_stat(working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["diff", "--stat"]), working_dir)


static func get_log(max_count: int = 15, working_dir: String = "") -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var res: Dictionary = execute(PackedStringArray([
		"log",
		"-n", str(max_count),
		"--pretty=format:%h|%an|%ad|%s",
		"--date=short"
	]), working_dir)
	
	if not bool(res.get("success", false)):
		return entries
		
	var lines: PackedStringArray = str(res.get("output", "")).split("\n", false)
	for line in lines:
		var parts: PackedStringArray = line.split("|", false, 3)
		if parts.size() == 4:
			entries.append({
				"hash": parts[0].strip_edges(),
				"author": parts[1].strip_edges(),
				"date": parts[2].strip_edges(),
				"message": parts[3].strip_edges(),
			})
	return entries


static func stage_all(working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["add", "-A"]), working_dir)


static func stage_files(files: PackedStringArray, working_dir: String = "") -> Dictionary:
	var args: PackedStringArray = PackedStringArray(["add"])
	args.append_array(files)
	return execute(args, working_dir)


static func unstage_files(files: PackedStringArray, working_dir: String = "") -> Dictionary:
	var args: PackedStringArray = PackedStringArray(["restore", "--staged"])
	args.append_array(files)
	return execute(args, working_dir)


static func discard_changes(file_path: String, working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["restore", file_path]), working_dir)


static func commit(message: String, working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["commit", "-m", message]), working_dir)


static func smart_commit(custom_scope: String = "", working_dir: String = "") -> Dictionary:
	var status: Dictionary = get_status(working_dir)
	var staged: Array = status.get("staged", [])
	var unstaged: Array = status.get("unstaged", [])
	var untracked: Array = status.get("untracked", [])
	
	var total_changes: int = staged.size() + unstaged.size() + untracked.size()
	if total_changes == 0:
		return {
			"success": false,
			"error": "Working tree is clean. No changes to commit.",
			"message": "",
		}
		
	# Stage all changes
	var stage_res: Dictionary = stage_all(working_dir)
	if not bool(stage_res.get("success", false)):
		return stage_res
		
	# Determine scope and message
	var scope: String = custom_scope if not custom_scope.is_empty() else "workspace"
	var all_modified: Array[String] = []
	for f in staged:
		all_modified.append(str(f))
	for f in unstaged:
		all_modified.append(str(f))
	for f in untracked:
		all_modified.append(str(f))
	
	if custom_scope.is_empty() and not all_modified.is_empty():
		var first_file: String = all_modified[0]
		if first_file.begins_with("scripts/"):
			scope = first_file.get_file().get_basename()
		elif first_file.begins_with("scene/"):
			scope = "ui"
		elif first_file.begins_with("test/"):
			scope = "test"
		elif first_file.ends_with(".md"):
			scope = "docs"
			
	var file_sample: String = ", ".join(all_modified.slice(0, 3))
	var summary_msg: String = "feat(%s): update %s" % [scope, file_sample]
	if all_modified.size() > 3:
		summary_msg += " and %d more files" % (all_modified.size() - 3)
		
	var commit_res: Dictionary = commit(summary_msg, working_dir)
	commit_res["message"] = summary_msg
	commit_res["modified_files"] = all_modified
	return commit_res


static func push(remote: String = "origin", branch: String = "", set_upstream: bool = true, working_dir: String = "") -> Dictionary:
	var target_branch: String = branch
	if target_branch.is_empty():
		target_branch = get_current_branch(working_dir)
	if target_branch.begins_with("HEAD ("):
		target_branch = "main"
		
	var args: PackedStringArray = PackedStringArray(["push"])
	if set_upstream:
		args.append("-u")
	args.append(remote)
	args.append(target_branch)
	return execute(args, working_dir)


static func pull(remote: String = "origin", branch: String = "", rebase: bool = false, working_dir: String = "") -> Dictionary:
	var target_branch: String = branch
	if target_branch.is_empty():
		target_branch = get_current_branch(working_dir)
	if target_branch.begins_with("HEAD ("):
		target_branch = "main"
		
	var args: PackedStringArray = PackedStringArray(["pull"])
	if rebase:
		args.append("--rebase")
	args.append(remote)
	args.append(target_branch)
	return execute(args, working_dir)


static func fetch(remote: String = "origin", working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["fetch", remote]), working_dir)


static func sync(remote: String = "origin", branch: String = "", working_dir: String = "") -> Dictionary:
	var pull_res: Dictionary = pull(remote, branch, false, working_dir)
	if not bool(pull_res.get("success", false)):
		return {
			"success": false,
			"error": "Git pull failed during sync:\n" + str(pull_res.get("output", "")),
			"stage": "pull",
		}
	var push_res: Dictionary = push(remote, branch, true, working_dir)
	if not bool(push_res.get("success", false)):
		return {
			"success": false,
			"error": "Git push failed during sync:\n" + str(push_res.get("output", "")),
			"stage": "push",
		}
	return {
		"success": true,
		"output": "Synchronisation with %s/%s completed successfully." % [remote, branch if not branch.is_empty() else get_current_branch(working_dir)],
		"stage": "complete",
	}


static func checkout_branch(branch_name: String, create_new: bool = false, working_dir: String = "") -> Dictionary:
	if create_new:
		return execute(PackedStringArray(["checkout", "-b", branch_name]), working_dir)
	return execute(PackedStringArray(["checkout", branch_name]), working_dir)


static func create_branch(branch_name: String, working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["branch", branch_name]), working_dir)


static func delete_branch(branch_name: String, force: bool = false, working_dir: String = "") -> Dictionary:
	var flag: String = "-D" if force else "-d"
	return execute(PackedStringArray(["branch", flag, branch_name]), working_dir)


static func clone_repository(repo_url: String, target_dir: String) -> Dictionary:
	return execute(PackedStringArray(["clone", repo_url, target_dir]))


static func init_repository(working_dir: String = "") -> Dictionary:
	return execute(PackedStringArray(["init"]), working_dir)


static func get_user_config(working_dir: String = "") -> Dictionary:
	var name_res: Dictionary = execute(PackedStringArray(["config", "user.name"]), working_dir)
	var email_res: Dictionary = execute(PackedStringArray(["config", "user.email"]), working_dir)
	return {
		"name": str(name_res.get("output", "")).strip_edges(),
		"email": str(email_res.get("output", "")).strip_edges(),
	}


static func set_user_config(name: String, email: String, global_scope: bool = false, working_dir: String = "") -> Dictionary:
	var scope_flag: String = "--global" if global_scope else "--local"
	var name_res: Dictionary = execute(PackedStringArray(["config", scope_flag, "user.name", name]), working_dir)
	var email_res: Dictionary = execute(PackedStringArray(["config", scope_flag, "user.email", email]), working_dir)
	return {
		"success": bool(name_res.get("success", false)) and bool(email_res.get("success", false)),
		"name": name,
		"email": email,
	}


static func configure_github_token(token: String, remote_name: String = "origin", working_dir: String = "") -> Dictionary:
	var current_url: String = get_remote_url(remote_name, working_dir)
	var gh_info: Dictionary = parse_github_url(current_url)
	if not bool(gh_info.get("is_github", false)):
		return {
			"success": false,
			"error": "The remote '%s' is not recognised as a GitHub repository URL: %s" % [remote_name, current_url],
		}
	var new_url: String = "https://x-access-token:%s@github.com/%s.git" % [token, str(gh_info.get("full_name", ""))]
	return set_remote_url(remote_name, new_url, working_dir)


static func format_status_bbcode(status: Dictionary, gh_info: Dictionary = {}) -> String:
	var branch: String = str(status.get("branch", "main"))
	var is_clean: bool = bool(status.get("is_clean", true))
	var ahead: int = int(status.get("ahead", 0))
	var behind: int = int(status.get("behind", 0))
	var staged: Array = status.get("staged", [])
	var unstaged: Array = status.get("unstaged", [])
	var untracked: Array = status.get("untracked", [])
	
	var out: String = "[b][color=#62a0ea]Git Repository Status[/color][/b]\n\n"
	out += "[color=#9a9996]Branch:[/color] [color=#57e389]⎇ %s[/color]" % branch
	if ahead > 0 or behind > 0:
		out += " [color=#ffa348](ahead %d, behind %d)[/color]" % [ahead, behind]
	out += "\n"
	
	if bool(gh_info.get("is_github", false)):
		out += "[color=#9a9996]GitHub Remote:[/color] [color=#62a0ea]%s[/color]\n" % str(gh_info.get("full_name", ""))
		out += "[color=#9a9996]Repository URL:[/color] [color=#3584e4]%s[/color]\n" % str(gh_info.get("web_url", ""))
	
	out += "\n"
	if is_clean:
		out += "[bgcolor=#1e1e24][color=#57e389]✔ Working tree clean. Nothing to commit.[/color][/bgcolor]\n"
	else:
		if not staged.is_empty():
			out += "[b][color=#57e389]Changes Staged for Commit (%d):[/color][/b]\n" % staged.size()
			for f in staged:
				out += "  [color=#57e389]+ %s[/color]\n" % str(f)
			out += "\n"
		if not unstaged.is_empty():
			out += "[b][color=#ffa348]Changes Not Staged for Commit (%d):[/color][/b]\n" % unstaged.size()
			for f in unstaged:
				out += "  [color=#ffa348]~ %s[/color]\n" % str(f)
			out += "\n"
		if not untracked.is_empty():
			out += "[b][color=#ed333b]Untracked Files (%d):[/color][/b]\n" % untracked.size()
			for f in untracked:
				out += "  [color=#ed333b]? %s[/color]\n" % str(f)
			out += "\n"
	return out


static func format_log_bbcode(log_entries: Array[Dictionary]) -> String:
	if log_entries.is_empty():
		return "[color=#9a9996]No commit history available.[/color]"
	var out: String = "[b][color=#62a0ea]Git Commit History[/color][/b]\n\n"
	for entry in log_entries:
		var h: String = str(entry.get("hash", ""))
		var a: String = str(entry.get("author", ""))
		var d: String = str(entry.get("date", ""))
		var m: String = str(entry.get("message", ""))
		out += "[bgcolor=#1e1e24][color=#ffa348]%s[/color] [color=#9a9996]%s[/color] [color=#62a0ea](%s)[/color][/bgcolor]\n" % [h, d, a]
		out += "  [color=#deddda]%s[/color]\n\n" % m
	return out


static func format_diff_bbcode(diff_text: String) -> String:
	var clean: String = diff_text.strip_edges()
	if clean.is_empty():
		return "[color=#57e389]No diffs found. Working tree clean.[/color]"
	return "```diff\n" + clean + "\n```"
