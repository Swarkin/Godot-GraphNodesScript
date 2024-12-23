class_name GraphNodeEquals
extends BranchingGraphNode

var _decision = null

func execute(args: Array) -> void:
	print("exec called")
	print(get_stack())
	_decision = args[0] == args[1]

func next_flow(out_connections: Array[ScriptGraphEdit.GraphNodeConnection]) -> ScriptGraphEdit.GraphNodeConnection:
	if out_connections.is_empty():
		return
	elif _decision == null:
		push_error("Reading decision before execute")
		return
	else:
		var target_from_port := 0 if _decision else 1
		for conn in out_connections:
			print(conn.from_port)
			if conn.from_port == target_from_port:
				return conn

		push_error("Missing connection")
		return
