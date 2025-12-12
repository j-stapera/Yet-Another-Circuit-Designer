extends Control

var pinned = false

func _ready():
	$PanelContainer.visible = false

func _on_area_2d_mouse_entered() -> void:
	if !pinned:
		$PanelContainer.visible = true
		$Sprite2D.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_area_2d_mouse_exited() -> void:
	if !pinned:
		$PanelContainer.visible = false
		$Sprite2D.self_modulate = Color(0.224, 0.224, 0.224)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Hide") && visible:
		visible = false
	elif event.is_action_pressed("Hide") && !visible:
		visible = true


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !pinned:
		$PanelContainer.visible = true
		pinned = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and pinned:
		$PanelContainer.visible = false
		pinned = false
	
