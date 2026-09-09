extends Control

## Welcome screen controller — handles initial boot animation and seamless
## asynchronous transition to ui_editor.tscn via ResourceLoader threading.

@onready var _progress_bar: ProgressBar = get_node_or_null("%ProgressBar") as ProgressBar
@onready var _status_label: Label = get_node_or_null("%StatusLabel") as Label

var _load_started: bool = false
const _EDITOR_SCENE := "res://scene/ui_editor.tscn"

func _ready() -> void:
	if _progress_bar:
		_progress_bar.value = 0.0
	if _status_label:
		_status_label.text = "Initialising SSCodeIDE workspace..."
	ResourceLoader.load_threaded_request(_EDITOR_SCENE, "", true)
	_load_started = true


func _process(_delta: float) -> void:
	if not _load_started:
		return
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(_EDITOR_SCENE, progress)
	var pct: float = float(progress[0]) * 100.0 if not progress.is_empty() else 0.0
	if _progress_bar:
		_progress_bar.value = pct
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if _status_label:
				_status_label.text = "Loading editor… %d%%" % int(pct)
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var scene: PackedScene = ResourceLoader.load_threaded_get(_EDITOR_SCENE) as PackedScene
			if scene:
				get_tree().change_scene_to_packed(scene)
			else:
				if _status_label:
					_status_label.text = "Error: could not load editor scene."
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			if _status_label:
				_status_label.text = "Error loading editor."
		_:
			pass
