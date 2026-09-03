class_name FileKind
extends RefCounted

## Manages VS Code / Material-style file icons, textures, colors, and language labels.

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

static var _texture_cache: Dictionary = {}

const SVG_ICONS: Dictionary = {
	"folder": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#62a0ea" d="M1.5 2A1.5 1.5 0 0 0 0 3.5v9A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5v-7A1.5 1.5 0 0 0 14.5 4H7.414L5.707 2.293A1 1 0 0 0 5 2H1.5z"/></svg>',
	"folder_open": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#62a0ea" d="M1.5 2A1.5 1.5 0 0 0 0 3.5v9A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5v-7A1.5 1.5 0 0 0 14.5 4H7.414L5.707 2.293A1 1 0 0 0 5 2H1.5z"/><path fill="#8ec4f7" d="M0 6h16v6.5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 0 12.5V6z"/></svg>',
	"godot": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#478cbf" d="M2 3h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/><circle cx="5" cy="8" r="1.5" fill="#ffffff"/><circle cx="11" cy="8" r="1.5" fill="#ffffff"/><circle cx="5" cy="8" r="0.7" fill="#1e1e24"/><circle cx="11" cy="8" r="0.7" fill="#1e1e24"/><path fill="#ffffff" d="M7 9.5h2v1.5H7z"/></svg>',
	"scene": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#e06c75" d="M3 2h10a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z"/><path fill="#ffffff" d="M6 5l5 3-5 3V5z"/></svg>',
	"resource": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#e5c07b" d="M8 1.5l6 3.5v6.5l-6 3.5-6-3.5V5l6-3.5z"/><circle cx="8" cy="8.2" r="2.2" fill="#ffffff"/></svg>',
	"python": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#3572a5" d="M7.5 1.5h1A2.5 2.5 0 0 1 11 4v2H7v1h5.5A2.5 2.5 0 0 1 15 9.5v2a2.5 2.5 0 0 1-2.5 2.5h-1a2.5 2.5 0 0 1-2.5-2.5v-2h4v-1H7.5A2.5 2.5 0 0 1 5 6V4a2.5 2.5 0 0 1 2.5-2.5z"/><circle cx="6.5" cy="3.5" r="0.7" fill="#ffd43b"/><circle cx="9.5" cy="12.5" r="0.7" fill="#ffffff"/></svg>',
	"typescript": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#3178c6"/><text x="8" y="11.5" fill="#ffffff" font-family="sans-serif" font-weight="bold" font-size="8.5" text-anchor="middle">TS</text></svg>',
	"javascript": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#f7df1e"/><text x="8" y="11.5" fill="#000000" font-family="sans-serif" font-weight="bold" font-size="8.5" text-anchor="middle">JS</text></svg>',
	"react": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><ellipse cx="8" cy="8" rx="6.5" ry="2.5" fill="none" stroke="#61dafb" stroke-width="1.2"/><ellipse cx="8" cy="8" rx="6.5" ry="2.5" fill="none" stroke="#61dafb" stroke-width="1.2" transform="rotate(60 8 8)"/><ellipse cx="8" cy="8" rx="6.5" ry="2.5" fill="none" stroke="#61dafb" stroke-width="1.2" transform="rotate(120 8 8)"/><circle cx="8" cy="8" r="1.2" fill="#61dafb"/></svg>',
	"c": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#599eff"/><text x="8" y="11.5" fill="#ffffff" font-family="sans-serif" font-weight="bold" font-size="9" text-anchor="middle">C</text></svg>',
	"cpp": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#519aba"/><text x="8" y="11.5" fill="#ffffff" font-family="sans-serif" font-weight="bold" font-size="8" text-anchor="middle">C++</text></svg>',
	"rust": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><circle cx="8" cy="8" r="6.5" fill="#dea584"/><circle cx="8" cy="8" r="4.5" fill="#1e1e24"/><text x="8" y="11" fill="#dea584" font-family="sans-serif" font-weight="bold" font-size="7.5" text-anchor="middle">R</text></svg>',
	"go": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#00add8"/><text x="8" y="11.5" fill="#ffffff" font-family="sans-serif" font-weight="bold" font-size="8.5" text-anchor="middle">GO</text></svg>',
	"shell": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#202024"/><path fill="none" stroke="#57e389" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" d="M4 5l3.5 3L4 11m4.5 0h3.5"/></svg>',
	"git": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#f05032" d="M14.6 6.8l-5.4-5.4a1.8 1.8 0 0 0-2.5 0l-1.3 1.3 2 2a1.5 1.5 0 0 1 1.9 1.9l1.9 1.9a1.5 1.5 0 1 1-1.1 1.1l-1.9-1.9v2.2a1.5 1.5 0 1 1-1.5-1.5v-3.7a1.5 1.5 0 0 1-.8-.4l-2-2L1.4 6.8a1.8 1.8 0 0 0 0 2.5l5.4 5.4a1.8 1.8 0 0 0 2.5 0l5.3-5.4a1.8 1.8 0 0 0 0-2.5z"/></svg>',
	"json": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#cbcb41"/><text x="8" y="11" fill="#1e1e24" font-family="sans-serif" font-weight="bold" font-size="8" text-anchor="middle">{ }</text></svg>',
	"config": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#cb171e" d="M2.5 1.5h8l3 3V14a1 1 0 0 1-1 1h-10a1 1 0 0 1-1-1V2.5a1 1 0 0 1 1-1z"/><circle cx="8" cy="8.5" r="2" fill="#ffffff"/></svg>',
	"markdown": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#1e1e24"/><path fill="#519aba" d="M3 4.5h1.5l1.5 2 1.5-2H9v7H7.5v-4l-1.5 2-1.5-2v4H3v-7zm7.5 3.5h1.5v3.5h1.5L11.25 14 9 11.5h1.5V8z"/></svg>',
	"text": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#99c1f1" d="M2.5 1.5h7.5l3.5 3.5V14a1 1 0 0 1-1 1h-10a1 1 0 0 1-1-1V2.5a1 1 0 0 1 1-1z"/><path fill="#1e1e24" d="M4.5 6h7v1h-7zm0 2.5h7v1h-7zm0 2.5h4.5v1h-4.5z"/></svg>',
	"image": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#a074c4"/><circle cx="5" cy="5.5" r="1.3" fill="#ffffff"/><path fill="#ffffff" d="M3 13l3.5-4.5 2.5 3 2.5-3.5L13 13H3z"/></svg>',
	"audio": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><rect width="14" height="14" x="1" y="1" rx="2" fill="#e06c75"/><path fill="#ffffff" d="M6 4.5v7l5.5-3.5L6 4.5z"/></svg>',
	"archive": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#e5c07b" d="M2.5 1.5h11a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1V2.5a1 1 0 0 1 1-1z"/><path fill="#1e1e24" d="M7 2h2v1H7zm0 2h2v1H7zm0 2h2v1H7zm0 2h2v2H7z"/></svg>',
	"file": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#deddda" d="M2.5 1.5h7.5l3.5 3.5V14a1 1 0 0 1-1 1h-10a1 1 0 0 1-1-1V2.5a1 1 0 0 1 1-1z"/><path fill="#9a9996" d="M10 1.5V5h3.5L10 1.5z"/></svg>'
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


static func icon_key_for_path(path: String, is_dir: bool = false, is_open: bool = false) -> String:
	if is_dir:
		return "folder_open" if is_open else "folder"
	var fname: String = path.get_file().to_lower()
	var ext: String = path.get_extension().to_lower()

	# Exact file names
	match fname:
		".gitignore", ".gitmodules", ".gitattributes":
			return "git"
		"package.json", "package-lock.json":
			return "json"
		"cargo.toml", "cargo.lock":
			return "rust"
		"go.mod", "go.sum":
			return "go"
		"dockerfile", "docker-compose.yml", "docker-compose.yaml":
			return "config"
		"makefile", "gnumakefile":
			return "config"
		"readme.md", "license", "licence":
			return "markdown" if fname.ends_with(".md") else "text"
		"project.godot":
			return "godot"

	# Extensions
	match ext:
		"gd":
			return "godot"
		"tscn", "scn":
			return "scene"
		"tres", "res":
			return "resource"
		"py", "pyw", "ipynb":
			return "python"
		"ts":
			return "typescript"
		"js", "mjs", "cjs":
			return "javascript"
		"tsx", "jsx":
			return "react"
		"c", "h":
			return "c"
		"cpp", "cc", "cxx", "hpp", "hxx":
			return "cpp"
		"rs":
			return "rust"
		"go":
			return "go"
		"sh", "bash", "zsh", "fish":
			return "shell"
		"json":
			return "json"
		"yaml", "yml", "toml", "ini", "cfg", "conf", "godot", "import":
			return "config"
		"md", "markdown":
			return "markdown"
		"txt", "log", "rst":
			return "text"
		"png", "jpg", "jpeg", "webp", "gif", "svg", "ico":
			return "image"
		"wav", "mp3", "ogg", "flac", "mp4", "webm", "mkv":
			return "audio"
		"zip", "tar", "gz", "tgz", "7z", "rar":
			return "archive"
		_:
			return "file"


static func texture_for_path(path: String, is_dir: bool = false, is_open: bool = false) -> Texture2D:
	var key: String = FileKind.icon_key_for_path(path, is_dir, is_open)
	if _texture_cache.has(key):
		return _texture_cache[key]

	# 1. Try to load from res://icons/<key>.svg if it exists
	var res_path: String = "res://icons/%s.svg" % key
	if ResourceLoader.exists(res_path):
		var loaded_tex: Texture2D = load(res_path) as Texture2D
		if loaded_tex:
			_texture_cache[key] = loaded_tex
			return loaded_tex

	# 2. Dynamic runtime SVG parsing via Image.load_svg_from_string
	var svg_str: String = SVG_ICONS.get(key, SVG_ICONS["file"])
	var img: Image = Image.new()
	var err: Error = img.load_svg_from_string(svg_str, 1.0)
	if err == OK:
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		_texture_cache[key] = tex
		return tex

	return null


static func color_for_path(path: String, is_dir: bool = false) -> Color:
	if is_dir:
		return Color("#8ec4f7")
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
		"gd":
			return Color("#478cbf")
		"tscn", "scn":
			return Color("#e06c75")
		"tres", "res":
			return Color("#e5c07b")
		"json":
			return Color("#cbcb41")
		"sh", "bash", "zsh", "fish":
			return Color("#57e389")
		"md":
			return Color("#99c1f1")
		"txt":
			return Color("#deddda")
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


static func icon_for_path(path: String) -> String:
	if path.is_empty():
		return "📄"
	var ext: String = path.get_extension().to_lower()
	match ext:
		"py", "pyw", "ipynb":
			return "🐍"
		"js", "mjs", "cjs":
			return "📜"
		"ts", "tsx":
			return "📘"
		"jsx":
			return "⚛️"
		"gd":
			return "📄"
		"c", "h":
			return "🔤"
		"cpp", "cc", "cxx", "hpp", "hxx":
			return "⚙️"
		"rs":
			return "🦀"
		"go":
			return "🐹"
		"java":
			return "☕"
		"kt":
			return "🅺"
		"sh", "bash", "zsh", "fish":
			return "🐚"
		"lua":
			return "🌙"
		"rb":
			return "💎"
		"tscn", "scn":
			return "🃏"
		"res", "tres":
			return "📦"
		"json":
			return "🔷"
		"yaml", "yml":
			return "�purple"
		"toml", "ini":
			return "⚙️"
		"cfg":
			return "🛠"
		"xml":
			return "🧾"
		"md":
			return "📝"
		"html", "htm":
			return "📄"
		"css":
			return "🎨"
		"scss", "sass":
			return "💅"
		"png", "jpg", "jpeg", "gif", "webp", "svg", "ico", "bmp":
			return "🖼"
		"wav", "mp3", "ogg", "flac":
			return "🎵"
		"mp4", "webm", "ogv", "mkv":
			return "🎬"
		"zip", "tar", "gz", "tgz", "7z", "rar":
			return "🗜"
		"pdf":
			return "📄"
		"txt", "log", "rst":
			return "📄"
		_:
			return "📄"


static func icon_resource_path(kind: Kind) -> String:
	match kind:
		Kind.DIRECTORY:
			return "res://icons/folder.svg"
		Kind.SCRIPT:
			return "res://icons/godot.svg"
		Kind.SCENE:
			return "res://icons/scene.svg"
		Kind.IMAGE:
			return "res://icons/image.svg"
		Kind.AUDIO:
			return "res://icons/audio.svg"
		Kind.VIDEO:
			return "res://icons/scene.svg"
		Kind.ARCHIVE:
			return "res://icons/archive.svg"
		Kind.CONFIG:
			return "res://icons/config.svg"
		Kind.DOCUMENT:
			return "res://icons/markdown.svg"
		Kind.FILE:
			return "res://icons/file.svg"
		_:
			return "res://icons/file.svg"


static func texture_for(kind: Kind) -> Texture2D:
	var path: String = icon_resource_path(kind)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


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
