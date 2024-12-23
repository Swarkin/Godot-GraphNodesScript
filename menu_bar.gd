extends Container

@export var graph: ScriptGraphEdit
@export var file_menu: MenuButton

func _enter_tree() -> void:
	var file_popup := file_menu.get_popup()
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)

func _on_file_menu_id_pressed(id: int) -> void:
	match id:
		0:
			print("New")
			for c in graph.get_children():
				if c is GraphNode:
					c.queue_free()

			graph.connections.clear()
		1:
			print("Open")
			var file := FileAccess.open("user://test.json", FileAccess.READ)
			var data := JSON.parse_string(file.get_as_text()) as Dictionary
			print(data)

			var in_conn_data: Array[Dictionary]
			var out_conn_data: Array[Dictionary]

			for name_key in data:
				var node_data := data[name_key] as Dictionary
				var graph_node := (load("res://nodes/"+node_data["t"]) as PackedScene).instantiate() as GraphNode
				in_conn_data.append_array(node_data["i"])
				out_conn_data.append_array(node_data["o"])
				graph_node.position_offset = Vector2(node_data["px"], node_data["py"])
				graph_node.size = Vector2(node_data["sx"], node_data["sy"])
				if node_data.has("v"):
					graph_node.set_value(node_data["v"])
				graph.add_child(graph_node)

			for in_conn in in_conn_data:
				graph.connect_node(in_conn["fn"], in_conn["fp"], in_conn["tn"], in_conn["tp"])

			for out_conn in out_conn_data:
				graph.connect_node(out_conn["fn"], out_conn["fp"], out_conn["tn"], out_conn["tp"])
		2:
			print("Save")
			var nodes := graph.parse()
			var data := {}

			for name_key in nodes:
				var node := nodes[name_key]
				var node_data := {
					"t": node.node.scene_file_path.get_file(),
					"px": node.node.position_offset.x,
					"py": node.node.position_offset.y,
					"sx": node.node.size.x,
					"sy": node.node.size.y,
					"i": [],
					"o": [],
				}

				if node.node is ValueGraphNode:
					node_data["v"] = node.node.get_value()

				for in_conn in node.in_connections:
					node_data["i"].append({
						"fp": in_conn.from_port,
						"tp": in_conn.to_port,
						"fn": in_conn.from_node.node.name,
						"tn": in_conn.to_node.node.name,
					})

				for out_conn in node.out_connections:
					node_data["o"].append({
						"fp": out_conn.from_port,
						"tp": out_conn.to_port,
						"fn": out_conn.from_node.node.name,
						"tn": out_conn.to_node.node.name,
					})

				data[name_key] = node_data

			var file := FileAccess.open("user://test.json", FileAccess.WRITE)
			file.store_string(JSON.stringify(data))
