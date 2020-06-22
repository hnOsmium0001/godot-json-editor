tool
extends Button

export(String) var icon_name: String
export(String) var type: String = "EditorIcons"

func _ready():
	# Somehow not deferring makes the icon hidden
	call_deferred("_add_props")

func _add_props():
	icon = get_icon(icon_name, type)
