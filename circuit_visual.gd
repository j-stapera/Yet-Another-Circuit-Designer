extends Window

# Circuit Visualizer - Populates your existing window scene
# Attach this to the root Control node in circuit_visual.tscn

@export var component_spacing := 150.0
@export var wire_color := Color.BLACK
@export var wire_thickness := 3.0

# Reference your existing containers from the scene
@onready var circuit_display = $HSplitContainer/PanelContainer/Circuit
@onready var solution_display = $HSplitContainer/ScrollContainer/VBoxContainer/RichTextLabel

var duplicated_components = {}
var node_positions = {}
var ground_node = ""

enum VisualizationMode {
	NODAL_ANALYSIS,
	MESH_ANALYSIS,
	SIMPLIFICATION
}

var current_mode = VisualizationMode.NODAL_ANALYSIS

func show_nodal_analysis(graph_node, solution_steps, node_indices, ground):
	ground_node = ground
	current_mode = VisualizationMode.NODAL_ANALYSIS
	
	# Populate circuit visualization
	await populate_circuit(graph_node)
	add_node_labels(graph_node.nodes)
	
	# Populate solution text
	populate_solution_text(solution_steps)
	
	# Show the control (if it's in a popup/window, show that instead)
	show()

func show_mesh_analysis(graph_node, solution_steps, loops: Array):
	current_mode = VisualizationMode.MESH_ANALYSIS
	
	# Populate circuit visualization
	await populate_circuit(graph_node)
	highlight_mesh_loops(loops)
	
	# Populate solution text
	populate_solution_text(solution_steps)
	
	# Show the control
	show()

func populate_circuit(graph_node):
	# Clear previous components
	for child in circuit_display.get_children():
		child.queue_free()
	
	duplicated_components.clear()
	node_positions.clear()
	
	# Calculate layout (waits for container to be ready)
	await calculate_layout(graph_node.nodes)
	
	# Group components by their connected nodes to handle series components
	var components_by_connection = {}
	for child in graph_node.get_children():
		if not child.has_method("get_value"):
			continue
		
		var component_id = child.id
		var connected_nodes = get_nodes_for_component(component_id, graph_node.nodes)
		if connected_nodes.size() >= 2:
			var connection_key = str(connected_nodes[0]) + "-" + str(connected_nodes[1])
			var reverse_key = str(connected_nodes[1]) + "-" + str(connected_nodes[0])
			
			# Use consistent key regardless of order
			var key = connection_key if connection_key < reverse_key else reverse_key
			
			if key not in components_by_connection:
				components_by_connection[key] = []
			components_by_connection[key].append({"id": component_id, "nodes": connected_nodes, "instance": child})
	
	# Duplicate and position components
	for connection_key in components_by_connection.keys():
		var components_list = components_by_connection[connection_key]
		var num_components = components_list.size()
		
		for i in range(num_components):
			var comp_data = components_list[i]
			var component_id = comp_data.id
			var connected_nodes = comp_data.nodes
			var child = comp_data.instance
			
			var duplicate = child.duplicate()
			circuit_display.add_child(duplicate)
			duplicated_components[component_id] = duplicate
			
			# Position components evenly along the connection
			var start_pos = node_positions[connected_nodes[0]]
			var end_pos = node_positions[connected_nodes[1]]
			
			# Divide the line into segments for multiple components
			var t = (i + 1.0) / (num_components + 1.0)  # Position along the line (0 to 1)
			var pos = start_pos.lerp(end_pos, t)
			
			print("Component ", component_id, " (", i+1, " of ", num_components, ") positioned at: ", pos)
			
			duplicate.position = pos
			duplicate.rotation = (end_pos - start_pos).normalized().angle()
	
	# Draw wires
	for component_id in graph_node.components.keys():
		var connected_nodes = get_nodes_for_component(component_id, graph_node.nodes)
		if connected_nodes.size() >= 2:
			var line = Line2D.new()
			line.add_point(node_positions[connected_nodes[0]])
			line.add_point(node_positions[connected_nodes[1]])
			line.default_color = wire_color
			line.width = wire_thickness
			line.z_index = -1
			circuit_display.add_child(line)
	
	circuit_display.queue_redraw()

func calculate_layout(graph_nodes):
	var node_list = graph_nodes.keys()
	
	print("Calculating layout for nodes: ", node_list)
	
	# Wait for the container to be ready and get its size
	await get_tree().process_frame
	var container_size = circuit_display.get_viewport_rect().size if circuit_display.get_viewport() else Vector2(400, 400)
	
	# Use a percentage of container size for spacing
	var available_width = container_size.x * 0.8  # Use 80% of width
	var available_height = container_size.y * 0.8
	var center = container_size / 2.0
	
	print("Container size: ", container_size)
	
	# For simple circuits (2-3 nodes), use linear layout
	if node_list.size() <= 3:
		var spacing = available_width / max(node_list.size(), 2)
		var start_x = center.x - (available_width / 2.0)
		
		for i in range(node_list.size()):
			var node_name = node_list[i]
			var x = start_x + (i * spacing) + (spacing / 2.0)
			var y = center.y
			node_positions[node_name] = Vector2(x, y)
			print("Node ", node_name, " positioned at: ", node_positions[node_name])
	else:
		# For larger circuits, use grid layout
		var grid_size = ceil(sqrt(node_list.size()))
		var spacing_x = available_width / grid_size
		var spacing_y = available_height / grid_size
		var start_x = center.x - (available_width / 2.0)
		var start_y = center.y - (available_height / 2.0)
		
		for i in range(node_list.size()):
			var node_name = node_list[i]
			var grid_x = i % int(grid_size)
			var grid_y = i / int(grid_size)
			var x = start_x + (grid_x * spacing_x) + (spacing_x / 2.0)
			var y = start_y + (grid_y * spacing_y) + (spacing_y / 2.0)
			node_positions[node_name] = Vector2(x, y)
			print("Node ", node_name, " positioned at: ", node_positions[node_name])

func add_node_labels(graph_nodes):
	for node_name in node_positions.keys():
		var pos = node_positions[node_name]
		
		# Node circle
		var circle = ColorRect.new()
		circle.size = Vector2(12, 12)
		circle.position = pos - Vector2(6, 6)
		circle.color = Color.DARK_GREEN if node_name == ground_node else Color.BLACK
		circuit_display.add_child(circle)
		
		# Label
		var label = Label.new()
		label.text = node_name
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.BLUE)
		
		var panel = PanelContainer.new()
		panel.position = pos + Vector2(-25, -50)
		panel.add_child(label)
		circuit_display.add_child(panel)
		
		# Ground symbol
		if node_name == ground_node:
			add_ground_lines(pos)

func add_ground_lines(pos: Vector2):
	for i in range(3):
		var line = Line2D.new()
		var width = 30 - (i * 10)
		var y_offset = 20 + (i * 5)
		line.add_point(pos + Vector2(-width/2, y_offset))
		line.add_point(pos + Vector2(width/2, y_offset))
		line.default_color = Color.DARK_GREEN
		line.width = 3.0 - i
		circuit_display.add_child(line)

func highlight_mesh_loops(loops: Array):
	var colors = [
		Color(1.0, 0.3, 0.3, 0.7),
		Color(0.3, 1.0, 0.3, 0.7),
		Color(1.0, 0.6, 0.2, 0.7),
		Color(0.6, 0.3, 1.0, 0.7),
		Color(0.3, 0.8, 1.0, 0.7)
	]
	
	for i in range(loops.size()):
		var loop_color = colors[i % colors.size()]
		
		# Highlight components in loop
		for component_id in loops[i]:
			if component_id in duplicated_components:
				duplicated_components[component_id].modulate = loop_color
		
		# Add loop label
		var center = Vector2.ZERO
		var count = 0
		for component_id in loops[i]:
			if component_id in duplicated_components:
				center += duplicated_components[component_id].position
				count += 1
		
		if count > 0:
			center /= count
			var label = Label.new()
			label.text = "Loop " + str(i + 1)
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", Color(loop_color.r, loop_color.g, loop_color.b, 1.0))
			label.position = center - Vector2(30, 10)
			circuit_display.add_child(label)

func populate_solution_text(solution_steps):
	solution_display.bbcode_enabled = true
	solution_display.fit_content = true
	
	var text = ""
	for step in solution_steps:
		if step.type == "step":
			text += "[b][font_size=18][color=#4A90E2]" + step.title + "[/color][/font_size][/b]\n"
			if "description" in step:
				text += "[i]" + step.description + "[/i]\n"
		elif step.type == "result":
			text += step.text + "\n"
		text += "\n"
	
	solution_display.text = text

func get_nodes_for_component(component_id, graph_nodes):
	var start_port = component_id + "_start"
	var end_port = component_id + "_end"
	var connected_nodes = []
	
	for node_name in graph_nodes.keys():
		if start_port in graph_nodes[node_name]:
			connected_nodes.append(node_name)
		if end_port in graph_nodes[node_name]:
			connected_nodes.append(node_name)
	
	return connected_nodes
