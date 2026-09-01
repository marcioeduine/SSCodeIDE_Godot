class_name FileKind
extends RefCounted

## Maps paths to explorer kinds, @icons textures, and editor language labels.

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

const ICON_DIR := "res://addons/at-icons/node/"


static func kind_for(path: String, is_dir: bool) -> Kind:
	if is_dir:
		return Kind.DIRECTORY
	var ext: String = path.get_extension().to_lower()
	match ext:
		"gd", "py", "js", "ts", "tsx", "jsx", "c", "h", "cc", "cpp", "hpp", "rs", "go", "java", "kt", "sh", "bash", "zsh", "lua", "rb":
			return Kind.SCRIPT
		"tscn", "scn", "res":
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


static func icon_resource_path(kind: Kind) -> String:
	match kind:
		Kind.DIRECTORY:
			return ICON_DIR + "folder.svg"
		Kind.SCRIPT:
			return ICON_DIR + "file_code.svg"
		Kind.SCENE:
			return ICON_DIR + "clapperboard.svg"
		Kind.IMAGE:
			return ICON_DIR + "file_image.svg"
		Kind.AUDIO:
			return ICON_DIR + "file_note.svg"
		Kind.VIDEO:
			return ICON_DIR + "file_video.svg"
		Kind.ARCHIVE:
			return ICON_DIR + "folder_zip.svg"
		Kind.CONFIG:
			return ICON_DIR + "file_cog.svg"
		Kind.DOCUMENT:
			return ICON_DIR + "file_document.svg"
		_:
			return ICON_DIR + "file.svg"


static func texture_for(kind: Kind) -> Texture2D:
	var path: String = icon_resource_path(kind)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func icon_for_path(path: String) -> String:
	var k: Kind = kind_for(path, false)
	match k:
		Kind.DIRECTORY:
			return "📁"
		Kind.SCRIPT:
			return "📄"
		Kind.SCENE:
			return "🎬"
		Kind.IMAGE:
			return "🖼️"
		Kind.AUDIO:
			return "🎵"
		Kind.VIDEO:
			return "🎥"
		Kind.ARCHIVE:
			return "📦"
		Kind.CONFIG:
			return "⚙️"
		Kind.DOCUMENT:
			return "📝"
		_:
			return "📄"


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
		"sh", "bash", "zsh":
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
