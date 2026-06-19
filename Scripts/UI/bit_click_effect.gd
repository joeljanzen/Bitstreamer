class_name BitClickEffect
extends Node2D
## An effect that plays when a bit is clicked to indicate the accuracy of 
## the click.

@onready var _accuracy_label: RichTextLabel = $AccuracyText

## The width of the effect, in pixels.
## WARNING: NOT GOOD TO HARDCODE THIS, SHOULD BE CALCULATED SOMEHOW
static func get_width() -> int:
	return 100


## Set up the effect depending on the quality of the click.
func create(global_pos, click_quality: PerformanceCalculator.ClickQuality) -> void:
	position = global_pos
	
	match click_quality:
		PerformanceCalculator.ClickQuality.PERFECT:
			if !GameSettings.ignores_perfect_clicks:
				_accuracy_label.set("theme_override_colors/default_color", Color(GameSettings.perfect_click_colour))
				_accuracy_label.text = "PERFECT!"
			else:
				hide()
		PerformanceCalculator.ClickQuality.GOOD:
			_accuracy_label.set("theme_override_colors/default_color", Color(GameSettings.good_click_colour))
			_accuracy_label.text = "GOOD"
		PerformanceCalculator.ClickQuality.OKAY:
			_accuracy_label.set("theme_override_colors/default_color", Color(GameSettings.okay_click_colour))
			_accuracy_label.text = "OKAY"
		PerformanceCalculator.ClickQuality.MISS:
			_accuracy_label.set("theme_override_colors/default_color", Color(GameSettings.missed_click_colour))
			_accuracy_label.text = "MISS!"
		PerformanceCalculator.ClickQuality.ERROR:
			_accuracy_label.set("theme_override_colors/default_color", Color(GameSettings.incorrect_click_colour))
			_accuracy_label.text = "ERROR!"
		_:
			push_error("Tried to pass a non-standard click quality!")


## Delete the effect after the animation ends.
func _on_animation_finished(_anim_name: StringName) -> void:
	queue_free()
