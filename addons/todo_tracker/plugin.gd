@tool
extends EditorPlugin

const TodoDockScene = preload("res://addons/todo_tracker/todo_dock.tscn")

var _dock: Control
var _fs_connected := false

func _enter_tree() -> void:
	_dock = TodoDockScene.instantiate()
	_dock.editor_interface = get_editor_interface()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)

	var fs := get_editor_interface().get_resource_filesystem()
	if fs and not fs.filesystem_changed.is_connected(_on_filesystem_changed):
		fs.filesystem_changed.connect(_on_filesystem_changed)
		_fs_connected = true

func _exit_tree() -> void:
	if _fs_connected:
		var fs := get_editor_interface().get_resource_filesystem()
		if fs and fs.filesystem_changed.is_connected(_on_filesystem_changed):
			fs.filesystem_changed.disconnect(_on_filesystem_changed)
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()

func _on_filesystem_changed() -> void:
	if _dock and _dock.has_method("refresh"):
		_dock.refresh()
