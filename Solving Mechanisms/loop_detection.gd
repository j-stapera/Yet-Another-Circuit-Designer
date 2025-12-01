extends Node

## Modified DFS algorithm to detect loops

@onready var graph = $"../Graph"

var loops = []

func detect_loops():
	loops.clear()
	
	var adjacency = build_adjacency_graph()
	
	print("\n=== LOOP DETECTION ===")
	print("Adjacency graph: ", adjacency)
	
	#var visited_edges = {}
	var spanning_tree_edges = []
	var non_tree_edges = []
	var visited_nodes = {}
	var node_keys = []
	
	node_keys = graph.nodes.keys()
	if node_keys.size() == 0:
		print("ERROR: No nodes found in graph")
		return []
	
	var start_node = node_keys[0]
	
	dfs_spanning_tree(start_node, null, adjacency, visited_nodes, spanning_tree_edges, non_tree_edges)
	
	print("\nSpanning tree edges: ", spanning_tree_edges)
	print("Non-tree edges: ", non_tree_edges)
	
	for edge in non_tree_edges:
		var loop = find_loop_from_edge(edge, spanning_tree_edges)
		if loop != null and loop.size() > 0:
			loops.append(loop)
	
	print("\nDETECTED LOOPS")
	for i in range(loops.size()):
		print("Loop ", i + 1, ": ", format_loop(loops[i]))
	
	return loops

func build_adjacency_graph():
	var adjacency = {}
	
	for node_name in graph.nodes.keys():
		adjacency[node_name] = []
	
	for comp_id in graph.components.keys():
		var connected_nodes = get_nodes_for_component(comp_id)
		if connected_nodes.size() == 2:
			var node1 = connected_nodes[0]
			var node2 = connected_nodes[1]
			
			adjacency[node1].append({"node": node2, "component": comp_id})
			adjacency[node2].append({"node": node1, "component": comp_id})
	
	return adjacency

func dfs_spanning_tree(current_node, parent_node, adjacency, visited_nodes, tree_edges, non_tree_edges):
	visited_nodes[current_node] = true
	
	for neighbor_info in adjacency[current_node]:
		var neighbor_node = neighbor_info.node
		var component_id = neighbor_info.component
		
		if neighbor_node == parent_node:
			continue
		
		var edge = {
			"from": current_node,
			"to": neighbor_node,
			"component": component_id
		}
		
		if not visited_nodes.has(neighbor_node):
			tree_edges.append(edge)
			dfs_spanning_tree(neighbor_node, current_node, adjacency, visited_nodes, tree_edges, non_tree_edges)
		else:
			var reverse_exists = false
			for nte in non_tree_edges:
				if nte.from == neighbor_node and nte.to == current_node and nte.component == component_id:
					reverse_exists = true
					break
			
			if not reverse_exists:
				non_tree_edges.append(edge)

func find_loop_from_edge(non_tree_edge, tree_edges):
	var start = non_tree_edge.to
	var end = non_tree_edge.from
	
	var path = find_path_in_tree(start, end, tree_edges)
	
	if path == null:
		return null
	
	var loop = []
	
	for edge in path:
		loop.append(edge.component)
	
	loop.append(non_tree_edge.component)
	
	return loop

func find_path_in_tree(start_node, end_node, tree_edges):
	var queue = [[start_node]]
	var visited = {start_node: true}
	
	var tree_adj = {}
	for node_name in graph.nodes.keys():
		tree_adj[node_name] = []
	
	for edge in tree_edges:
		tree_adj[edge.from].append({"node": edge.to, "component": edge.component})
		tree_adj[edge.to].append({"node": edge.from, "component": edge.component})
	
	while queue.size() > 0:
		var path = queue.pop_front()
		var current = path[-1]
		
		if current == end_node:
			var edge_path = []
			for i in range(path.size() - 1):
				var from = path[i]
				var to = path[i + 1]
				
				# Find component between these nodes
				for neighbor in tree_adj[from]:
					if neighbor.node == to:
						edge_path.append({
							"from": from,
							"to": to,
							"component": neighbor.component
						})
						break
			
			return edge_path
		
		for neighbor_info in tree_adj[current]:
			var neighbor = neighbor_info.node
			if not visited.has(neighbor):
				visited[neighbor] = true
				var new_path = path.duplicate()
				new_path.append(neighbor)
				queue.append(new_path)
	
	return null

func format_loop(loop):
	print("Format_loop - loop type: ", typeof(loop))
	print("Format_loop - loop value: ", loop)
	print("Format_loop - loop size: ", loop.size())
	
	var text = ""
	for i in range(loop.size()):
		var comp_id = loop[i]
		print("Comp_id at index ", i, ": ", comp_id, " (type: ", typeof(comp_id), ")")
		
		if not graph.components.has(comp_id):
			print("ERROR: Component ", comp_id, " not found in Graph.components")
			print("Available components: ", graph.components.keys())
			continue
		
		var comp = graph.components[comp_id]
		text += comp_id + " (" + comp.component_type + ")"
		if i < loop.size() - 1:
			text += " → "
	return text

func get_nodes_for_component(component_id):
	var start_port = component_id + "_start"
	var end_port = component_id + "_end"
	var connected_nodes = []
	
	for node_name in graph.nodes.keys():
		if start_port in graph.nodes[node_name]:
			connected_nodes.append(node_name)
		if end_port in graph.nodes[node_name]:
			connected_nodes.append(node_name)
	
	return connected_nodes

var detected_loops = []

func _on_button_2_pressed():
	detected_loops = detect_loops()
