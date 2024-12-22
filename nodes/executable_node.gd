class_name ExecutableGraphNode
extends GraphNode

@warning_ignore("unused_parameter")
func execute(args: Array) -> void:
	push_error("Cannot call function on abstract class")
