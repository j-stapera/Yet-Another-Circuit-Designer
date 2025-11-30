extends Line2D

const GRID_SIZE = 32  # Adjust to your grid size

var points_list = []

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
	width = 3
