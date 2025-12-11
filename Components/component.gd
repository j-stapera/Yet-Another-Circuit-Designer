class_name Component
extends Node2D

signal something_changed

var id: String
var component_type: String 
var hover = false
var start_connections: Dictionary = {}
var end_connections: Dictionary = {}
var current: float
var states: Array = []


signal port_clicked(component_id, port_name, position)

const info_window = preload("res://popup_windows/informational_window.tscn")

@onready var label: LineEdit
@onready var id_label: Label


func set_id():
	pass

func get_id():
	pass

func get_current():
	return current

func set_current(new_current: float):
	#var new_value_string = str(new_value)
	#current = new_value_string
	current = new_current
	something_changed.emit()

func get_value():
	return 0

func set_value(new_value):
	something_changed.emit()

func get_prefix() -> String:
	return ""

func _process(_delta):
	handle_movement()
	handle_port_visibility()

func handle_port_visibility():
	if Global.wire_mode:
		$Start/Port.visible = true
		$End/Port2.visible = true
	else:
		$Start/Port.visible = false
		$End/Port2.visible = false

func snap_to_grid(pos):
	return Vector2(0,0)

func handle_movement():
	if hover and Input.is_action_pressed("Drag"):
		position = snap_to_grid(get_global_mouse_position())
	if hover and Input.is_action_just_pressed("Rotate Left"):
		rotation_degrees -= 90
		something_changed.emit()
	if hover and Input.is_action_just_pressed("Rotate Right"):
		rotation_degrees += 90
		something_changed.emit()


func _on_container_mouse_entered():
	hover = true

func _on_container_mouse_exited():
	if not Input.is_action_pressed("Drag"):
		hover = false

func _on_start_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "start", %StartPos.global_position)

func _on_end_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "end", %EndPos.global_position)
		
func _on_container_gui_input(event):
		if event is InputEventMouseButton and event.is_pressed():
			if event.is_double_click():
				display_info()

func display_info():
	var info_instance = info_window.instantiate()
	add_child(info_instance)
	
	var id_text = info_instance.find_child("Name")
	var value_text = info_instance.find_child("Value")
	var current_text = info_instance.find_child("LineEdit")
	
	# Debug prints
	print("id_text found: ", id_text != null)
	print("value_text found: ", value_text != null)
	print("current_text found: ", current_text != null)
	
	if current_text == null:
		push_error("LineEdit not found! Check node names in info_window scene")
		return
	
	id_text.text = "Name: " + id
	
	if get_prefix() == "R":
		value_text.text = "Resistance: " + str(get_value())
		current_text.text = "%.4f" % get_current()
			
	if get_prefix() == "V":
		value_text.text = "Voltage: " + str(get_value())
	
	if not current_text.text_submitted.is_connected(_on_text_submitted):
		current_text.text_submitted.connect(_on_text_submitted)
	
func _on_text_submitted(new_text):
	set_current(int(new_text))

func set_connection(port, connected_id, connected_port):
	if port == "start":
		start_connections[connected_id] = connected_port
	else:
		end_connections[connected_id] = connected_port
