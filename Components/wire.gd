extends Line2D

## Need a proper algorithm to determine how to draw the wire. Currently just goes to the midpoint then matches y position
func draw_wire(start: Vector2, end: Vector2):
	print("Signal recieved")
	var midpoint = (start.x + end.x) / 2
	var pointB = Vector2(midpoint, start.y)
	var pointC = Vector2(midpoint, end.y)
	
	add_point(start)
	add_point(pointB)
	add_point(pointC)
	add_point(end)
	
	print("wire drawn from start ", start, " to ", pointB, " to ", pointC, " to ", end)


#func draw_wire():
	#if Global.wire_mode:
		#pass
		#
