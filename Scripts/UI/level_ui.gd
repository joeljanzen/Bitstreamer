class_name LevelStatistics
extends Control
## Tracks statistics during gameplay and updates the level UI with it.

@onready var _score_label: RichTextLabel = $CanvasLayer/Score
@onready var _combo_label: RichTextLabel = $CanvasLayer/Combo
@onready var _health_bar: ProgressBar = $CanvasLayer/ProgramHealth
@onready var _accuracy_label: RichTextLabel = $CanvasLayer/Accuracy

## The score for this play, including all bonuses.
var score: int = 0

## The number of bits that have been correctly clicked since the last miss.
var combo: int = 0

## The highest combo achieved in this play.
var max_combo: int = 0

## The total accuracy of all clicks in this play.
var accuracy: float = 100

## The score for this play, ignoring any combo bonuses.
var _raw_score: int = 0

## The maximum raw score obtainable in this play.
var _max_accuracy: int = 0


## Share statistics with PerformanceCalculator, and connect to gameplay signals.
func _ready() -> void:
	PerformanceCalculator.connect_stats(self)
	Signals.scored.connect(_scored)
	Signals.missed.connect(_missed)


## Points have been scored. amount is the total score gained, and raw_amount is
## the score given for the click before any bonuses 
## (bad, good, or perfect click).
func _scored(amount: int, raw_amount: int) -> void:
	score += amount
	_score_label.text = "Score: %d" % score
	combo += 1
	max_combo = max(combo, max_combo)
	_combo_label.text = "Combo: %dx" % combo
	
	if _health_bar.value < _health_bar.max_value:
		_health_bar.value += PerformanceCalculator.calculate_health_gain(raw_amount)
	
	_update_acc(raw_amount)


## The player missed a bit.
func _missed(damage: int) -> void:
	combo = 0
	_combo_label.text = "Combo: %dx" % combo
	_health_bar.value -= damage
	
	_update_acc(0)
	
	if _health_bar.value <= 0:
		Signals.failed.emit()


## Updates player accuracy. raw_score is the score given for the click 
## before any bonuses (bad, good, or perfect click).
func _update_acc(raw_score: int) -> void:
	_raw_score += raw_score
	_max_accuracy += PerformanceCalculator.PERFECT_CLICK_SCORE
	accuracy = float(_raw_score) / float(_max_accuracy) * 100
	_accuracy_label.text = "Accuracy: %.2f%%" % accuracy
