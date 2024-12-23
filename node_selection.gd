extends Container

const PATH := "res://nodes/"
const NODE_BUTTON := preload("res://ui/node_button.tscn") as PackedScene

@export var graph: ScriptGraphEdit
@export var buttons: Container

var nodes: Dictionary[String, PackedScene]

func _enter_tree() -> void:
	for file in DirAccess.get_files_at(PATH):
		if file.ends_with(".tscn"):
			var scn := load(PATH+file) as PackedScene
			nodes[file] = scn
			var btn := NODE_BUTTON.instantiate() as Button
			btn.text = file.get_basename().to_pascal_case()
			btn.pressed.connect(_pressed.bind(file))
			buttons.add_child(btn)

func _pressed(node: String) -> void:
	var scn := nodes[node].instantiate() as GraphNode
	scn.position_offset = graph.scroll_offset
	graph.add_child(scn)
