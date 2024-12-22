class_name ValueGraphNode
extends GraphNode

func get_value():
	push_error("Cannot call function on abstract class")
	return
