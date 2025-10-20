#File to store the graph representation of the connections in the graph.
#Design goals:
#Each component will be a node in the graph
#Each connection will be an edge in the graph. For instance, each
#resistor will have two edges (initially). One for the left side
#and one for the right side. The node itself will contain the resistance
extends Node
var num_nodes = 0 #Autoincrement key for getting new keys. Never, ever decrement.
var nodes = {} #dictonary. Put nodes as key:value pairs. Get key from num_nodes and increment num_nodes. Value is the element itself. Element should own a list of nodes this node is connected to. Identify the connected nodes by their key.

func addNode(node) -> int:
	nodes[num_nodes] = node
	num_nodes += 1
	regenerate_edges()
	return num_nodes - 1

func regenerate_edges() -> void:
	for nodekey in nodes.keys():
		print("TODO")
	
