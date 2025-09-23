extends Node2D

## Initialize for component selection and its holo counterpart
var element_selected: PackedScene = null
var holo_node: Node2D = null
var wire_mode = false


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
	#
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

## Cancels the currently selected component. Will only trigger when an element is also selected, so RMB functionality is still available
func cancel_selection():
	if holo_node and holo_node.is_inside_tree():
		holo_node.queue_free()
	holo_node = null
	element_selected = null


func handle_wire():
	pass
