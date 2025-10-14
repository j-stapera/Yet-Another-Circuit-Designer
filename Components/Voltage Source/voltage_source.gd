extends Node2D

## Stores whether the mouse is currently hovering over the component
var hover = false
var id: int
var port = {}
static var counter = 0
signal port_clicked(component_id, port_name, position)

func _on_container_mouse_entered():
	hover = true


func _on_container_mouse_exited():
	if not Input.is_action_pressed("Drag"):
		hover = false

func _process(_delta):
	handle_movement()

func _ready():
	id = counter
	counter += 1 
	port["start"] = $Start
	port["end"] = $End

func handle_movement():
	if hover and Input.is_action_pressed("Drag"):
		position = get_global_mouse_position()
	if hover and Input.is_action_just_pressed("Rotate Left"):
		rotation_degrees -= 45
	if hover and Input.is_action_just_pressed("Rotate Right"):
		rotation_degrees += 45



func _on_start_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "start", %StartPos.global_position)
		print("Port start clicked on resistor ", id)

func _on_end_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "end", %EndPos.global_position)
		print("Port end clicked on resistor ", id)
