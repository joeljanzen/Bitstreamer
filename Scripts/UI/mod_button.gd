@tool
class_name ModButton
extends Node

@onready var button = $Button

## The mod activated by pressing this button. The appropriate icon is set
## given this value.
@export var mod: ModManager.ModType


## The name of this mod.
@export var mod_name: String:
	set(value):
		mod_name = value
		$Button/MarginContainer/VBoxContainer/HBoxContainer/Name.text = value


## The description of this mod.
@export var description: String:
	set(value):
		description = value
		$Button/MarginContainer/VBoxContainer/Description.text = value


## Emitted when the button is pressed.
signal pressed(mod: ModManager.ModType)

## Emitted when the mouse hovers over the button.
signal mouse_entered()


func _ready() -> void:
	if !Engine.is_editor_hint():
		var icon = ModManager.get_icon(mod)
		$Button/MarginContainer/VBoxContainer/HBoxContainer/Icon.texture = icon


## Emit the actual pressed signal with the mod type attached.
func _on_button_pressed() -> void:
	pressed.emit(mod)


func _on_button_mouse_entered() -> void:
	if !button.disabled:
		mouse_entered.emit()


func is_disabled() -> bool:
	return button.disabled


func toggle_disabled() -> void:
	button.disabled = !button.disabled


func set_pressed(press: bool) -> void:
	button.set_pressed_no_signal(press)
