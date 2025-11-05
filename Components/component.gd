class_name Component
extends Node2D


var id: String
var component_type: String 
var hover = false
var start_connections: Dictionary = {}
var end_connections: Dictionary = {}


signal port_clicked(component_id, port_name, position)


@onready var label: LineEdit
@onready var id_label: Label


func get_value():
	return 0

func set_value(new_value):
	pass

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
	return Vector2(
		round(pos.x / Global.grid_size) * Global.grid_size,
		round(pos.y / Global.grid_size) * Global.grid_size
	)

func handle_movement():
	if hover and Input.is_action_pressed("Drag"):
		position = snap_to_grid(get_global_mouse_position())
	if hover and Input.is_action_just_pressed("Rotate Left"):
		rotation_degrees -= 90
	if hover and Input.is_action_just_pressed("Rotate Right"):
		rotation_degrees += 90

func _on_container_mouse_entered():
	hover = true

func _on_container_mouse_exited():
	if not Input.is_action_pressed("Drag"):
		hover = false

func _on_start_input_event(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "start", %StartPos.global_position)

func _on_end_input_event(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "end", %EndPos.global_position)

func set_connection(port, connected_id, connected_port):
	if port == "start":
		start_connections[connected_id] = connected_port
	else:
		end_connections[connected_id] = connected_port
