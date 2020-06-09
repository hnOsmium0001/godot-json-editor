tool
class_name JsonDock
extends PanelContainer

const TYPE_COL := 0
const KEY_COL := 1
const VALUE_COL := 2

onready var open_button: Button = get_node("VSplitContainer/Tools/Open File")
onready var file_name: Label = get_node("VSplitContainer/Tools/File Name")
onready var tree: Tree = get_node("VSplitContainer/Tree")
var select_file_dialog: EditorFileDialog
var confirmation_dialog: ConfirmationDialog
var error_dialog: AcceptDialog

var opened_path: String
var json: Dictionary
var modified_not_saved: bool

func _ready() -> void:
	self.name = "JSON"
	
	tree.columns = 3
	select_file_dialog.connect("file_selected", self, "_open_file")

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
	
	self.opened_path = file_path
	self.json = parse_result.result
	self.modified_not_saved = false
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
				var item := tree.create_item(object)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "String")
				item.set_cell_mode(KEY_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(KEY_COL, key)
				item.set_editable(KEY_COL, true)
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, "\"%s\"" % value)
				item.set_editable(VALUE_COL, true)
			TYPE_BOOL:
				var item := tree.create_item(object)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "Boolean")
				item.set_cell_mode(KEY_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(KEY_COL, key)
				item.set_editable(KEY_COL, true)
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, str(value))
				item.set_editable(VALUE_COL, true)
			_:
				var item := tree.create_item(object)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "Unknown")
				item.set_cell_mode(KEY_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(KEY_COL, key)
				item.set_editable(KEY_COL, true)
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, str(value))
				item.set_editable(VALUE_COL, true)

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
				var item := tree.create_item(array)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "String")
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, "\"%s\"" % value)
				item.set_editable(VALUE_COL, true)
			_:
				var item := tree.create_item(array)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "Unknown")
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, str(value))
				item.set_editable(VALUE_COL, true)
			TYPE_BOOL:
				var item := tree.create_item(array)
				item.set_cell_mode(TYPE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(TYPE_COL, "Boolean")
				item.set_cell_mode(VALUE_COL, TreeItem.CELL_MODE_STRING)
				item.set_text(VALUE_COL, str(value))
				item.set_editable(VALUE_COL, true)

func _request_save_file() -> void:
	var file := File.new()
	if file.open(opened_path, File.WRITE) != OK:
		show_error("Error while trying to open JSON file %s." % opened_path)
		return
	file.store_string(JSON.print(json))
	file.close()
	
	modified_not_saved = false

func _request_close_file() -> void:
	if modified_not_saved:
		confirmation_dialog.dialog_text = "You have changes that are not saved, discard?"
		confirmation_dialog.connect("confirmed", self, "_close_file")
		confirmation_dialog.popup_centered()
	else:
		_close_file()

func _close_file() -> void:
	self.opened_path = ""
	self.json = {}
	file_name.text = ""
	tree.clear()

func show_error(msg: String) -> void:
	push_error(msg)
	error_dialog.dialog_text = msg
	error_dialog.popup_centered()
