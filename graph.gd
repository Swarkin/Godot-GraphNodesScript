class_name ScriptGraphEdit
extends GraphEdit

const TYPE_FLOW := 69
const TYPE_ANY := 42

@export var verbose := false
@export var hide_scroll := false:
	set(v):
		hide_scroll = v
		set_process(v)

var _h_scroll: HScrollBar
var _v_scroll: VScrollBar

class GraphNodeRepr:
	var node: GraphNode
	var in_connections: Array[GraphNodeConnection]
	var out_connections: Array[GraphNodeConnection]

	func _init(_node: GraphNode) -> void:
		node = _node

	func flow_next() -> GraphNodeRepr:
		if out_connections.is_empty(): return null
		var conn: GraphNodeConnection

		if node is BranchingGraphNode:
			conn = node.next_flow(out_connections)
		else:
			conn = out_connections[0] if !out_connections.is_empty() else null

		return conn.to_node if conn else null

	func get_input(port_idx: int, default = null) -> Variant:
		var conn: GraphNodeConnection
		for c in in_connections:
			if c.to_port != port_idx: continue
			conn = c

		if conn == null:
			print("No connection for port %d" % port_idx)
			return default

		var in_node := conn.from_node.node

		if in_node is ValueGraphNode:
			return in_node.get_value()
		elif in_node is ExecutableGraphNode:
			push_error("Not implemented")
		else:
			push_error("Invalid connection")

		return default

class GraphNodeConnection:
	var from_node: GraphNodeRepr
	var from_port: int
	var to_node: GraphNodeRepr
	var to_port: int

	func _init(d: Dictionary, nodes: Dictionary[StringName, GraphNodeRepr]) -> void:
		from_node = nodes[d["from_node"]]
		from_port = d["from_port"]
		to_node = nodes[d["to_node"]]
		to_port = d["to_port"]


func _enter_tree() -> void:
	for c in get_children(true):
		if c.name.match("@Control@*"):
			_h_scroll = c.get_node(^"_h_scroll")
			_v_scroll = c.get_node(^"_v_scroll")

func _process(_dt: float) -> void:
	_set_scroll_visible(!hide_scroll)


func execute() -> void:
	if verbose: print("Executing...")
	var nodes := parse()

	var ready_node := nodes["ReadyNode"]
	if verbose:
		print(ready_node.node.name)
		print("In:   ", ready_node.in_connections)
		print("Out:  ", ready_node.out_connections)

	var next := ready_node.flow_next()
	while next:
		if verbose:
			print("\n - ", next.node.name)
			print("In:   ", next.in_connections)
			print("Out:  ", next.out_connections)

		var node := next.node as ExecutableGraphNode
		var args := []

		# resolve inputs
		for port_idx in node.get_input_port_count():
			var slot_idx := node.get_input_port_slot(port_idx)
			var debug := " [Port %d | Slot %d] " % [port_idx, slot_idx]

			var port_type := node.get_slot_type_left(slot_idx)
			if port_type == TYPE_FLOW:
				if verbose:
					debug += "Flow (Skipped)"
					print(debug)
				continue
			elif port_type == TYPE_ANY:
				debug += "Any"
			else:
				debug += type_string(port_type)

			var value = next.get_input(port_idx)
			if verbose: print(debug, " (%s) | " % type_string(typeof(value)), value)
			args.append(value)

		if verbose: print("Args: ", args)

		node.execute(args)
		next = next.flow_next()

	if verbose: print("\nFinished")

func parse() -> Dictionary[StringName, GraphNodeRepr]:
	var nodes: Dictionary[StringName, GraphNodeRepr]

	for node in get_children() as Array[Control]:
		if node is not GraphNode: continue
		nodes[node.name] = GraphNodeRepr.new(node)

	for conn in connections:
		var from := nodes[conn["from_node"] as StringName]
		var to := nodes[conn["to_node"] as StringName]
		var from_conn := GraphNodeConnection.new(conn, nodes)
		var to_conn := GraphNodeConnection.new(conn, nodes)
		from.out_connections.append(from_conn)
		to.in_connections.append(to_conn)

	return nodes


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from := get_node(str(from_node)) as GraphNode
	var to := get_node(str(to_node)) as GraphNode

	if from == to:
		print("Cannot connect to self")
		return

	for conn in connections:
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			print("Port already used")
			return

	# only connect flow outputs to flow inputs for dynamic nodes
	var _out := from.get_output_port_type(from_port)
	var _in := to.get_input_port_type(to_port)
	if _out == TYPE_FLOW || _in == TYPE_FLOW:
		if _out != _in:
			print("Flow -> Flow connection required")
			return

	connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node in nodes:
		get_node(node as String).queue_free()

		for conn in connections:
			if conn["from_node"] == node || conn["to_node"] == node:
				disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])


func _set_scroll_visible(state: bool) -> void:
	_h_scroll.visible = state
	_v_scroll.visible = state
