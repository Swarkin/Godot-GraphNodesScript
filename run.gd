extends Button

@export var graph: GraphEdit

func _pressed() -> void:
	graph.execute()
