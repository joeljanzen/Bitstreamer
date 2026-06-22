class_name ColorButton
extends Button
## Custom Button to allow picking a color from a color palette.

@onready var _color_rect = $MarginContainer/ColorRect

## The color of the button has changed.
signal color_changed(color: Color)

var _color_picker_scene = preload("res://Scenes/UI/color_pallete_picker.tscn")

@export var color: Color = Color("ffffff")


## Set the color of the button. Does not send out the color_changed signal.
func set_color(new_color: Color) -> void:
	color = new_color
	_color_rect.color = new_color


## Set the color of the button based on a signal from the color palette.
func _set_color_from_palette(new_color: Color) -> void:
	set_color(new_color)
	color_changed.emit(new_color)


func _pressed() -> void:
	var color_picker = _color_picker_scene.instantiate()
	color_picker.connect("color_selected", _set_color_from_palette)
	add_child(color_picker)
