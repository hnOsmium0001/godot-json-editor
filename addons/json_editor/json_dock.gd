tool
class_name JsonDock
extends PanelContainer

const TYPE_COL := 0
const KEY_COL := 1
const VALUE_COL := 2

const TYPES := [
	{
		name = "Object",
		default_val = {},
	},
	{
		name = "Array",
		default_val = [],
	},
	{
		name = "String",
		default_val = "",
	},
	{
		name = "Number",
		default_val = 0,
	},
	{
		name = "Boolean",
		default_val = false,
	},
	{
		name = "Null",
		default_val = null,
	},
]

const INDENTATIONS := [
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
onready var settings: PopupPanel = get_node("Settings")
onready var close_file_confirmation: ConfirmationDialog = get_node("Close File Confirmation")
onready var error_dialog: AcceptDialog = get_node("Error Dialog")

onready var file_name: Label = get_node("VBoxContainer/Tools/Left/File Name")
onready var tree: Tree = get_node("VBoxContainer/Tree")

var opened_path: String
var indentation_idx: int = 0
var auto_parenting: bool = false

func _ready() -> void:
	name = "JSON"
	
	var indentation_option: OptionButton = get_node("Settings/VSplitContainer/Contents/Indentation/OptionButton")
	indentation_option.clear()
	for i in range(0, INDENTATIONS.size()):
		indentation_option.add_item(INDENTATIONS[i].name, i)
	
	var add_element_button: MenuButton = get_node("VBoxContainer/Tree Manipulation Tools/Add Entry")
	for i in range(0, TYPES.size()):
		add_element_button.get_popup().add_item(TYPES[i].name, i)
	add_element_button.get_popup().connect("id_pressed", self, "_add_element")
	
	tree.columns = 3
	select_file_dialog.connect("file_selected", self, "_open_file")

func _request_open_file() -> void:
	if not opened_path.empty():
		error_dialog.dialog_text = "A file is already open. Please close the current file before opening a new one."
		error_dialog.popup_centered()
		return
	select_file_dialog.popup_centered_ratio()

func _open_file(file_path: String) -> void:
	var file := File.new()
	var file_open_err := file.open(file_path, File.READ)
	if file_open_err != OK:
		show_error("Error while trying to open JSON file %s. Error code: %d" % [file_path, file_open_err])
		return
	
	var parse_result := JSON.parse(file.get_as_text())
	if parse_result.error != OK:
		show_error("Loaded invalid JSON file from %s, please fix syntax errors before loading with this plugin." % file_path)
		return
	file.close()
	
	opened_path = file_path
	file_name.text = select_file_dialog.current_file
	
	var root = parse_result.result
	match typeof(root):
		TYPE_DICTIONARY:
			_gen_object(root as Dictionary, "", false)
		TYPE_ARRAY:
			_gen_array(root as Array, "", false)
		TYPE_STRING:
			_gen_item(null, "String", root)
		TYPE_BOOL:
			_gen_item(null, "Boolean", root)
		TYPE_REAL:
			_gen_item(null, "Number", root)
		_:
			_gen_item(null, "Null", null)

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
	var indent: String = INDENTATIONS[indentation_idx].indent
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
		close_file_confirmation.popup_centered()

func _close_file() -> void:
	opened_path = ""
	file_name.text = ""
	tree.clear()
	

func show_error(msg: String) -> void:
	push_error(msg)
	error_dialog.dialog_text = msg
	error_dialog.popup_centered()

func _close_settings() -> void:
	settings.visible = false

func _open_settings() -> void:
	settings.popup_centered()

func _select_indentation(id: int) -> void:
	indentation_idx = id

func _set_auto_parenting_option(pressed: bool) -> void:
	auto_parenting = pressed

func _add_element(id: int, parent: TreeItem = null) -> void:
	var sel := tree.get_selected() if parent == null else parent
	if sel == null:
		return
	
	var key: String
	var has_key := false
	match sel.get_text(TYPE_COL):
		"Object":
			key = ""
			has_key = true
		"Array":
			has_key = false
		_:
			if auto_parenting:
				# auto-parenting result
				var apr: TreeItem = sel
				while apr != null:
					var type := apr.get_text(TYPE_COL)
					if type == "Object" or type == "Array":
						break
					apr = apr.get_parent()
				_add_element(id, apr)
			else:
				show_error("Cannot add to a non-container element!")
			return
	
	var type: String = TYPES[id].name
	var default_val = TYPES[id].default_val
	match type:
		"Object":
			_gen_object(default_val, key, has_key, sel)
		"Array":
			_gen_array(default_val, key, has_key, sel)
		_:
			_gen_item(sel, type, default_val, key, has_key)
		

func _remove_selected_element() -> void:
	var sel := tree.get_selected()
	if sel == null:
		return
	
	var parent := sel.get_parent()
	if parent == null:
		show_error("Cannot remove the root node!")
	else:
		parent.remove_child(sel)
