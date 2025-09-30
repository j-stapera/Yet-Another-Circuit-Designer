extends Node2D

## Stores whether the mouse is currently hovering over the component
var hover = false

func _on_container_mouse_entered():
	hover = true

func _process(_delta):
	handle_movement()


func handle_movement():
	if hover and Input.is_action_pressed("Drag"):
		position = get_global_mouse_position()
	if hover and Input.is_action_just_pressed("Rotate Left"):
		rotation_degrees -= 45
	if hover and Input.is_action_just_pressed("Rotate Right"):
		rotation_degrees += 45

func _on_container_mouse_exited():
	if not Input.is_action_pressed("Drag"):
		hover = false
