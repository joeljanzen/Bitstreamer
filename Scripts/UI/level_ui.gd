class_name LevelUI
extends Control
## Tracks statistics during gameplay and updates the level UI with it.

@onready var _canvas: CanvasLayer = $CanvasLayer
@onready var _score_label: RichTextLabel = $CanvasLayer/Score
@onready var _combo_label: RichTextLabel = $CanvasLayer/Combo
@onready var _health_bar: ProgressBar = $CanvasLayer/ProgramHealth
@onready var _accuracy_label: RichTextLabel = $CanvasLayer/Accuracy
@onready var _progress_circle: TextureProgressBar = $CanvasLayer/LevelProgress

## Stores data for the current play of a level, including score, combo, etc.
var play_data: PlayData = PlayData.new()

## The score for this play, ignoring any combo bonuses.
var _raw_score: int = 0

## The maximum raw score obtainable in this play.
var _max_accuracy: int = 0

## The value to multiply the player's score by. This value is set by active mods.
var _score_multiplier: float = 1

## Used to look up the current point in the level and display progress.
var _conductor: Conductor

## If the player fails the level, this value will be set at the time of fail.
var _progress_at_fail = -1


## Get the score multiplier from ModManager, attach the modlist to playdata,
## share that play data with the PerformanceCalculator, and connect to gameplay 
## score and miss signals.
func _ready() -> void:
	_score_multiplier = ModManager.get_score_multiplier()
	
	# Attach mod list to the play data in case it is saved later.
	play_data.mods = ModManager.get_mod_list()
	
	PerformanceCalculator.connect_play_data(play_data)
	Signals.scored.connect(_scored)
	Signals.missed.connect(_missed)


## Updates the level progress circle.
func _process(_delta: float) -> void:
	if UI_is_visible() and _progress_circle.visible:
		_progress_circle.value = _conductor.get_time()


## Connects the current level to the level UI.
func connect_conductor(conductor: Conductor) -> void:
	_conductor = conductor


## Set the length of the level, used for the progress circle.
## If it is not set, the progress circle will never update itself.
func set_level_length(length: float) -> void:
	_progress_circle.max_value = length


## Set the visibility of the entire levelUI.
func set_UI_visible(enabled: bool) -> void:
	if enabled:
		show_UI()
	else:
		hide_UI()


## Show the entire levelUI.
func show_UI() -> void:
	_canvas.show()
	
	# In the event that theme colors were changed.
	_health_bar.modulate = GameSettings.one_bit_colour
	_progress_circle.tint_progress = GameSettings.one_bit_colour


## Hide the entire levelUI.
func hide_UI() -> void:
	_canvas.hide()


## Returns if the UI is currently visible.
func UI_is_visible() -> bool:
	return _canvas.visible


## Get the current percentage of progress into the level the player is.
## If it returns -1, the current progress does not exist (for tutorial levels).
func get_current_progress() -> float:
	if _progress_at_fail > 0:
		# This means the user made it to the very last click, but missed it and
		# failed (or clicked it wrong and also late).
		# They didn't actually finish the level, so lower progress slightly.
		if _progress_at_fail == 100:
			_progress_at_fail = 99.99
		
		return _progress_at_fail
	else:
		var progress = _progress_circle.value / _progress_circle.max_value * 100
		
		if progress > 0:
			return progress
		else:
			return -1


## Set the visibility of the level progress circle.
func set_level_progress_visible(enabled: bool) -> void:
	if enabled:
		_progress_circle.show()
	else:
		_progress_circle.hide()


## Set the visibility of the score label.
func set_score_label_visible(enabled: bool) -> void:
	if enabled:
		_score_label.show()
	else:
		_score_label.hide()


## Set the visibility of the score label.
func set_accuracy_label_visible(enabled: bool) -> void:
	if enabled:
		_accuracy_label.show()
	else:
		_accuracy_label.hide()


## Set the visibility of the health bar.
func set_health_bar_visible(enabled: bool) -> void:
	if enabled:
		_health_bar.show()
	else:
		_health_bar.hide()


## Set the visibility of the accuracy label.
func set_combo_label_visible(enabled: bool) -> void:
	if enabled:
		_combo_label.show()
	else:
		_combo_label.hide()


## Used in the tutorial where there are multiple separate sections.
func reset_stats() -> void:
	play_data.score = 0
	_score_label.text = "0"
	play_data.combo = 0
	_combo_label.text = "0x"
	
	play_data.perfect_clicks = 0
	play_data.good_clicks = 0
	play_data.okay_clicks = 0
	play_data.missed_clicks = 0
	play_data.error_clicks = 0
	
	play_data.accuracy = 100
	_accuracy_label.text = "Accuracy 100%%"
	_max_accuracy = 0
	_raw_score = 0


## Points have been scored. Amount is the total score gained, and raw_amount is
## the score given for the click before any bonuses 
## (okay, good, or perfect click).
func _scored(amount: int, raw_amount: int) -> void:
	play_data.score += round(amount * _score_multiplier)
	_score_label.text = "%d" % play_data.score
	play_data.combo += 1
	play_data.max_combo = max(play_data.combo, play_data.max_combo)
	_combo_label.text = "%dx" % play_data.combo
	
	if _health_bar.value < _health_bar.max_value:
		_health_bar.value += PerformanceCalculator.calculate_health_gain(raw_amount)
	
	match PerformanceCalculator.get_click_quality(raw_amount):
		PerformanceCalculator.ClickQuality.PERFECT:
			play_data.perfect_clicks += 1
		PerformanceCalculator.ClickQuality.GOOD:
			play_data.good_clicks += 1
		PerformanceCalculator.ClickQuality.OKAY:
			play_data.okay_clicks += 1
	
	_update_acc(raw_amount)


## The player missed a bit.
func _missed(damage: int, click_quality: PerformanceCalculator.ClickQuality) -> void:
	play_data.combo = 0
	_combo_label.text = "%dx" % play_data.combo
	_health_bar.value -= damage
	
	_update_acc(0)
	
	match click_quality:
		PerformanceCalculator.ClickQuality.MISS:
			play_data.missed_clicks += 1
		PerformanceCalculator.ClickQuality.ERROR:
			play_data.error_clicks += 1
	
	if _health_bar.value <= 0:
		# Ignore extra missed and clicked bits, the player already failed.
		Signals.missed.disconnect(_missed) 
		Signals.scored.disconnect(_scored)
		_progress_at_fail = get_current_progress()
		Signals.failed.emit()


## Updates player accuracy. raw_score is the score given for the click 
## before any bonuses (okay, good, or perfect click).
func _update_acc(raw_score: int) -> void:
	_raw_score += raw_score
	_max_accuracy += PerformanceCalculator.PERFECT_CLICK_SCORE
	play_data.accuracy = float(_raw_score) / float(_max_accuracy) * 100
	_accuracy_label.text = "Accuracy %.2f%%" % play_data.accuracy
