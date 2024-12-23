class_name BranchingGraphNode
extends ExecutableGraphNode

@warning_ignore("unused_parameter")
func next_flow(out_connections: Array[ScriptGraphEdit.GraphNodeConnection]) -> ScriptGraphEdit.GraphNodeConnection:
	push_error("Cannot call function on abstract class")
	return
