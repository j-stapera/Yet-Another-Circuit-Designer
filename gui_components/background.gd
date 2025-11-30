extends Sprite2D

func _ready():
	Global.connect("theme_change", _update_theme)

func _update_theme(newValue):
	visible = newValue
