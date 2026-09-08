extends Control

## Welcome screen controller — handles initial boot animation and seamless transition to ui_editor.tscn.

@onready var _progress_bar: ProgressBar = get_node_or_null("%ProgressBar") as ProgressBar
@onready var _status_label: Label = get_node_or_null("%StatusLabel") as Label

var _progress: float = 0.0

func _ready() -> void:
	if _progress_bar:
		_progress_bar.value = 0.0
	if _status_label:
		_status_label.text = "Initialising SSCodeIDE workspace..."
	set_process(true)

func _process(delta: float) -> void:
	_progress += delta * 220.0
	if _progress_bar:
		_progress_bar.value = minf(_progress, 100.0)
	if _progress >= 100.0:
		set_process(false)
		_transition_to_editor()

func _transition_to_editor() -> void:
	get_tree().change_scene_to_file("res://scene/ui_editor.tscn")
