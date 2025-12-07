extends Line2D

const GRID_SIZE = 32

var points_list = []
var component_list = []

func get_save_data() -> Dictionary:
	var points_to_save = []
	for i in range(get_point_count()):
		var point = get_point_position(i)
		points_to_save.append({"x": point.x, "y": point.y})
	
	return {
		"points": points_to_save,
		"components": component_list
	}


func load_save_data(data, graph):
	points_list = data["points"].duplicate()
	component_list = data["components"].duplicate()
	print("Loading wire with data: ", data)
	print("Points type: ", typeof(data["points"][0]) if data["points"].size() > 0 else "empty")
	clear_points()
	for point in points_list:
		if point is Dictionary:
			add_point(Vector2(point.x, point.y))
		elif point is Vector2:
			add_point(point)
		elif point is Array:
			add_point(Vector2(point[0], point[1]))
	
	var part1 = component_list[0].split("_")
	var part2 = component_list[1].split("_")
		
	var start = {"id": part1[0], "port": part1[1]}
	var end = {"id": part2[0], "port": part2[1]}
	
	graph.add_connection(start, end)
	default_color = Color.WHITE
	width = 4

func draw_wire_segment(start: Vector2, end: Vector2):
	add_point(start)
	add_point(end)
	points_list.append(start)
	points_list.append(end)

func clear_wire():
	clear_points()
	points_list.clear()

func finalize_wire():
	default_color = Color.WHITE
	width = 4

func add_connection(start, end):
	component_list.append(start["id"] + "_" + start["port"])
	component_list.append(end["id"] + "_" + end["port"])
	component_list.sort()
	
