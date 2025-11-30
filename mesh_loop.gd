extends Node

var mesh_currents = []
var loops = []
var solution_steps = []
@onready var loop_detection = $"../Loop Detection"
@onready var Graph = $"../Graph"
@onready var solver = $"../Solver"

func add_step(title, description = ""):
	solution_steps.append({
		"type": "step",
		"title": title,
		"description": description
	})

func add_step_result(text):
	solution_steps.append({
		"type": "result",
		"text": text
	})

func add_step_equation(equation_text):
	solution_steps.append({
		"type": "equation",
		"text": equation_text
	})
	
func solve_mesh_analysis():
	if loops.size() == 0:
		print("ERROR: No loops detected. Run detect_loops() first.")
		return
	
	solution_steps.clear()
	
	add_step("Step 1: Identify Independent Meshes", "Found " + str(loops.size()) + " independent mesh loops")
	add_step_result(format_all_meshes())
	
	add_step("Step 2: Assign Mesh Current Variables", "Each mesh gets its own current variable flowing clockwise")
	for i in range(loops.size()):
		add_step_result("Mesh " + str(i + 1) + ": Current I" + str(i + 1) + " (clockwise)")
	
	add_step("Step 3: Write KVL Equations for Each Mesh", "Apply Kirchhoff's Voltage Law around each mesh")
	kvl_equations()
	
	add_step("Step 4: Form Matrix Equation [R][I] = [V]", "Organize equations into matrix form")
	var mesh_matrix = build_mesh_matrix()
	add_step_result(mesh_matrix["description"])
	add_step_result("\nMatrix Form:")
	add_step_result(mesh_matrix["matrix_display"])
	
	add_step("Step 5: Solve for Mesh Currents", "Use linear algebra to find all mesh currents")
	var solution = solve_mesh_system(mesh_matrix)
	add_step_result(solution["description"])
	
	add_step("Step 6: Determine Branch Currents", "Calculate actual current through each component")
	var branch_currents = calculate_branch_currents(solution["currents"])
	add_step_result(branch_currents["description"])
	
	add_step("Step 7: Calculate Component Voltages and Power", "Use Ohm's Law and branch currents")
	var component_values = mesh_component_values(branch_currents)
	add_step_result(component_values["description"])
	
	add_step("Step 8: Verify Solution", "Check KVL for each mesh")
	var verification = verify_mesh_solution(component_values)
	add_step_result(verification["description"])
	
	# Display solution window (matching nodal analysis)
	var soln_window = preload("res://solution_window.tscn").instantiate()
	add_child(soln_window)
	soln_window.populate_solution_text(solution_steps)
	
	return solution

func format_all_meshes():
	var text = ""
	for i in range(loops.size()):
		text += "Mesh " + str(i + 1) + ": " + loop_detection.format_loop(loops[i]) + "\n"
	return text

func assign_mesh_currents():
	var description = ""
	for i in range(loops.size()):
		description += "Mesh " + str(i + 1) + ": Current I" + str(i + 1) + " (clockwise)\n"
	
	return {
		"description": description
	}

func kvl_equations():
	for mesh_idx in range(loops.size()):
		var loop = loops[mesh_idx]
		add_step_result("\n--- Mesh " + str(mesh_idx + 1) + " KVL ---")
		
		var equation_parts = []
		
		for comp_id in loop:
			var comp = Graph.components[comp_id]
			
			if comp.component_type == "voltage_source":
				var V = comp.get_value()
				var direction = get_traversal_direction(comp_id, mesh_idx)
				
				if direction > 0:
					add_step_result("  Voltage source " + comp_id + " = +" + str(V) + "V (traverse with polarity)")
					equation_parts.append("+" + str(V))
				else:
					add_step_result("  Voltage source " + comp_id + " = -" + str(V) + "V (traverse against polarity)")
					equation_parts.append("-" + str(V))
			
			elif comp.component_type == "resistor":
				var R = comp.get_value()
				var shared_meshes = meshes_containing_component(comp_id)
				
				if shared_meshes.size() == 1:
					add_step_result("  Resistor " + comp_id + ": -I" + str(mesh_idx + 1) + " × " + str(R) + "Ω")
					equation_parts.append("-I" + str(mesh_idx + 1) + "×" + str(R))
				else:
					var resistor_desc = "  Resistor " + comp_id + " (shared): -I" + str(mesh_idx + 1) + " × " + str(R) + "Ω"
					var resistor_term = "-I" + str(mesh_idx + 1) + "×" + str(R)
					
					for other_mesh in shared_meshes:
						if other_mesh != mesh_idx:
							var direction = get_current_direction(comp_id, mesh_idx, other_mesh)
							
							##If they flow in same direction currents add, so voltage is subtracted. If direction is opposite then visa versa
							if direction > 0:
								resistor_term += " - I" + str(other_mesh + 1) + "×" + str(R)
								resistor_desc += " - I" + str(other_mesh + 1) + " × " + str(R) + "Ω"
							else:
								resistor_term += " + I" + str(other_mesh + 1) + "×" + str(R)
								resistor_desc += " + I" + str(other_mesh + 1) + " × " + str(R) + "Ω"
					
					add_step_result(resistor_desc)
					equation_parts.append(resistor_term)
			
			##I havent fully tested a current source with mesh loop analysis
			elif comp.component_type == "current_source":
				var I_src = comp.get_value()
				add_step_result("  Current source " + comp_id + " = " + str(I_src) + "A")
				equation_parts.append("(constrained by " + comp_id + ")")
		
		var equation = " ".join(equation_parts) + " = 0"
		add_step_result("\nEquation " + str(mesh_idx + 1) + ":")
		add_step_equation(equation)
	var description = ""
	var equations = []
	
	for mesh_idx in range(loops.size()):
		var loop = loops[mesh_idx]
		var equation_parts = []
		
		for comp_id in loop:
			var comp = Graph.components[comp_id]
			
			if comp.component_type == "voltage_source":
				var V = comp.get_value()
				var direction = get_traversal_direction(comp_id, mesh_idx)
				
				if direction > 0:
					equation_parts.append("+" + str(V))
				else:
					equation_parts.append("-" + str(V))
			
			elif comp.component_type == "resistor":
				var R = comp.get_value()
				var shared_meshes = meshes_containing_component(comp_id)
				
				if shared_meshes.size() == 1:
					equation_parts.append("-I" + str(mesh_idx + 1) + "×" + str(R))
				else:
					var resistor_term = "-I" + str(mesh_idx + 1) + "×" + str(R)
					
					for other_mesh in shared_meshes:
						if other_mesh != mesh_idx:
							var direction = get_current_direction(comp_id, mesh_idx, other_mesh)
							if direction > 0:
								resistor_term += " - I" + str(other_mesh + 1) + "×" + str(R)
							else:
								resistor_term += " + I" + str(other_mesh + 1) + "×" + str(R)
					
					equation_parts.append(resistor_term)
		
		var equation = " ".join(equation_parts) + " = 0"
		equations.append(equation)
	
	return {
		"description": description,
		"equations": equations
	}


func meshes_containing_component(comp_id):
	var meshes = []
	for i in range(loops.size()):
		if comp_id in loops[i]:
			meshes.append(i)
	return meshes

## Determine if mesh traverses component from start->end (+1) or end->start (-1)
func get_traversal_direction(comp_id, mesh_idx):
	var loop = loops[mesh_idx]
	var comp_nodes = solver.get_nodes_for_component(comp_id)
	var start_node = comp_nodes[0]
	var end_node = comp_nodes[1]
	
	var comp_index = loop.find(comp_id)
	if comp_index == -1:
		print("ERROR: Component ", comp_id, " not found in mesh ", mesh_idx)
		return 1.0
	
	var prev_comp_id = loop[(comp_index - 1 + loop.size()) % loop.size()]
	var next_comp_id = loop[(comp_index + 1) % loop.size()]
	var prev_nodes = solver.get_nodes_for_component(prev_comp_id)
	var next_nodes = solver.get_nodes_for_component(next_comp_id)
	
	var entry_node = null
	var exit_node = null
	
	for node in comp_nodes:
		if node in prev_nodes:
			entry_node = node
			break
	
	for node in comp_nodes:
		if node in next_nodes:
			exit_node = node
			break
	
	if entry_node == null or exit_node == null:
		print("ERROR: Could not determine traversal direction for ", comp_id, " in mesh ", mesh_idx)
		print("Entry node: ", entry_node, ", Exit node: ", exit_node)
		print("Component nodes: ", comp_nodes)
		print("Prev component nodes: ", prev_nodes)
		print("Next component nodes: ", next_nodes)
		return 1.0
	
	if entry_node == start_node and exit_node == end_node:
		return 1.0
	elif entry_node == end_node and exit_node == start_node:
		return -1.0
	else:
		# Shouldn't happen in a valid loop
		print("WARNING: Unusual traversal pattern for ", comp_id, " in mesh ", mesh_idx)
		print("  Entry: ", entry_node, " Exit: ", exit_node)
		print("  Start: ", start_node, " End: ", end_node)
		return 1.0

#Determine if the two meshes traverse this component in same or opposite directions
func get_current_direction(comp_id, mesh1_idx, mesh2_idx):
	var dir1 = get_traversal_direction(comp_id, mesh1_idx)
	var dir2 = get_traversal_direction(comp_id, mesh2_idx)
	
	print("Component ", comp_id, " direction in mesh ", mesh1_idx, " = ", dir1)
	print("Component ", comp_id, " direction in mesh ", mesh2_idx, " = ", dir2)
	
	if dir1 * dir2 > 0:
		# Same direction - currents add
		print("Currents flow in same direction through ", comp_id, " -> mutual R is positive")
		return 1.0
	else:
		# Opposite directions - currents subtract
		print("Currents flow in opposite directions through ", comp_id, " -> mutual R is negative")
		return -1.0

func build_mesh_matrix():
	var num_meshes = loops.size()
	var R_matrix = []
	var V_vector = []
	
	var description = "Building resistance matrix and voltage vector:\n\n"
	
	# Initialize
	for i in range(num_meshes):
		var row = []
		for j in range(num_meshes):
			row.append(0.0)
		R_matrix.append(row)
		V_vector.append(0.0)
	
	print("\nBUILDING MESH MATRIX WITH DIRECTION DETECTION\n")
	
	# Build mesh matrix
	for mesh_idx in range(num_meshes):
		var loop = loops[mesh_idx]
		var mesh_resistance = 0.0
		var mesh_voltage = 0.0
		
		print("Processing Mesh ", mesh_idx + 1, ": ", loop)
		
		for comp_id in loop:
			var comp = Graph.components[comp_id]
			
			if comp.component_type == "voltage_source":
				# Determine polarity based on traversal direction
				var direction = get_traversal_direction(comp_id, mesh_idx)
				var voltage_contribution = direction * comp.get_value()
				mesh_voltage += voltage_contribution
				
				print("  Voltage source ", comp_id, ": ", comp.get_value(), "V × ", direction, " = ", voltage_contribution, "V")
				description += "Mesh " + str(mesh_idx + 1) + " traverses " + comp_id + " with polarity factor " + str(direction) + "\n"
			
			elif comp.component_type == "resistor":
				var R = comp.get_value()
				
				# Add to self-resistance
				mesh_resistance += R
				print("  Resistor ", comp_id, ": ", R, "Ω added to self-resistance")
				
				# Check for mutual resistance with other meshes
				var meshes_with_comp = meshes_containing_component(comp_id)
				
				if meshes_with_comp.size() > 1:
					print("  ", comp_id, " is shared with meshes: ", meshes_with_comp)
					
					for other_mesh in meshes_with_comp:
						if other_mesh != mesh_idx:
							var direction = get_current_direction(comp_id, mesh_idx, other_mesh)
							R_matrix[mesh_idx][other_mesh] += direction * R
							
							print("  Mutual resistance with mesh ", other_mesh + 1, ": ", direction, " × ", R, "Ω = ", direction * R, "Ω")
		
		R_matrix[mesh_idx][mesh_idx] = mesh_resistance
		V_vector[mesh_idx] = mesh_voltage
		
		print("  Total self-resistance: ", mesh_resistance, "Ω")
		print("  Total voltage: ", mesh_voltage, "V")
		print()
	
	description += "\nResistance Matrix [R]:\n"
	for i in range(R_matrix.size()):
		description += "  Row " + str(i + 1) + ": " + str(R_matrix[i]) + "\n"
	
	description += "\nVoltage Vector [V]:\n"
	description += "  " + str(V_vector) + "\n"
	
	print("FINAL MATRIX")
	print("R matrix:")
	for row in R_matrix:
		print("  ", row)
	print("V vector: ", V_vector)
	print()
	
	return {
		"R_matrix": R_matrix,
		"V_vector": V_vector,
		"description": description,
		"matrix_display": format_matrix_equation(R_matrix, V_vector)
	}

func format_matrix_equation(R_matrix, V_vector):
	var text = "\n"
	for i in range(R_matrix.size()):
		text += "[ "
		for j in range(R_matrix[i].size()):
			text += ("%.1f" % R_matrix[i][j]) + " "
		text += "]   [ I" + str(i + 1) + " ]   [ " + ("%.1f" % V_vector[i]) + " ]\n"
	return text

func solve_mesh_system(mesh_matrix):
	var R = mesh_matrix.R_matrix
	var V = mesh_matrix.V_vector
	
	print("\nCALLING LINEAR SOLVER")
	print("Input R matrix: ", R)
	print("Input V vector: ", V)
	
	# Use the existing linear solver
	var currents = solver.solve_linear_system(R, V)
	
	print("\nSOLVER RETURNED")
	print("Currents: ", currents)
	
	if currents == null:
		print("ERROR: Solver returned null")
		return {
			"description": "ERROR: Could not solve mesh system (singular matrix or solver failure)",
			"results_text": "Solver failed",
			"currents": []
		}
	
	if currents.size() == 0:
		print("ERROR: Solver returned empty array")
		return {
			"description": "ERROR: Solver returned no solutions",
			"results_text": "No solutions found",
			"currents": []
		}
	
	mesh_currents = currents
	
	var description = "Solved mesh currents:\n"
	var results_text = ""
	
	for i in range(currents.size()):
		var current_val = currents[i]
		description += "I" + str(i + 1) + " = " + ("%.6f" % current_val) + " A\n"
		results_text += "I" + str(i + 1) + " = " + ("%.6f" % current_val) + " A\n"
	
	print("MESH CURRENTS SOLVED")
	print(results_text)
	
	return {
		"description": description,
		"results_text": results_text,
		"currents": currents
	}

func calculate_branch_currents(mesh_currents_array):
	var description = "Branch currents (actual current through each component):\n\n"
	var branch_currents = {}
	
	for comp_id in Graph.components.keys():
		var meshes_with_comp = meshes_containing_component(comp_id)
		
		if meshes_with_comp.size() == 1:
			## Component only in one mesh
			var mesh_idx = meshes_with_comp[0]
			branch_currents[comp_id] = mesh_currents_array[mesh_idx]
			description += comp_id + " = I" + str(mesh_idx + 1) + " = " + ("%.6f" % mesh_currents_array[mesh_idx]) + " A\n"
		
		elif meshes_with_comp.size() == 2:
			## Shared between two meshes
			var mesh1 = meshes_with_comp[0]
			var mesh2 = meshes_with_comp[1]
			var direction = get_current_direction(comp_id, mesh1, mesh2)
			var branch_current
			
			if direction > 0:
				branch_current = mesh_currents_array[mesh1] + mesh_currents_array[mesh2]
				description += comp_id + " = I" + str(mesh1 + 1) + " + I" + str(mesh2 + 1)
				description += " = " + ("%.6f" % mesh_currents_array[mesh1]) + " + " + ("%.6f" % mesh_currents_array[mesh2])
			else:
				branch_current = mesh_currents_array[mesh1] - mesh_currents_array[mesh2]
				description += comp_id + " = I" + str(mesh1 + 1) + " - I" + str(mesh2 + 1)
				description += " = " + ("%.6f" % mesh_currents_array[mesh1]) + " - " + ("%.6f" % mesh_currents_array[mesh2])
			
			branch_currents[comp_id] = branch_current
			description += " = " + ("%.6f" % branch_current) + " A\n"
	
	return {
		"description": description,
		"branch_currents": branch_currents
	}

func mesh_component_values(branch_currents_data):
	var description = "Component voltages and power:\n\n"
	var component_values = {}
	
	for comp_id in branch_currents_data.branch_currents.keys():
		var comp = Graph.components[comp_id]
		var current = branch_currents_data.branch_currents[comp_id]
		
		if comp.component_type == "resistor":
			var R = comp.get_value()
			var V = abs(current * R)
			var P = abs(current * current * R)
			
			component_values[comp_id] = {
				"voltage": V,
				"current": abs(current),
				"power": P
			}
			
			description += comp_id + " (" + str(R) + " Ω):\n"
			description += "  V = |I| × R = " + ("%.6f" % abs(current)) + " × " + str(R) + " = " + ("%.3f" % V) + " V\n"
			description += "  I = " + ("%.6f" % abs(current)) + " A\n"
			description += "  P = I² × R = " + ("%.3f" % P) + " W\n\n"
		
		elif comp.component_type == "voltage_source":
			var V = comp.get_value()
			var P = abs(V * current)
			
			component_values[comp_id] = {
				"voltage": V,
				"current": abs(current),
				"power": P
			}
			
			description += comp_id + " (" + str(V) + " V):\n"
			description += "  V = " + str(V) + " V (source)\n"
			description += "  I = " + ("%.6f" % abs(current)) + " A\n"
			description += "  P = " + ("%.3f" % P) + " W\n\n"
		
		elif comp.component_type == "current_source":
			var I = comp.get_value()
			component_values[comp_id] = {
				"current": I
			}
			
			description += comp_id + " (" + str(I) + " A):\n"
			description += "  I = " + str(I) + " A (source)\n\n"
	
	return {
		"description": description,
		"values": component_values
	}

func verify_mesh_solution(component_values_data):
	var description = "Verifying KVL for each mesh:\n\n"
	
	for mesh_idx in range(loops.size()):
		var loop = loops[mesh_idx]
		var voltage_sum = 0.0
		
		description += "Mesh " + str(mesh_idx + 1) + ":\n"
		
		for comp_id in loop:
			var comp = Graph.components[comp_id]
			
			if comp.component_type == "voltage_source":
				var V = comp.get_value()
				voltage_sum += V
				description += "  +" + comp_id + " = +" + str(V) + " V\n"
			
			elif comp.component_type == "resistor" and component_values_data.values.has(comp_id):
				var V = component_values_data.values[comp_id].voltage
				voltage_sum -= V
				description += "  -" + comp_id + " = -" + ("%.3f" % V) + " V\n"
		
		description += "  Sum = " + ("%.6f" % voltage_sum) + " V"
		
		if abs(voltage_sum) < 0.01:
			description += " ✓\n\n"
		else:
			description += " (possible rounding error or wrong answer)\n\n"
	
	return {
		"description": description
	}

func display_mesh_steps(steps):
	print("\nMESH ANALYSIS SOLUTION - STEP BY STEP")
	
	for step in steps:
		print("\n" + step.title)
		if step.description != "":
			print(step.description)
		if step.content != "":
			print("\n" + step.content)
		if step.equation != "":
			print("\n" + step.equation)


func run():
	loops = $"../Loop Detection".detect_loops()
	solve_mesh_analysis()
	analyze_voltage_source_directions()

func analyze_voltage_source_directions():
	print("\nVOLTAGE SOURCE DIRECTION ANALYSIS")
	
	for mesh_idx in range(loops.size()):
		var loop = loops[mesh_idx]
		for comp_id in loop:
			var comp = Graph.components[comp_id]
			if comp.component_type == "voltage_source":
				var nodes = solver.get_nodes_for_component(comp_id)
				print("Mesh ", mesh_idx + 1, " traverses ", comp_id, " from ", nodes[0], " to ", nodes[1])
