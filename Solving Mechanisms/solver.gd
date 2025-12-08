extends Node

@onready var Graph = $"../Graph"

#var circuit_scn = preload("res://circuit_visual.tscn")

var solution_steps = []
var equations = [] 
var variables = [] 


func run():
	solution_steps.clear()
	equations.clear()
	variables.clear()
	
	add_step("Step 1: Select Ground Node")
	var ground_node = select_ground_node()
	add_step_result("Ground node: " + ground_node + " = 0V")
	
	add_step("Step 2: Identify Unknown Variables")
	var node_indices = create_node_indices(ground_node)
	
	for node_name in node_indices.keys():
		variables.append("V" + node_name)
	
	var num_voltage_sources = count_voltage_sources()
	for i in range(num_voltage_sources):
		variables.append("I" + str(i + 1))
	
	add_step_result("Unknown variables: " + ", ".join(variables))
	

	add_step("Step 3: Apply KCL at Each Node")
	add_step_result("(Sum of currents leaving each node = 0)")
	build_symbolic_equations(node_indices, ground_node)
	

	add_step("Step 4: Solve System of Equations")
	display_system_of_equations()
	
	var num_nodes = node_indices.size()
	var matrix_size = num_nodes + num_voltage_sources
	var matrices = initialize_matrices(matrix_size)
	var A = matrices["A"]
	var B = matrices["B"]
	
	populate_matrices(A, B, node_indices, ground_node)
	var solution = solve_linear_system(A,B)
	

	add_step("Step 5: Solutions")
	
	display_results(solution, node_indices, ground_node)
	
	var debug = Graph.nodes.values()
	
	print(debug)
	highlight_wire_nodes()
	

func populate_matrices(A, B, node_indices, ground_node):
	var vs_counter = 0
	
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		
		if component.component_type == "resistor":
			add_resistor_to_matrix(A, component, node_indices)
		elif component.component_type == "voltage_source":
			add_voltage_source_to_matrix(A, B, component, node_indices, vs_counter)
			vs_counter += 1
		elif component.component_type == "current_source":
			add_current_source_to_matrix(B, component, node_indices)

func add_step(title):
	solution_steps.append({"type": "step", "title": title})

func add_step_result(text):
	solution_steps.append({"type": "result", "text": text})
	


func display_results(solution, node_indices, ground_node):
	var description = ""
	
	description += "\nNode Voltages:\n"
	description += ground_node + " = 0.000V (Ground)\n"
	
	for node_name in node_indices.keys():
		var index = node_indices[node_name]
		var voltage = solution[index]
		description += node_name + " = " + ("%.3f" % voltage) + "V\n"
	
	description += "\n"
	
	var num_nodes = node_indices.size()
	var vs_index = 0
	var has_voltage_sources = false
	
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "voltage_source":
			has_voltage_sources = true
			break
	
	if has_voltage_sources:
		description += "Voltage Source Currents:\n"
		
		vs_index = 0
		for component_id in Graph.components.keys():
			var component = Graph.components[component_id]
			if component.component_type == "voltage_source":
				var current = solution[num_nodes + vs_index]
				description += component_id + " = " + ("%.3f" % current) + "A\n"
				vs_index += 1
		
		description += "\n"
	
	description += "Component voltages and power:\n\n"
	
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "resistor":
			var info = calculate_resistor_values(component, solution, node_indices, ground_node)
			component.set_current(info.current)
			
			description += component_id + " (" + str(info.resistance) + " Ω):\n"
			description += "  V = |I| × R = " + ("%.6f" % info.current) + " × " + str(info.resistance) + " = " + ("%.3f" % info.voltage) + " V\n"
			description += "  I = " + ("%.6f" % info.current) + " A\n"
			description += "  P = I² × R = " + ("%.3f" % info.power) + " W\n\n"
	
	vs_index = 0
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "voltage_source":
			var V = component.get_value()
			var current = solution[num_nodes + vs_index]
			var P = abs(V * current)
			
			description += component_id + " (" + str(V) + " V):\n"
			description += "  V = " + str(V) + " V (source)\n"
			description += "  I = " + ("%.6f" % abs(current)) + " A\n"
			description += "  P = " + ("%.3f" % P) + " W\n\n"
			vs_index += 1
	
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "current_source":
			var I = component.get_value()
			var current_info = calculate_current_source_voltage(component, solution, node_indices, ground_node)
			
			description += component_id + " (" + str(I) + " A):\n"
			description += "  V = " + ("%.3f" % current_info.voltage) + " V\n"
			description += "  I = " + str(I) + " A (source)\n"
			description += "  P = " + ("%.3f" % current_info.power) + " W\n\n"
	
	add_step_result(description)
	
	var soln_window = preload("res://popup_windows/solution_window.tscn").instantiate()
	add_child(soln_window)
	soln_window.populate_solution_text(solution_steps)


func display_system_of_equations():
	var description = "\nSystem of " + str(equations.size()) + " equations with " + str(variables.size()) + " unknowns:\n\n"
	
	for i in range(equations.size()):
		description += "  (" + str(i + 1) + ")  " + equations[i] + "\n"
	
	description += "\n"
	
	add_step_result(description)

func build_symbolic_equations(node_indices, ground_node):
	var equation_number = 1
	var description = ""
	
	description += "\nKCL Equations (node-by-node):\n\n"
	
	# KCL equations for each node
	for node_name in node_indices.keys():
		description += "Node " + node_name + ":\n"
		var eq_components = kcl_equations(node_name, ground_node)
		
		# Show the detailed breakdown
		description += "  Currents leaving node " + node_name + ":\n"
		for term_desc in eq_components["term_descriptions"]:
			description += "    " + term_desc + "\n"
		
		# Show the final equation
		var eq_str = eq_components["equation"]
		equations.append(eq_str)
		description += "  Equation " + str(equation_number) + ": " + eq_str + "\n"
		equation_number += 1
	
	description += "\nVoltage Source Constraint Equations:\n\n"
	
	# Voltage source constraint equations
	var vs_counter = 1
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "voltage_source":
			var eq_details = build_voltage_source_equations(component_id, ground_node, vs_counter)
			
			description += component_id + " (" + str(component.get_value()) + " V):\n"
			description += "  " + eq_details["description"] + "\n"
			
			var eq_str = eq_details["equation"]
			equations.append(eq_str)
			description += "  Equation " + str(equation_number) + ": " + eq_str + "\n"
			equation_number += 1
			vs_counter += 1
	
	add_step_result(description)
	


func kcl_equations(node_name, ground_node):
	var terms = []
	var term_descriptions = []
	
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		var nodes = get_nodes_for_component(component_id)
		var node1 = nodes[0]  # start port
		var node2 = nodes[1]  # end port
		
		var connected_at_start = (node1 == node_name)
		var connected_at_end = (node2 == node_name)
		
		if not connected_at_start and not connected_at_end:
			continue
		
		if component.component_type == "resistor":
			var R = component.get_value()
			var other_node = node2 if connected_at_start else node1
			var term = ""
			var description = ""
			
			if other_node == ground_node:
				term = "V" + node_name + "/" + str(R)
				description = component_id + ": (V" + node_name + " - 0) / " + str(R) + " Ω"
			else:
				term = "(V" + node_name + " - V" + other_node + ")/" + str(R)
				description = component_id + ": (V" + node_name + " - V" + other_node + ") / " + str(R) + " Ω"
			
			terms.append(term)
			term_descriptions.append(description)
		
		elif component.component_type == "current_source":
			var I = component.get_value()
			var description = component_id + ": "
			
			if connected_at_start:
				terms.append(str(I))
				description += str(I) + " A (leaving node)"
			else:
				terms.append(str(-I))
				description += str(-I) + " A (entering node)"
			
			term_descriptions.append(description)
		
		elif component.component_type == "voltage_source":
			var vs_index = get_voltage_source_index(component_id)
			var I_name = "I" + str(vs_index + 1)
			var description = component_id + ": "
			
			if connected_at_start:
				terms.append(I_name)
				description += I_name + " (current leaving node)"
			else:
				terms.append("-" + I_name)
				description += "-" + I_name + " (current entering node)"
			
			term_descriptions.append(description)
	
	var equation = " + ".join(terms) + " = 0"
	equation = equation.replace(" + -", " - ")
	
	return {
		"equation": equation,
		"term_descriptions": term_descriptions
	}


func build_voltage_source_equations(component_id, ground_node, vs_number):
	var component = Graph.components[component_id]
	var V = component.get_value()
	var nodes = get_nodes_for_component(component_id)
	var neg_node = nodes[0]
	var pos_node = nodes[1]
	
	var left_side = ""
	var description = "Voltage from " + neg_node + " (−) to " + pos_node + " (+) must equal " + str(V) + " V"
	
	if pos_node == ground_node:
		left_side = "0"
	else:
		left_side = "V" + pos_node
	
	left_side += " - "
	
	if neg_node == ground_node:
		left_side += "0"
	else:
		left_side += "V" + neg_node
	
	left_side = left_side.replace(" - 0", "")
	if left_side == "0 - ":
		left_side = "-"
	
	return {
		"equation": left_side + " = " + str(V),
		"description": description
	}


func solve_linear_system(A, B):
	var n = A.size()
	var augmented = []
	
	for i in range(n):
		var row = A[i].duplicate()
		row.append(B[i])
		augmented.append(row)
	
	print("Initial augmented matrix:")
	print_matrix(augmented)
	
	for col in range(n):
		var max_row = col
		for row in range(col + 1, n):
			if abs(augmented[row][col]) > abs(augmented[max_row][col]):
				max_row = row
		
		if max_row != col:
			var temp = augmented[col]
			augmented[col] = augmented[max_row]
			augmented[max_row] = temp
		
		if abs(augmented[col][col]) < 1e-10:
			push_error("Matrix is singular at column " + str(col))
			return null
		
		for row in range(col + 1, n):
			var factor = augmented[row][col] / augmented[col][col]
			for j in range(col, n + 1):
				augmented[row][j] -= factor * augmented[col][j]
	
	print("After forward elimination:")
	print_matrix(augmented)
	
	var x = []
	for i in range(n):
		x.append(0.0)
	
	for i in range(n - 1, -1, -1):
		var sum = augmented[i][n]
		
		for j in range(i + 1, n):
			sum -= augmented[i][j] * x[j]
		
		x[i] = sum / augmented[i][i]
	
	return x

func print_matrix(matrix):
	for row in matrix:
		print(row)

func count_voltage_sources():
	var count = 0
	for component_id in Graph.components.keys():
		if Graph.components[component_id].component_type == "voltage_source":
			count += 1
	return count

func select_ground_node():
	var max_connections = 0
	var ground_node = "A"
	
	for node_name in Graph.nodes.keys():
		var connection_count = Graph.nodes[node_name].size()
		if connection_count > max_connections:
			max_connections = connection_count
			ground_node = node_name
	
	print("Ground node selected: ", ground_node)
	return ground_node

func create_node_indices(ground_node):
	var node_indices = {}
	var index = 0
	
	for node_name in Graph.nodes.keys():
		if node_name != ground_node:
			node_indices[node_name] = index
			index += 1
	
	return node_indices

func calculate_matrix_size(node_indices, components):
	var num_nodes = node_indices.size()
	var num_voltage_sources = 0
	
	for component_id in components.keys():
		if components[component_id].component_type == "voltage_source":
			num_voltage_sources += 1
	
	var matrix_size = num_nodes + num_voltage_sources
	return matrix_size

func initialize_matrices(size):
	var A = []
	var B = []
	
	for i in range(size):
		var row = []
		for j in range(size):
			row.append(0.0)
		A.append(row)
	
	for i in range(size):
		B.append(0.0)
	
	return {"A": A, "B": B}
	
func add_resistor_to_matrix(A, component, node_indices):
	var R = component.get_value()
	var G = 1.0 / R  #Conductance
	var nodes_connected = get_nodes_for_component(component.id)
	var node1 = nodes_connected[0]
	var node2 = nodes_connected[1]
	
	var idx1 = node_indices.get(node1, -1)
	var idx2 = node_indices.get(node2, -1)
	
	## Add conductance to diagonal
	if idx1 >= 0:
		A[idx1][idx1] += G
	if idx2 >= 0:
		A[idx2][idx2] += G
	
	## Subtract conductance from off-diagonal
	if idx1 >= 0 and idx2 >= 0:
		A[idx1][idx2] -= G
		A[idx2][idx1] -= G
		
func add_voltage_source_to_matrix(A, B, component, node_indices, vs_index):
	var V = component.get_value()
	var num_nodes = node_indices.size()
	var current_var_index = num_nodes + vs_index
	
	var nodes_connected = get_nodes_for_component(component.id)
	var positive_node = nodes_connected[1]  
	var negative_node = nodes_connected[0]  
	
	var pos_idx = node_indices.get(positive_node, -1)
	var neg_idx = node_indices.get(negative_node, -1)
	
	if pos_idx >= 0:
		A[pos_idx][current_var_index] += 1.0
		A[current_var_index][pos_idx] += 1.0
	
	if neg_idx >= 0:
		A[neg_idx][current_var_index] -= 1.0
		A[current_var_index][neg_idx] -= 1.0
	
	## Set voltage constraint: V_pos - V_neg = V
	B[current_var_index] = V

func add_current_source_to_matrix(B, component, node_indices):
	var I = component.get_value()
	var nodes_connected = get_nodes_for_component(component.id)
	var source_node = nodes_connected[0]
	var sink_node = nodes_connected[1]
	
	var source_idx = node_indices.get(source_node, -1)
	var sink_idx = node_indices.get(sink_node, -1)
	
	## Add current to source node (current leaving = positive)
	if source_idx >= 0:
		B[source_idx] += I
	
	## Subtract current from sink node (current entering = negative)
	if sink_idx >= 0:
		B[sink_idx] -= I

func calculate_current_source_voltage(component, solution, node_indices, ground_node):
	var I = component.get_value()
	var connected_nodes = get_nodes_for_component(component.id)
	var node1 = connected_nodes[0]
	var node2 = connected_nodes[1]
	
	var V1 = 0.0
	var V2 = 0.0
	
	if node1 != ground_node:
		V1 = solution[node_indices[node1]]
	if node2 != ground_node:
		V2 = solution[node_indices[node2]]
	
	var voltage = V1 - V2
	var power = abs(voltage * I)
	
	return {
		"voltage": abs(voltage),
		"power": power
	}

func get_voltage_source_index(component_id):
	var index = 0
	for cid in Graph.components.keys():
		if cid == component_id:
			return index
		if Graph.components[cid].component_type == "voltage_source":
			index += 1
	return -1

func get_nodes_for_component(component_id):
	var start_port = component_id + "_start"
	var end_port = component_id + "_end"
	var connected_nodes = []
	
	for node_name in Graph.nodes.keys():
		if start_port in Graph.nodes[node_name]:
			connected_nodes.append(node_name)
		if end_port in Graph.nodes[node_name]:
			connected_nodes.append(node_name)
	
	return connected_nodes

var wire_nodes = {}

func highlight_wire_nodes():
	wire_nodes.clear()
	for child in get_parent().get_children():
		if child is Line2D:
			print(child)
			print("wire connections", child.component_list)
			
			for node_key in Graph.nodes.keys():
				var node_connection = Graph.nodes[node_key]
				print("Node connections", node_connection)
				
				if node_connection.has(child.component_list[0]) && node_connection.has(child.component_list[1]):
					if not wire_nodes.has(node_key):
						wire_nodes[node_key] = []
					wire_nodes[node_key].append(child)
	print(wire_nodes)
	var node_colors = {}
	var color_index = 0

	for node in wire_nodes.keys():
		if not node_colors.has(node):
			node_colors[node] = generate_color(color_index)
			color_index += 1
	
		for wire in wire_nodes.get(node):
			wire.default_color = node_colors[node]
	
		if wire_nodes[node].size() > 0:
			var first_wire = wire_nodes[node][0]
			var label = Label.new()
			label.text = node
			label.add_theme_color_override("font_color", node_colors[node])
		
			if first_wire.points.size() > 0:
				var midpoint = first_wire.points[first_wire.points.size() / 2]
				label.position = midpoint + Vector2(20, -20)  
				
			first_wire.add_child(label)

func generate_color(index: int) -> Color:
	var hue = float(index) * 0.618033988749895
	hue = fmod(hue, 1.0)
	return Color.from_hsv(hue, 0.8, 0.9)

func calculate_resistor_values(component, solution, node_indices, ground_node):
	var R = component.get_value()
	var connected_nodes = get_nodes_for_component(component.id)
	var node1 = connected_nodes[0]
	var node2 = connected_nodes[1]
	
	var V1 = 0.0
	var V2 = 0.0
	
	if node1 != ground_node:
		V1 = solution[node_indices[node1]]
	
	if node2 != ground_node:
		V2 = solution[node_indices[node2]]
	
	var voltage_across = V1 - V2
	var current = voltage_across / R
	var power = current * voltage_across
	
	return {
		"resistance": R,
		"voltage": abs(voltage_across),
		"current": abs(current),
		"power": abs(power)
	}
