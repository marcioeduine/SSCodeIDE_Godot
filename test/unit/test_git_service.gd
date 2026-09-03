extends GutTest

## Unit tests for GitService covering git repository detection, status parsing,
## branches, remotes, GitHub URL parsing, commit generation, and formatting.


func test_git_service_script_loads() -> void:
	var scr: Script = load("res://scripts/git_service.gd")
	assert_not_null(scr, "GitService script should load cleanly")


func test_is_git_repository_current_workspace() -> void:
	var is_repo: bool = GitService.is_git_repository()
	assert_true(is_repo, "Current project directory should be recognised as a Git repository")


func test_get_current_branch() -> void:
	var branch: String = GitService.get_current_branch()
	assert_gt(branch.length(), 0, "Current branch should not be empty")
	assert_false(branch.is_empty())


func test_get_branches_list() -> void:
	var branches: Array[Dictionary] = GitService.get_branches()
	assert_gt(branches.size(), 0, "Should find at least one branch")
	var has_current: bool = false
	for b in branches:
		if bool(b.get("is_current", false)):
			has_current = true
			break
	assert_true(has_current, "At least one branch should be marked current")


func test_get_status_structure() -> void:
	var status: Dictionary = GitService.get_status()
	assert_has(status, "branch")
	assert_has(status, "is_clean")
	assert_has(status, "staged")
	assert_has(status, "unstaged")
	assert_has(status, "untracked")


func test_get_remotes_and_remote_url() -> void:
	var remotes: Array[Dictionary] = GitService.get_remotes()
	assert_gt(remotes.size(), 0, "Should have at least one remote configured")
	
	var origin_url: String = GitService.get_remote_url("origin")
	assert_true(origin_url.contains("github.com"), "Origin URL should point to GitHub: " + origin_url)


func test_parse_github_url_ssh() -> void:
	var ssh_url: String = "git@github.com:marcioeduine/ss_code_ide_godot.git"
	var info: Dictionary = GitService.parse_github_url(ssh_url)
	assert_true(bool(info.get("is_github", false)))
	assert_eq(str(info.get("owner", "")), "marcioeduine")
	assert_eq(str(info.get("repo", "")), "ss_code_ide_godot")
	assert_eq(str(info.get("full_name", "")), "marcioeduine/ss_code_ide_godot")
	assert_eq(str(info.get("web_url", "")), "https://github.com/marcioeduine/ss_code_ide_godot")
	assert_eq(str(info.get("commits_url", "")), "https://github.com/marcioeduine/ss_code_ide_godot/commits")
	assert_eq(str(info.get("pulls_url", "")), "https://github.com/marcioeduine/ss_code_ide_godot/pulls")
	assert_eq(str(info.get("issues_url", "")), "https://github.com/marcioeduine/ss_code_ide_godot/issues")


func test_parse_github_url_https() -> void:
	var https_url: String = "https://github.com/marcioeduine/ss_code_ide_godot.git"
	var info: Dictionary = GitService.parse_github_url(https_url)
	assert_true(bool(info.get("is_github", false)))
	assert_eq(str(info.get("owner", "")), "marcioeduine")
	assert_eq(str(info.get("repo", "")), "ss_code_ide_godot")
	assert_eq(str(info.get("full_name", "")), "marcioeduine/ss_code_ide_godot")
	assert_eq(str(info.get("web_url", "")), "https://github.com/marcioeduine/ss_code_ide_godot")


func test_parse_github_url_invalid() -> void:
	var invalid_url: String = "https://gitlab.com/other/project.git"
	var info: Dictionary = GitService.parse_github_url(invalid_url)
	assert_false(bool(info.get("is_github", false)))


func test_get_github_info() -> void:
	var gh_info: Dictionary = GitService.get_github_info()
	assert_true(bool(gh_info.get("is_github", false)))
	assert_eq(str(gh_info.get("owner", "")).to_lower(), "marcioeduine")
	assert_true(str(gh_info.get("repo", "")).to_lower() in ["ss_code_ide_godot", "sscodeide_godot"])


func test_get_commit_history() -> void:
	var log_entries: Array[Dictionary] = GitService.get_log(5)
	assert_gt(log_entries.size(), 0, "Should have recent commits")
	var first_entry: Dictionary = log_entries[0]
	assert_has(first_entry, "hash")
	assert_has(first_entry, "author")
	assert_has(first_entry, "date")
	assert_has(first_entry, "message")


func test_compose_commit_message_scripts_scope() -> void:
	var msg: String = GitService.compose_commit_message(["scripts/ui_editor.gd", "scripts/ai_service.gd"])
	assert_eq(msg, "feat(ui_editor): update scripts/ui_editor.gd, scripts/ai_service.gd")


func test_compose_commit_message_docs_and_truncation() -> void:
	var msg: String = GitService.compose_commit_message([
		"README.md",
		"docs/user-guide.md",
		"docs/architecture.md",
		"docs/development.md",
	])
	assert_eq(msg, "feat(docs): update README.md, docs/user-guide.md, docs/architecture.md and 1 more files")


func test_compose_commit_message_empty_paths() -> void:
	var msg: String = GitService.compose_commit_message([])
	assert_eq(msg, "chore(workspace): update files")


func test_bbcode_formatters() -> void:
	var mock_status: Dictionary = {
		"branch": "main",
		"is_clean": false,
		"ahead": 1,
		"behind": 0,
		"staged": ["scripts/git_service.gd"],
		"unstaged": ["README.md"],
		"untracked": ["new_file.txt"],
	}
	var mock_gh: Dictionary = {
		"is_github": true,
		"full_name": "marcioeduine/ss_code_ide_godot",
		"web_url": "https://github.com/marcioeduine/ss_code_ide_godot",
	}
	var formatted_status: String = GitService.format_status_bbcode(mock_status, mock_gh)
	assert_true(formatted_status.contains("Git Repository Status"))
	assert_true(formatted_status.contains("marcioeduine/ss_code_ide_godot"))
	assert_true(formatted_status.contains("Changes Staged for Commit"))
	assert_true(formatted_status.contains("Changes Not Staged for Commit"))
	assert_true(formatted_status.contains("Untracked Files"))
	
	var mock_log: Array[Dictionary] = [
		{"hash": "abc1234", "author": "Developer", "date": "2026-09-01", "message": "feat: add git service"}
	]
	var formatted_log: String = GitService.format_log_bbcode(mock_log)
	assert_true(formatted_log.contains("Git Commit History"))
	assert_true(formatted_log.contains("abc1234"))
	assert_true(formatted_log.contains("feat: add git service"))
	
	var formatted_diff: String = GitService.format_diff_bbcode("diff --git a/test.gd b/test.gd\n+line")
	assert_true(formatted_diff.contains("```diff"))
