tool
extends EditorPlugin

var select_file_dialog: EditorFileDialog
var dock: JsonDock

func _enter_tree() -> void:
	var base := get_editor_interface().get_base_control()
	
	select_file_dialog = EditorFileDialog.new()
	select_file_dialog.add_filter("*.json")
	select_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	base.add_child(select_file_dialog)
	
	dock = preload("res://addons/json_editor/json_dock.tscn").instance()
	dock.select_file_dialog = select_file_dialog
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
	select_file_dialog.free()
