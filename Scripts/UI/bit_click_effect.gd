class_name BitClickEffect
extends Node2D
## An effect that plays when a bit is clicked to indicate the accuracy of 
## the click.

@onready var _accuracy_label: RichTextLabel = $AccuracyText


## Set up the effect depending on the quality of the click.
func create(global_position, click_quality: PerformanceCalculator.ClickQuality) -> void:
	position = global_position
	
	match click_quality:
		PerformanceCalculator.ClickQuality.PERFECT:
			_accuracy_label.set("theme_override_colors/default_color", Color("2AEBE7"))
			_accuracy_label.text = "PERFECT!"
		PerformanceCalculator.ClickQuality.GOOD:
			_accuracy_label.set("theme_override_colors/default_color", Color("10E610"))
			_accuracy_label.text = "GOOD!"
		PerformanceCalculator.ClickQuality.OKAY:
			_accuracy_label.set("theme_override_colors/default_color", Color("E6BE20"))
			_accuracy_label.text = "OKAY!"
		PerformanceCalculator.ClickQuality.MISS:
			_accuracy_label.set("theme_override_colors/default_color", Color("ffffff"))
			_accuracy_label.text = "MISS!"
		PerformanceCalculator.ClickQuality.ERROR:
			_accuracy_label.set("theme_override_colors/default_color", Color("C21515"))
			_accuracy_label.text = "ERROR!"
		_:
			push_error("Tried to pass a non-standard click quality!")


func get_width() -> int:
	return 100

## Delete the effect after the animation ends.
func _on_animation_finished(anim_name: StringName) -> void:
	queue_free()
