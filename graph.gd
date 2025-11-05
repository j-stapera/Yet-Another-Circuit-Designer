extends Node

var connection = {}
var components = {}
var nodes = {}
var port_to_node = {}
var node_counter = 65 #ASCII Starting @ A


func _on_button_pressed():
	detect_components()
	detect_connections()
	initialize_nodes()
	merge_nodes()
	reorder_nodeName()
	#debug()


func detect_components():
	components.clear()
	for i in get_child_count():
		var node_id = get_child(i).id
		components[node_id] = get_child(i)
		i += 1
		print("node added: ", components)
		

func add_connection(start = {}, end = {}):
	connection[connection.size()] = [start, end]


func detect_connections():

	for i in connection.size():
		var first_componentID = connection[i][0].get("id")
		var second_componentID = connection[i][1].get("id")
		var first_componentPort = connection[i][0].get("port")
		var second_componentPort = connection[i][1].get("port")

		components[first_componentID].set_connection(first_componentPort, second_componentID, second_componentPort)
		components[second_componentID].set_connection(second_componentPort, first_componentID, first_componentPort)


func debug():
	#var start = (components["R0"].start_connections)
	#if start.has("R1"):
	#	print("true")
	#for key in components.keys():
	#	print(key)
	#	print("Node ", components[key], " has the starting connections: ", components[key].start_connections, " and end connections: ", components[key].end_connections)
	pass

## UnionFind algorithm. Each component's terminals start as their own node

func initialize_nodes():
	port_to_node.clear()
	nodes.clear()
	
	for component_id in components.keys():
		var start_port = component_id + "_start"
		var end_port = component_id + "_end"
		
		var node_name = String.chr(node_counter)
		port_to_node[start_port] = node_name
		nodes[node_name] = [start_port]
		node_counter += 1
		
		node_name = String.chr(node_counter)
		port_to_node[end_port] = node_name
		nodes[node_name] = [end_port]
		node_counter += 1

## Go through each connection and assign ports to nodes based on similar connections

func merge_nodes():
	for component_id in components.keys():
		var component = components[component_id]
		
		for connected_id in component.start_connections.keys():
			var connected_port = component.start_connections[connected_id]
			var port1 = component_id + "_start"
			var port2 = connected_id + "_" + connected_port
			merge_ports(port1, port2)
		
		for connected_id in component.end_connections.keys():
			var connected_port = component.end_connections[connected_id]
			var port1 = component_id + "_end"
			var port2 = connected_id + "_" + connected_port
			merge_ports(port1, port2)

func merge_ports(port1, port2):
	var node1 = port_to_node[port1]
	var node2 = port_to_node[port2]
	
	if node1 == node2:
		return
	
	for port in nodes[node2]:
		nodes[node1].append(port)
		port_to_node[port] = node1
		
	nodes.erase(node2)

func reorder_nodeName():
	var old_nodes = nodes.duplicate()
	nodes.clear()
	port_to_node.clear()
	var new_counter = 65
	
	for old_node_name in old_nodes.keys():
		var new_node_name = String.chr(new_counter)
		nodes[new_node_name] = old_nodes[old_node_name]
		
		for port in old_nodes[old_node_name]:
			port_to_node[port] = new_node_name
		
		new_counter += 1
	
	print(nodes)
