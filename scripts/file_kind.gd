class_name FileKind
extends RefCounted

## Maps paths to LazyVim / nvim-web-devicons glyphs, colors, and editor language labels.

enum Kind {
	DIRECTORY,
	SCRIPT,
	SCENE,
	IMAGE,
	AUDIO,
	VIDEO,
	ARCHIVE,
	CONFIG,
	DOCUMENT,
	FILE,
}


static func kind_for(path: String, is_dir: bool) -> Kind:
	if is_dir:
		return Kind.DIRECTORY
	var ext: String = path.get_extension().to_lower()
	match ext:
		"gd", "py", "js", "ts", "tsx", "jsx", "c", "h", "cc", "cpp", "hpp", "rs", "go", "java", "kt", "sh", "bash", "zsh", "lua", "rb":
			return Kind.SCRIPT
		"tscn", "scn", "res", "tres":
			return Kind.SCENE
		"png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "ico":
			return Kind.IMAGE
		"wav", "mp3", "ogg", "flac":
			return Kind.AUDIO
		"mp4", "webm", "ogv", "mkv":
			return Kind.VIDEO
		"zip", "tar", "gz", "tgz", "7z", "rar":
			return Kind.ARCHIVE
		"json", "cfg", "ini", "toml", "yaml", "yml", "godot", "import", "xml":
			return Kind.CONFIG
		"md", "txt", "rst", "pdf", "doc", "docx", "rtf":
			return Kind.DOCUMENT
		_:
			return Kind.FILE


static func icon_for_path(path: String, is_dir: bool = false) -> String:
	if is_dir:
		return ""
	var fname: String = path.get_file().to_lower()
	var ext: String = path.get_extension().to_lower()

	# Exact filename match (LazyVim / Devicons)
	match fname:
		".gitignore", ".gitmodules", ".gitattributes":
			return ""
		"package.json", "package-lock.json":
			return ""
		"cargo.toml", "cargo.lock":
			return ""
		"go.mod", "go.sum":
			return ""
		"dockerfile", "docker-compose.yml", "docker-compose.yaml":
			return "󰡨"
		"makefile", "gnumakefile":
			return ""
		"readme.md", "license", "licence":
			return ""
		"project.godot":
			return ""

	# Extension match
	match ext:
		"gd":
			return ""
		"tscn", "scn", "tres", "res":
			return "󰒃"
		"py", "pyw", "ipynb":
			return ""
		"js", "mjs", "cjs":
			return ""
		"ts":
			return ""
		"tsx", "jsx":
			return ""
		"c", "h":
			return ""
		"cpp", "cc", "cxx", "hpp", "hxx":
			return ""
		"rs":
			return ""
		"go":
			return ""
		"sh", "bash", "zsh", "fish":
			return ""
		"json":
			return ""
		"yaml", "yml":
			return ""
		"toml", "ini", "cfg", "conf":
			return ""
		"md", "markdown":
			return ""
		"txt", "log":
			return ""
		"html", "htm":
			return ""
		"css", "scss", "sass", "less":
			return ""
		"lua":
			return ""
		"rb":
			return ""
		"java", "jar":
			return ""
		"png", "jpg", "jpeg", "webp", "gif", "svg", "ico":
			return "󰈟"
		"wav", "mp3", "ogg", "flac":
			return "󰎆"
		"mp4", "webm", "mkv", "avi":
			return "󰕼"
		"zip", "tar", "gz", "tgz", "7z", "rar":
			return ""
		_:
			return ""


static func color_for_path(path: String, is_dir: bool = false) -> Color:
	if is_dir:
		return Color("#62a0ea") # Adwaita folder blue
	var fname: String = path.get_file().to_lower()
	var ext: String = path.get_extension().to_lower()

	if fname.begins_with(".git"):
		return Color("#f05032")
	if fname.begins_with("package"):
		return Color("#cb3837")
	if fname == "makefile":
		return Color("#ffa348")

	match ext:
		"py", "pyw":
			return Color("#599eff")
		"js", "mjs":
			return Color("#f7df1e")
		"ts":
			return Color("#3178c6")
		"tsx", "jsx":
			return Color("#61dafb")
		"c", "h":
			return Color("#62a0ea")
		"cpp", "cc", "hpp":
			return Color("#5bc8af")
		"rs":
			return Color("#ffa348")
		"go":
			return Color("#00add8")
		"gd", "tscn", "tres":
			return Color("#478cbf")
		"json":
			return Color("#cbcb41")
		"sh", "bash", "zsh", "fish":
			return Color("#57e389")
		"md", "txt":
			return Color("#99c1f1")
		"yaml", "yml", "toml", "cfg", "ini":
			return Color("#dc8add")
		"html":
			return Color("#e34f26")
		"css", "scss":
			return Color("#1572b6")
		"png", "jpg", "jpeg", "svg", "webp":
			return Color("#dc8add")
		_:
			return Color("#deddda")


static func label_for_path(path: String) -> String:
	if path.is_empty():
		return "Plain Text"
	var ext: String = path.get_extension().to_lower()
	match ext:
		"gd":
			return "GDScript"
		"py":
			return "Python"
		"js":
			return "JavaScript"
		"ts":
			return "TypeScript"
		"tsx", "jsx":
			return "React"
		"c", "h":
			return "C"
		"cpp", "cc", "hpp":
			return "C++"
		"rs":
			return "Rust"
		"go":
			return "Go"
		"java":
			return "Java"
		"kt":
			return "Kotlin"
		"sh", "bash", "zsh", "fish":
			return "Shell"
		"lua":
			return "Lua"
		"rb":
			return "Ruby"
		"tscn", "scn":
			return "Godot Scene"
		"res", "tres":
			return "Godot Resource"
		"json":
			return "JSON"
		"cfg", "ini":
			return "Config"
		"toml":
			return "TOML"
		"yaml", "yml":
			return "YAML"
		"xml":
			return "XML"
		"html", "htm":
			return "HTML"
		"css":
			return "CSS"
		"md":
			return "Markdown"
		"txt":
			return "Text"
		_:
			return ext.to_upper() if not ext.is_empty() else "Plain Text"
