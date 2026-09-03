class_name CodeEditorService
extends RefCounted

## Owns editor-only configuration. Keeping this out of the scene controller
## makes the UI script responsible for orchestration rather than code syntax.

const KEYWORDS: Array[String] = [
	"func", "var", "const", "extends", "class_name", "if", "elif", "else",
	"for", "while", "match", "return", "signal", "enum", "static", "void",
	"int", "float", "bool", "String", "Array", "Dictionary", "true", "false", "null",
	"@onready", "@export", "preload", "load", "print", "push_error", "await",
]

const BUILTIN_FUNCTIONS: Array[String] = [
	"print", "push_error", "push_warning", "len", "range", "str", "int", "float",
	"bool", "min", "max", "clamp", "abs", "sin", "cos", "sqrt", "randf", "randi",
	"load", "preload", "get_node", "has_node", "find_child", "add_child", "remove_child",
	"queue_free", "emit_signal", "connect", "disconnect", "is_connected",
]

const TYPES: Array[String] = [
	"Node", "Control", "Panel", "PanelContainer", "Label", "Button", "LineEdit",
	"TextEdit", "CodeEdit", "Tree", "TreeItem", "ItemList", "TabBar", "RichTextLabel",
	"HTTPRequest", "ColorRect", "TextureRect", "Vector2", "Vector3", "Color", "Rect2",
	"Transform2D", "Transform3D", "PackedStringArray", "PackedByteArray", "Variant",
]


static func configure(editor: CodeEdit, palette: Dictionary, open_files: Array) -> void:
	editor.syntax_highlighter = create_highlighter(palette)
	editor.draw_tabs = true
	editor.draw_spaces = false
	editor.indent_size = 4
	editor.indent_use_spaces = false
	editor.auto_brace_completion_enabled = true
	editor.code_completion_enabled = true
	editor.code_completion_prefixes = [".", "(", "@", "$", " ", ":"]
	update_completion(editor, open_files)


static func update_completion(editor: CodeEdit, open_files: Array) -> void:
	for keyword in KEYWORDS:
		editor.add_code_completion_option(CodeEdit.KIND_KEYWORD, keyword, keyword, Color("#dc8add"))
	for function_name in BUILTIN_FUNCTIONS:
		editor.add_code_completion_option(CodeEdit.KIND_FUNCTION, function_name, function_name + "()", Color("#62a0ea"))
	for type_name in TYPES:
		editor.add_code_completion_option(CodeEdit.KIND_CLASS, type_name, type_name, Color("#93ddc2"))
	for file_info: Dictionary in open_files:
		var filename: String = str(file_info.get("path", "")).get_file()
		if not filename.is_empty():
			editor.add_code_completion_option(CodeEdit.KIND_FILE_PATH, filename, '"' + filename + '"', Color("#57e389"))
	editor.update_code_completion_options(false)


static func create_highlighter(palette: Dictionary) -> CodeHighlighter:
	var highlighter := CodeHighlighter.new()
	highlighter.number_color = Color(str(palette.get("hl_number", "#ffa348")))
	highlighter.symbol_color = Color(str(palette.get("hl_symbol", "#5bc8af")))
	highlighter.function_color = Color(str(palette.get("hl_func", "#62a0ea")))
	highlighter.member_variable_color = Color(str(palette.get("hl_member", "#99c1f1")))
	var keyword_colour := Color(str(palette.get("hl_keyword", "#dc8add")))
	var type_colour := Color(str(palette.get("hl_type", "#93ddc2")))
	var constant_colour := Color(str(palette.get("hl_const", "#ffa348")))
	highlighter.add_color_region("#", "", Color(str(palette.get("hl_comment", "#9a9996"))), true)
	highlighter.add_color_region('"', '"', Color(str(palette.get("hl_string", "#57e389"))))
	highlighter.add_color_region("'", "'", Color(str(palette.get("hl_string", "#57e389"))))
	highlighter.add_color_region('\"\"\"', '\"\"\"', Color(str(palette.get("hl_string", "#57e389"))))
	for keyword in KEYWORDS:
		highlighter.add_keyword_color(keyword, keyword_colour)
	for type_name in ["Vector2", "Vector3", "Color", "PackedStringArray", "PackedByteArray", "Error", "NodePath", "StringName"]:
		highlighter.add_keyword_color(type_name, type_colour)
	for constant_name in ["true", "false", "null", "self", "PI", "TAU", "INF", "NAN"]:
		highlighter.add_keyword_color(constant_name, constant_colour)
	return highlighter
