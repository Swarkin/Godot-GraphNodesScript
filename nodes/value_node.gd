class_name ValueGraphNode
extends GraphNode

func get_value() -> Variant:
	push_error("Cannot call function on abstract class")
	return null

@warning_ignore("unused_parameter")
func set_value(v) -> void:
	push_error("Cannot call function on abstract class")
