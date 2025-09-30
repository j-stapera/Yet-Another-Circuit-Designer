extends Node2D

## Initialize for component selection and its holo counterpart
var element_selected: PackedScene = null
var holo_node: Node2D = null
var wire: PackedScene = null


var wire_mode = false
var placing_wire = false
var wire_instance
var start_position = Vector2(0, 0)
var end_position = Vector2(0, 0)
var start
var end
#signal wire_placed(start: Vector2, end: Vector2)


## Load in all the scenes. Each component will be preloaded in this section
var resistor_scn = preload("res://Components/Resistor/resistor.tscn")
var resistor_holoscn = preload("res://Components/Resistor/resistor_holo.tscn")
var voltageSource_scn = preload("res://Components/Voltage Source/voltage_source.tscn")
var voltageSource_holoscn = preload("res://Components/Voltage Source/vs_holo.tscn")
var wire_scn = preload("res://Components/wire.tscn")
var element_rotation

## Need to expand the container and create a function to limit placing components when the mouse enters the container ***
var placeable = true

## Button presses for each component will follow the same structure
func _on_button_resistor_pressed():
	select_element(resistor_scn, resistor_holoscn)

func _on_button_voltage_source_pressed():
	select_element(voltageSource_scn, voltageSource_holoscn)
	
func _on_button_wire_pressed():
	cancel_selection()
	wire_mode = true

## Assign the currently selected component based on the button pressed
func select_element(scene: PackedScene, holo: PackedScene):
	if holo_node and holo_node.is_inside_tree():
		holo_node.queue_free()
	
	element_selected = scene
	holo_node = holo.instantiate()
	add_child(holo_node)
	holo_node.visible = true
	holo_node.position = get_global_mouse_position()



func _process(_delta):

	if element_selected and placeable:
		holo_node.position = get_global_mouse_position()
		handle_element()
	

	
	if Input.is_action_just_pressed("Cancel") and element_selected:
		cancel_selection()
		

## All actions while an component is currently selected
func handle_element():
	if Input.is_action_just_pressed("Rotate Left"):
		holo_node.rotation_degrees -= 45
	if Input.is_action_just_pressed("Rotate Right"):
		holo_node.rotation_degrees += 45

	if Input.is_action_just_pressed("Place"):
		var instance = element_selected.instantiate()
		instance.position = holo_node.position
		instance.rotation = holo_node.rotation
		$Graph.add_child(instance)
		instance.port_clicked.connect(_on_port_clicked)

## Cancels the currently selected component. Will only trigger when an element is also selected, so RMB functionality is still available
func cancel_selection():
	wire_mode = false
	if holo_node and holo_node.is_inside_tree():
		holo_node.queue_free()
	holo_node = null
	element_selected = null

## Handles the wiring between components
func _on_port_clicked(component_id, port_name, position):
	if not placing_wire and wire_mode:
		start = { "id": component_id, "port": port_name }
		start_position = position
		
		wire_instance = wire_scn.instantiate()
		add_child(wire_instance)
		#connect("wire_placed", Callable(wire_instance, "draw_wire"))
		placing_wire = true
		print("starting point created at: ", start_position)
	elif wire_mode:
			# Second click: set end and finalize wire
		end = { "id": component_id, "port": port_name }
		end_position = position
		print("starting position before sending: ", start_position)
		#emit_signal("wire_placed", start_position, end_position)
		wire_instance.draw_wire(start_position, end_position)
			#wire_instance.draw_wire(start, end)  # pass coords into wire’s script
		placing_wire = false
		disconnect("wire_placed", Callable(wire_instance, "draw_wire"))
		print("end point created at: ", end_position)
	
