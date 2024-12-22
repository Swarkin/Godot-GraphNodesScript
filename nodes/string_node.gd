class_name GraphNodeString
extends ValueGraphNode

@export var line_edit: LineEdit

func get_value() -> String:
	return line_edit.text
