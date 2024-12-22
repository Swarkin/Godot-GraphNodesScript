class_name GraphNodeAlert
extends ExecutableGraphNode

func execute(args: Array) -> void:
	OS.alert(args[0], args[1])
