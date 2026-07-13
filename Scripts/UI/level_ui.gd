class_name GameplayStatistics
extends Control
## Tracks statistics during gameplay and updates the level UI with it.

@onready var _canvas: CanvasLayer = $CanvasLayer
@onready var _score_label: RichTextLabel = $CanvasLayer/Score
@onready var _combo_label: RichTextLabel = $CanvasLayer/Combo
@onready var _health_bar: ProgressBar = $CanvasLayer/ProgramHealth
@onready var _accuracy_label: RichTextLabel = $CanvasLayer/Accuracy
@onready var _progress_circle: TextureProgressBar = $CanvasLayer/LevelProgress

## The score for this play, including all bonuses.
var score: int = 0

## The number of bits that have been correctly clicked since the last miss.
var combo: int = 0

## The highest combo achieved in this play.
var max_combo: int = 0

## The total accuracy of all clicks in this play.
var accuracy: float = 100

# Tracking amount of each click quality.
## The number of perfect clicks made in this play.
var perfect_clicks: int = 0
## The number of good clicks made in this play.
var good_clicks: int = 0
## The number of okay clicks made in this play.
var okay_clicks: int = 0
## The number of missed bits in this play.
var missed_clicks: int = 0
## The number of error clicks made in this play.
var error_clicks: int = 0

## The score for this play, ignoring any combo bonuses.
var _raw_score: int = 0

## The maximum raw score obtainable in this play.
var _max_accuracy: int = 0

## Contains statistics for the current level.
var _conductor: Conductor


## Share statistics with PerformanceCalculator, and connect to gameplay signals.
func _ready() -> void:
	PerformanceCalculator.connect_gameplay_stats(self)
	Signals.scored.connect(_scored)
	Signals.missed.connect(_missed)
	
	#_progress_circle.tint_progress = GameSettings.zero_bit_colour


## Updates the level progress circle.
func _process(_delta: float) -> void:
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
	score = 0
	_score_label.text = "0"
	combo = 0
	_combo_label.text = "0x"
	
	perfect_clicks = 0
	good_clicks = 0
	okay_clicks = 0
	missed_clicks = 0
	error_clicks = 0
	
	accuracy = 100
	_accuracy_label.text = "Accuracy 100%%"
	_max_accuracy = 0
	_raw_score = 0


## Points have been scored. amount is the total score gained, and raw_amount is
## the score given for the click before any bonuses 
## (okay, good, or perfect click).
func _scored(amount: int, raw_amount: int) -> void:
	score += amount
	_score_label.text = "%d" % score
	combo += 1
	max_combo = max(combo, max_combo)
	_combo_label.text = "%dx" % combo
	
	if _health_bar.value < _health_bar.max_value:
		_health_bar.value += PerformanceCalculator.calculate_health_gain(raw_amount)
	
	match PerformanceCalculator.get_click_quality(raw_amount):
		PerformanceCalculator.ClickQuality.PERFECT:
			perfect_clicks += 1
		PerformanceCalculator.ClickQuality.GOOD:
			good_clicks += 1
		PerformanceCalculator.ClickQuality.OKAY:
			okay_clicks += 1
	
	_update_acc(raw_amount)


## The player missed a bit.
func _missed(damage: int, click_quality: PerformanceCalculator.ClickQuality) -> void:
	combo = 0
	_combo_label.text = "%dx" % combo
	_health_bar.value -= damage
	
	_update_acc(0)
	
	match click_quality:
		PerformanceCalculator.ClickQuality.MISS:
			missed_clicks += 1
		PerformanceCalculator.ClickQuality.ERROR:
			error_clicks += 1
	
	if _health_bar.value <= 0:
		Signals.failed.emit()


## Updates player accuracy. raw_score is the score given for the click 
## before any bonuses (okay, good, or perfect click).
func _update_acc(raw_score: int) -> void:
	_raw_score += raw_score
	_max_accuracy += PerformanceCalculator.PERFECT_CLICK_SCORE
	accuracy = float(_raw_score) / float(_max_accuracy) * 100
	_accuracy_label.text = "Accuracy %.2f%%" % accuracy
