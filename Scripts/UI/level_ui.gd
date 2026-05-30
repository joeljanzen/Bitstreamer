class_name LevelStatistics
extends Control

@onready var _score_label = $CanvasLayer/Score
@onready var _combo_label = $CanvasLayer/Combo
@onready var _health_bar = $CanvasLayer/ProgramHealth
@onready var _accuracy_label = $CanvasLayer/Accuracy

## the score for this play, including all bonuses
var _score: int = 0
## the score for this play, ignoring any combo bonuses
var _raw_score: int = 0
## the number of bits that have been correctly clicked since the last miss
var _combo: int = 0
## the highest combo achieved in this play
var _max_combo: int = 0
## the maximum raw score obtainable in this play
var _max_accuracy: int = 0
## the total accuracy of all clicks in this play
var _accuracy: float = 100


func _ready() -> void:
	PerformanceCalculator.connect_stats(self)
	Signals.score.connect(scored)
	Signals.miss.connect(missed)


## points have been scored
func scored(amount: int, raw_amount: int) -> void:
	_score += amount
	_score_label.text = "Score: %d" % _score
	_combo += 1
	_max_combo = max(_combo, _max_combo)
	_combo_label.text = "Combo: %dx" % _combo
	
	update_acc(raw_amount)


## the player missed a bit
func missed(damage: int) -> void:
	_combo = 0
	_combo_label.text = "Combo: %dx" % _combo
	_health_bar.value -= damage
	
	update_acc(0)


## update player accuracy.
## the raw score is the score given for the click before any bonuses (bad, good, or perfect click)
func update_acc(raw_score: int):
	_raw_score += raw_score
	_max_accuracy += PerformanceCalculator.PERFECT_CLICK_SCORE
	_accuracy = float(_raw_score) / float(_max_accuracy) * 100
	_accuracy_label.text = "Accuracy: %.2f%%" % _accuracy


func get_current_score() -> int:
	return _score


func get_combo() -> int:
	return _combo


func get_max_combo() -> int:
	return _max_combo


func get_accuracy() -> float:
	return _accuracy
