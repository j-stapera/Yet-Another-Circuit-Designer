extends Node2D

@onready var label = $LineEdit

## Stores whether the mouse is currently hovering over the component
var hover = false
var id: int
var port = {}
var resistance = 5000
static var counter = 0
signal port_clicked(component_id, port_name, position)


func _ready():
	label.text = str(resistance)
	id = counter
	counter += 1 
	port["start"] = $Start
	port["end"] = $End

func _process(_delta):
	handle_movement()
	
	if Global.wire_mode:
		$Start/Port.visible = true
		$End/Port2.visible = true
	else:
		$Start/Port.visible = false
		$End/Port2.visible = false


func _on_container_mouse_entered():
	hover = true


func _on_container_mouse_exited():
	if not Input.is_action_pressed("Drag"):
		hover = false


func snap_to_grid(pos):
	return Vector2(round(pos.x / Global.grid_size) * Global.grid_size, round(pos.y / Global.grid_size) * Global.grid_size)


func handle_movement():
	if hover and Input.is_action_pressed("Drag"):
		position = snap_to_grid(get_global_mouse_position())
	if hover and Input.is_action_just_pressed("Rotate Left"):
		rotation_degrees -= 45
	if hover and Input.is_action_just_pressed("Rotate Right"):
		rotation_degrees += 45

## If the "Start" collision node is clicked then emit signal
func _on_start_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "start", %StartPos.global_position)
		print("Port start clicked on resistor ", id)

## If the "End" collision node is clicked then emit signal
func _on_end_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("port_clicked", id, "end", %EndPos.global_position)
		print("Port end clicked on resistor ", id)




func set_resistance(new_res):
	resistance = new_res
	print("resistance changed to ", resistance)

func _on_line_edit_text_submitted(new_text):
	var res = new_text.to_int()
	set_resistance(res)
var value = 2.0 #resistance in ohms
var edges = []
