tool
extends EditorPlugin

enum Formatting {
	SPACE_2_WIDE,
	SAPCE_4_WIDE,
	SPACE_8_WIDE,
	TABS,
	NO_INDENTATION,
}

const FORMATTING_DATA := [
	{
		name = "2 wide spaces",
		indent = "  ",
	},
	{
		name = "4 wide spaces",
		indent = "    ",
	},
	{
		name = "8 wide spaces",
		indent = "        ",
	},
	{
		name = "tabs",
		indent = "	",
	},
	{
		name = "no formatting",
		indent = "",
	},
]

var select_file_dialog: EditorFileDialog
var dock: JsonDock

func _enter_tree() -> void:
	_add_enum_setting("plugins/json_editor/formatting", Formatting.SPACE_2_WIDE, FORMATTING_DATA)
	var ps_error := ProjectSettings.save()
	if ps_error:
		push_error("Failed to save project settings after adding custom entries from Godot JSON Editor. Error code: %d" % ps_error)
	
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


func _add_enum_setting(name: String, default_value: int, enum_descs: Array) -> void:
	var hint_string := ""
	for desc in enum_descs:
		hint_string = "%s,%s" % [hint_string, str(desc.name)]
	_add_setting(name, default_value, TYPE_INT, PROPERTY_HINT_ENUM, hint_string)

func _add_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	var info := {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	}
	ProjectSettings.set_setting(name, default_value)
	#ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.add_property_info(info)
