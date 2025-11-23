extends Node

@onready var Graph = $"../Graph"


func _on_button_pressed():
	var ground_node = select_ground_node()
	var node_indices = create_node_indices(ground_node)
	
	var num_nodes = node_indices.size()
	var num_voltage_sources = count_voltage_sources()
	var matrix_size = num_nodes + num_voltage_sources
	
	var matrices = initialize_matrices(matrix_size)
	var A = matrices["A"]
	var B = matrices["B"]
	
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
	
	var solution = solve_linear_system(A, B)
	display_results(solution, node_indices, ground_node)


func solve_linear_system(A, B):
	var n = A.size()
	var augmented = []
	
	for i in range(n):
		var row = A[i].duplicate()
		row.append(B[i])
		augmented.append(row)
	
	print("Initial augmented matrix:")
	print_matrix(augmented)
	
	#forward elimination
	for col in range(n):
		#find pivot
		var max_row = col
		for row in range(col + 1, n):
			if abs(augmented[row][col]) > abs(augmented[max_row][col]):
				max_row = row
		
		#swap rows
		if max_row != col:
			var temp = augmented[col]
			augmented[col] = augmented[max_row]
			augmented[max_row] = temp
		
		if abs(augmented[col][col]) < 1e-10:
			push_error("Matrix is singular at column " + str(col))
			return null
		
		#eliminate
		for row in range(col + 1, n):
			var factor = augmented[row][col] / augmented[col][col]
			for j in range(col, n + 1):
				augmented[row][j] -= factor * augmented[col][j]
	
	print("After forward elimination:")
	print_matrix(augmented)
	
	#back substitution
	var x = []
	for i in range(n):
		x.append(0.0)
	
	for i in range(n - 1, -1, -1):
		var sum = augmented[i][n]  #right-hand side
		
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

func display_results(solution, node_indices, ground_node):
	if solution == null:
		print("ERROR: Could not solve circuit (singular matrix)")
		return
	
	print("\nCIRCUIT ANALYSIS RESULTS")
	print("\nNode Voltages")
	print(ground_node, ": 0.000 V (Ground)")
	for node_name in node_indices.keys():
		var index = node_indices[node_name]
		var voltage = solution[index]
		print(node_name, ": ", "%.3f" % voltage, " V")
	
	var num_nodes = node_indices.size()
	var vs_index = 0
	print("\n--- Voltage Source Currents ---")
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "voltage_source":
			var current = solution[num_nodes + vs_index]
			print(component_id, ": ", "%.3f" % current, " A")
			vs_index += 1
			
	print("\nCurrent Sources")
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "current_source":
			var current = component.get_value()
			var voltage_info = calculate_current_source_voltage(component, solution, node_indices, ground_node)
			print(component_id, " (", current, " A):")
			print("  Voltage across: ", "%.3f" % voltage_info.voltage, " V")
			print("  Power: ", "%.3f" % voltage_info.power, " W")
			
	print("\nResistor Analysis")
	for component_id in Graph.components.keys():
		var component = Graph.components[component_id]
		if component.component_type == "resistor":
			var resistor_info = calculate_resistor_values(component, solution, node_indices, ground_node)
			print(component_id, " (", resistor_info.resistance, " Ω):")
			print("  Voltage: ", "%.3f" % resistor_info.voltage, " V")
			print("  Current: ", "%.3f" % resistor_info.current, " A")
			print("  Power: ", "%.3f" % resistor_info.power, " W")
