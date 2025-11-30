extends Node2D

## Initialize for component selection and its holo counterpart
var element_selected: PackedScene = null
var holo_node: Node2D = null
var wire: PackedScene = null


#var placing_wire = false
var wire_instance
var start_position = Vector2(0, 0)
var end_position = Vector2(0, 0)
var start = {}
var end = {}
var ui_hover = false
#signal wire_placed(start: Vector2, end: Vector2)
#signal add_connection(start, end)

## Load in all the scenes. Each component will be preloaded in this section
var resistor_scn = preload("res://Components/Resistor/resistor.tscn")
var resistor_holoscn = preload("res://Components/Resistor/resistor_holo.tscn")
var voltageSource_scn = preload("res://Components/Voltage Source/voltage_source.tscn")
var voltageSource_holoscn = preload("res://Components/Voltage Source/vs_holo.tscn")
var currentSource_scn = preload("res://Components/Current Source/current_source.tscn")
var currentSource_holoscn = preload("res://Components/Current Source/current_holo.tscn")
var wire_scn = preload("res://Components/wire.tscn")
var element_rotation
var current_holo_scene = null
@onready var connectiongraph = get_node("ConnectionGraph")

## Need to expand the container and create a function to limit placing components when the mouse enters the container ***
var placeable = true

## Button presses for each component will follow the same structure
func _on_button_resistor_pressed():
	select_element(resistor_scn, resistor_holoscn)

func _on_button_voltage_source_pressed():
	select_element(voltageSource_scn, voltageSource_holoscn)
	
func _on_button_wire_pressed():
	cancel_selection()
	Global.wire_mode = true
	
func _on_button_current_source_pressed():
	select_element(currentSource_scn, currentSource_holoscn)


## Assign the currently selected component based on the button pressed
func select_element(scene: PackedScene, holo: PackedScene):
	if holo_node and holo_node.is_inside_tree():
		holo_node.queue_free()
	
	element_selected = scene
	current_holo_scene = holo
	holo_node = holo.instantiate()
	add_child(holo_node)
	holo_node.visible = true
	holo_node.position = get_global_mouse_position()


func snap_to_grid(pos):
	return Vector2(round(pos.x / Global.grid_size) * Global.grid_size, round(pos.y / Global.grid_size) * Global.grid_size)

func snap_to_grid_component(pos):
	var half_grid = Global.grid_size / 2.0
	var rotation_mod = fmod(abs(holo_node.rotation_degrees), 180)
	
	# Determine if component is currently in "rotated" state (90° or 270°)
	var is_rotated_90 = (rotation_mod > 45 && rotation_mod < 135)
	
	# Resistor: horizontal at 0°, vertical at 90°
	# Voltage source: vertical at 0°, horizontal at 90°
	var should_be_vertical = false
	
	if current_holo_scene == resistor_holoscn:
		should_be_vertical = is_rotated_90  # Vertical when rotated 90°
	elif current_holo_scene == voltageSource_holoscn:
		should_be_vertical = !is_rotated_90  # Vertical when NOT rotated
	
	if should_be_vertical:
		# Snap to vertical gridlines (offset Y)
		return Vector2(
			round(pos.x / Global.grid_size) * Global.grid_size,
			round(pos.y / Global.grid_size) * Global.grid_size + half_grid
		)
	else:
		# Snap to horizontal gridlines (offset X)
		return Vector2(
			round(pos.x / Global.grid_size) * Global.grid_size + half_grid,
			round(pos.y / Global.grid_size) * Global.grid_size
		)
func _process(_delta):

	if element_selected and placeable:
		holo_node.position = snap_to_grid_component(get_global_mouse_position())
		handle_element()
	ui_movement()
	

	
	if Input.is_action_just_pressed("Cancel"):
		cancel_selection()
	
	if Global.placing_wire and wire_instance:
		# Update preview wire to follow mouse
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)
		update_wire_preview(snapped_pos)
		

## All actions while an component is currently selected
func handle_element():
	if Input.is_action_just_pressed("Rotate Left"):
		holo_node.rotation_degrees -= 90
	if Input.is_action_just_pressed("Rotate Right"):
		holo_node.rotation_degrees += 90

	if Input.is_action_just_pressed("Place"):
		var instance = element_selected.instantiate()
		instance.position = holo_node.position
		instance.rotation = holo_node.rotation
		$Graph.add_child(instance)
		instance.port_clicked.connect(_on_port_clicked)


## Cancels the currently selected component. Will only trigger when an element is also selected, so RMB functionality is still available
func cancel_selection():
	Global.wire_mode = false
	Global.placing_wire = false
	if holo_node and holo_node.is_inside_tree():
		holo_node.queue_free()
	holo_node = null
	element_selected = null

## Handles the wiring between components. Still needs to be redone.

var wire_points = []


func update_wire_preview(mouse_pos: Vector2):
	# Clear current preview
	wire_instance.clear_wire()
	
	# Redraw all existing segments
	for i in range(len(wire_points) - 1):
		var point_a = wire_points[i]
		var point_b = wire_points[i + 1]
		
		# Draw orthogonal segments between placed points
		var midpoint_x = (point_a.x + point_b.x) / 2
		wire_instance.add_point(point_a)
		wire_instance.add_point(Vector2(midpoint_x, point_a.y))
		wire_instance.add_point(Vector2(midpoint_x, point_b.y))
		wire_instance.add_point(point_b)
	
	# Add preview segment from last point to mouse
	if wire_points.size() > 0:
		var last_point = wire_points[-1]
		
		# Draw orthogonal path (horizontal then vertical)
		var midpoint_x = (last_point.x + mouse_pos.x) / 2
		wire_instance.add_point(last_point)
		wire_instance.add_point(Vector2(midpoint_x, last_point.y))
		wire_instance.add_point(Vector2(midpoint_x, mouse_pos.y))
		wire_instance.add_point(mouse_pos)



func _on_port_clicked(component_id, port_name, port_position):
	if not Global.placing_wire and Global.wire_mode:
		# Start wire placement
		start = { "id": component_id, "port": port_name }
		start_position = port_position
		wire_instance = wire_scn.instantiate()
		wire_instance.default_color = Color(0.0, 0.0, 0.0, 0.5)  # Semi-transparent preview
		wire_instance.width = 2
		add_child(wire_instance)
		
		wire_points.clear()
		wire_points.append(start_position)
		Global.placing_wire = true
		Global.placing_wire = true
		print("Starting wire placement from port")
	
	elif Global.placing_wire and Global.wire_mode:
		# End wire placement
		end = { "id": component_id, "port": port_name }
		end_position = port_position
		
		# Don't add the snapped grid point, use the actual port position
		# wire_points.append(end_position)
		
		# Finalize the wire
		wire_instance.clear_wire()
		
		# Draw all intermediate segments
		for i in range(len(wire_points) - 1):
			var point_a = wire_points[i]
			var point_b = wire_points[i + 1]
			
			# Draw orthogonal segments
			var midpoint_x = (point_a.x + point_b.x) / 2
			wire_instance.add_point(point_a)
			wire_instance.add_point(Vector2(midpoint_x, point_a.y))
			wire_instance.add_point(Vector2(midpoint_x, point_b.y))
			wire_instance.add_point(point_b)
		
		# Add final segment from last grid point to the actual port position
		if wire_points.size() > 0:
			var last_grid_point = wire_points[-1]
			var midpoint_x = (last_grid_point.x + end_position.x) / 2
			wire_instance.add_point(last_grid_point)
			wire_instance.add_point(Vector2(midpoint_x, last_grid_point.y))
			wire_instance.add_point(Vector2(midpoint_x, end_position.y))
			wire_instance.add_point(end_position)
		
		wire_instance.finalize_wire()
		
		# Reset state
		Global.placing_wire = false
		wire_points.clear()
		
		$Graph.add_connection(start, end)
		print("Wire completed")


func _draw():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
		
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	var camera_pos = camera.global_position
	
	var half_size = (viewport_size / zoom) / 2.0
	var top_left = camera_pos - half_size
	var bottom_right = camera_pos + half_size
	
	var start_x = int(top_left.x / Global.grid_size) * Global.grid_size
	var start_y = int(top_left.y / Global.grid_size) * Global.grid_size
	
	var x = start_x
	while x <= bottom_right.x:
		draw_line(Vector2(x, top_left.y), Vector2(x, bottom_right.y), Global.grid_color)
		x += Global.grid_size
	
	var y = start_y
	while y <= bottom_right.y:
		draw_line(Vector2(top_left.x, y), Vector2(bottom_right.x, y), Global.grid_color)
		y += Global.grid_size



func ui_movement():
	if Input.is_action_pressed("Drag") && ui_hover:
		$Camera2D/FoldableContainer.position = get_global_mouse_position()


	

func _on_foldable_container_mouse_entered():
	ui_hover = true



func _on_foldable_container_mouse_exited():
	if Input.is_action_pressed("Drag"):
		ui_hover = true
	else:
		ui_hover = false
		

var position_before_drag = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Zoom_In"):
		$Camera2D.zoom *= 1.1
		_update_ui_scale()
		queue_redraw()
	if event.is_action_pressed("Zoom_out"):
		$Camera2D.zoom *= 0.9
		_update_ui_scale()
		queue_redraw()
	
	if event.is_action_pressed("Camera Pan"):
		position_before_drag = event.global_position
	
	if event.is_action_released("Camera Pan"):
		position_before_drag = null
	
	if event is InputEventPanGesture:
		$Camera2D.global_position += event.delta * 20
		queue_redraw()
	
	if event is InputEventScreenDrag:
		$Camera2D.global_position -= event.relative
		queue_redraw()
	
	if position_before_drag != null and event is InputEventMouseMotion:
		var delta = event.global_position - position_before_drag
		$Camera2D.global_position -= delta / $Camera2D.zoom
		position_before_drag = event.global_position
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Global.placing_wire:
			var snapped_pos = snap_to_grid(get_global_mouse_position())
			wire_points.append(snapped_pos)
			print("Point added at: ", snapped_pos)

func _update_ui_scale():
	pass

func cancel_wire_placement():
	# Call this if user presses Escape or right-clicks
	if Global.placing_wire and wire_instance:
		wire_instance.queue_free()
		wire_instance = null
		wire_points.clear()
		Global.placing_wire = false
		Global.placing_wire = false
		print("Wire placement cancelled")

func _unhandled_input(event):
	# Cancel wire placement on right click or Escape
	if Global.placing_wire:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT) or \
		   (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			cancel_wire_placement()
			get_viewport().set_input_as_handled()
