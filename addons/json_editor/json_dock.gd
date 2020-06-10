tool
class_name JsonDock
extends PanelContainer

const TYPE_COL := 0
const KEY_COL := 1
const VALUE_COL := 2

const INDENTATIONS := [
	{
		name = "2 width spaces",
		indent = "  ",
	},
	{
		name = "4 width spaces",
		indent = "    ",
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

onready var settings: PopupPanel = get_node("Settings")
onready var indentation_options: OptionButton = get_node("Settings/VSplitContainer/Contents/Indentation/OptionButton")

onready var open_button: Button = get_node("VSplitContainer/Tools/Left/Open File")
onready var file_name: Label = get_node("VSplitContainer/Tools/Left/File Name")
onready var tree: Tree = get_node("VSplitContainer/Tree")

var select_file_dialog: EditorFileDialog
var confirmation_dialog: ConfirmationDialog
var error_dialog: AcceptDialog

var opened_path: String
var indent: String = INDENTATIONS[0].indent

func _ready() -> void:
	self.name = "JSON"
	
	indentation_options.clear()
	for i in range(0, INDENTATIONS.size()):
		indentation_options.add_item(INDENTATIONS[i].name, i)
	
	#get_node("Settings/VSplitContainer/Navigation/Right/Close").icon = get_icon("Close", "EditorIcons")
	
	tree.columns = 3
	select_file_dialog.connect("file_selected", self, "_open_file")
	confirmation_dialog.dialog_text = "There may have been changes, discard them?"
	confirmation_dialog.connect("confirmed", self, "_close_file")

func _request_open_file() -> void:
	select_file_dialog.popup_centered_ratio()

func _open_file(file_path: String) -> void:
	var file := File.new()
	if file.open(file_path, File.READ) != OK:
		show_error("Error while trying to open JSON file %s." % file_path)
		return
	
	var parse_result := JSON.parse(file.get_as_text())
	if parse_result.error != OK:
		show_error("Loaded invalid JSON file from %s, please fix syntax errors before loading with this plugin." % file_path)
		return
	file.close()
	
	opened_path = file_path
	file_name.text = select_file_dialog.current_file
	
	_gen_object(parse_result.result)

func _gen_object(node: Dictionary, node_key: String = "", has_key: bool = false, parent: Object = null) -> void:
	var object := tree.create_item(parent)
	
	object.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
	object.set_text(TYPE_COL, "Object")
	if has_key:
		object.set_cell_mode(KEY_COL, TreeItem.CELL_MODE_STRING)
		object.set_text(KEY_COL, node_key)
		object.set_editable(KEY_COL, true)
	
	for dict_key in node.keys():
		var key := dict_key as String
		var value = node[key]
		match typeof(value):
			TYPE_DICTIONARY:
				_gen_object(value as Dictionary, key, true, object)
			TYPE_ARRAY:
				_gen_array(value as Array, key, true, object)
			TYPE_STRING:
				_gen_item(object, "String", value, key, true)
			TYPE_BOOL:
				_gen_item(object, "Boolean", value, key, true)
			TYPE_REAL:
				_gen_item(object, "Number", value, key, true)
			_:
				_gen_item(object, "Null", null, key, true)

func _gen_array(node: Array, node_key: String = "", has_key: bool = false, parent: Object = null) -> void:
	var array := tree.create_item(parent)
	
	array.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
	array.set_text(TYPE_COL, "Array")
	if has_key:
		array.set_cell_mode(KEY_COL, TreeItem.CELL_MODE_STRING)
		array.set_text(KEY_COL, node_key)
		array.set_editable(KEY_COL, true)
	
	for value in node:
		match typeof(value):
			TYPE_DICTIONARY:
				_gen_object(value as Dictionary, "", false, array)
			TYPE_ARRAY:
				_gen_array(value as Array, "", false, array)
			TYPE_STRING:
				_gen_item(array, "String", value)
			TYPE_BOOL:
				_gen_item(array, "Boolean", value)
			TYPE_REAL:
				_gen_item(array, "Number", value)
			_:
				_gen_item(array, "Null", null)

func _gen_item(parent: TreeItem, type: String, value, key: String = "", has_key: bool = false) -> TreeItem:
	var item := tree.create_item(parent)
	item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
	item.set_text(TYPE_COL, type)
	if has_key:
		item.set_text(KEY_COL, key)
		item.set_editable(KEY_COL, true)
	item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
	item.set_text(VALUE_COL, str(value))
	item.set_editable(VALUE_COL, true)
	return item

func _request_save_file() -> void:
	if opened_path.empty():
		return
	
	var file := File.new()
	if file.open(opened_path, File.WRITE) != OK:
		show_error("Error while trying to open JSON file %s." % opened_path)
		return
	var json := _reconstruct_object(tree.get_root())
	file.store_string(JSON.print(json, indent))
	file.close()

func _reconstruct_object(node: TreeItem) -> Dictionary:
	var result := {}
	var child := node.get_children()
	while child:
		var key := child.get_text(KEY_COL)
		match child.get_text(TYPE_COL):
			"Object":
				result[key] = _reconstruct_object(child)
			"Array":
				result[key] = _reconstruct_array(child)
			"String":
				result[key] = child.get_text(VALUE_COL)
			"Number":
				result[key] = int(child.get_text(VALUE_COL))
			"Boolean":
				result[key] = bool(child.get_text(VALUE_COL))
			"Null":
				result[key] = null
		child = child.get_next()
	return result

func _reconstruct_array(node: TreeItem) -> Array:
	var result := []
	var child := node.get_children()
	while child:
		match child.get_text(TYPE_COL):
			"Object":
				result.append(_reconstruct_object(child))
			"Array":
				result.append(_reconstruct_array(child))
			"String":
				result.append(child.get_text(VALUE_COL))
			"Number":
				result.append(int(child.get_text(VALUE_COL)))
			"Boolean":
				result.append(bool(child.get_text(VALUE_COL)))
			"Null":
				result.append(null)
		child = child.get_next()
	return result

func _request_close_file() -> void:
	if not opened_path.empty():
		confirmation_dialog.popup_centered()

func _close_file() -> void:
	opened_path = ""
	file_name.text = ""
	tree.clear()

func show_error(msg: String) -> void:
	push_error(msg)
	error_dialog.dialog_text = msg
	error_dialog.popup_centered()

func _select_indentation(id):
	indent = INDENTATIONS[id].indent

func _open_settings():
	settings.popup_centered()

func _close_settings():
	settings.visible = false
