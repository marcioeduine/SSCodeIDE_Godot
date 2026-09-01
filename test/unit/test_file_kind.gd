extends GutTest


func test_directory_kind() -> void:
	assert_eq(FileKind.kind_for("/tmp/project", true), FileKind.Kind.DIRECTORY)


func test_script_extensions() -> void:
	assert_eq(FileKind.kind_for("ui_editor.gd", false), FileKind.Kind.SCRIPT)
	assert_eq(FileKind.kind_for("main.py", false), FileKind.Kind.SCRIPT)
	assert_eq(FileKind.kind_for("app.ts", false), FileKind.Kind.SCRIPT)


func test_scene_image_config_document() -> void:
	assert_eq(FileKind.kind_for("scene/ui_editor.tscn", false), FileKind.Kind.SCENE)
	assert_eq(FileKind.kind_for("icon.svg", false), FileKind.Kind.IMAGE)
	assert_eq(FileKind.kind_for("project.godot", false), FileKind.Kind.CONFIG)
	assert_eq(FileKind.kind_for("README.md", false), FileKind.Kind.DOCUMENT)
	assert_eq(FileKind.kind_for("notes.txt", false), FileKind.Kind.DOCUMENT)


func test_icon_for_path_and_label_for_path() -> void:
	assert_eq(FileKind.label_for_path("main.gd"), "GDScript")
	assert_eq(FileKind.label_for_path("main.py"), "Python")
	assert_eq(FileKind.label_for_path(""), "Plain Text")
	assert_eq(FileKind.icon_for_path("doc.md"), "📝")
	assert_eq(FileKind.icon_for_path("code.gd"), "📄")


func test_icon_resources_exist() -> void:
	var kinds: Array = [
		FileKind.Kind.DIRECTORY,
		FileKind.Kind.SCRIPT,
		FileKind.Kind.SCENE,
		FileKind.Kind.IMAGE,
		FileKind.Kind.AUDIO,
		FileKind.Kind.VIDEO,
		FileKind.Kind.ARCHIVE,
		FileKind.Kind.CONFIG,
		FileKind.Kind.DOCUMENT,
		FileKind.Kind.FILE,
	]
	for kind in kinds:
		var k: FileKind.Kind = kind
		var path: String = FileKind.icon_resource_path(k)
		assert_true(ResourceLoader.exists(path), path)
		var tex: Texture2D = FileKind.texture_for(k)
		assert_not_null(tex, path)
