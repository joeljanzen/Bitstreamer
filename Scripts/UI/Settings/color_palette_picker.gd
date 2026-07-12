class_name ColorPalettePicker
extends Control
## Allows picking a color from a limited selection.

## A color has been selected from the palette.
signal color_selected(color: Color)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_close_dialog"):
		accept_event()
		queue_free()


## The panel was pressed, so close the pallete picker
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		queue_free()


func _on_button_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button/ColorRect.color)
	queue_free()


func _on_button_2_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button2/ColorRect.color)
	queue_free()


func _on_button_3_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button3/ColorRect.color)
	queue_free()


func _on_button_4_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button4/ColorRect.color)
	queue_free()


func _on_button_5_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button5/ColorRect.color)
	queue_free()


func _on_button_6_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button6/ColorRect.color)
	queue_free()


func _on_button_7_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button7/ColorRect.color)
	queue_free()


func _on_button_8_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button8/ColorRect.color)
	queue_free()


func _on_button_9_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button9/ColorRect.color)
	queue_free()


func _on_button_10_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button10/ColorRect.color)
	queue_free()


func _on_button_11_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button11/ColorRect.color)
	queue_free()


func _on_button_12_pressed() -> void:
	color_selected.emit($CanvasLayer/Panel/GridContainer/Button12/ColorRect.color)
	queue_free()
