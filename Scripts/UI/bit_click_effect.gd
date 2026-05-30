class_name BitClickEffect
extends Node2D
## An effect that plays when a bit is clicked to indicate the accuracy of 
## the click.

@onready var _accuracy_label: RichTextLabel = $AccuracyText


## Set up the effect using the raw score of the click.
## Set the raw score to negative to indicate an incorrect "error" click.
func create(global_position, raw_score: int) -> void:
	position = global_position
	
	if raw_score >= 0:
		match raw_score:
			PerformanceCalculator.PERFECT_CLICK_SCORE:
				_accuracy_label.set("theme_override_colors/default_color", Color("2AEBE7"))
				_accuracy_label.text = "PERFECT!"
			PerformanceCalculator.GOOD_CLICK_SCORE:
				_accuracy_label.set("theme_override_colors/default_color", Color("10E610"))
				_accuracy_label.text = "GOOD!"
			PerformanceCalculator.BAD_CLICK_SCORE:
				_accuracy_label.set("theme_override_colors/default_color", Color("E6BE20"))
				_accuracy_label.text = "OKAY!"
			_:
				_accuracy_label.set("theme_override_colors/default_color", Color("ffffff"))
				_accuracy_label.text = "MISS!"
	else:
		_accuracy_label.set("theme_override_colors/default_color", Color("C21515"))
		_accuracy_label.text = "ERROR!"


func get_width() -> int:
	return 100

## Delete the effect after the animation ends.
func _on_animation_finished(anim_name: StringName) -> void:
	queue_free()
