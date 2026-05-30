class_name LevelStatistics
extends Control

@onready var _score_label = $CanvasLayer/Score
@onready var _combo_label = $CanvasLayer/Combo
@onready var _health_bar = $CanvasLayer/ProgramHealth
@onready var _accuracy_label = $CanvasLayer/Accuracy

var _score: int = 0
var _combo: int = 0
var _max_combo: int = 0
var _max_accuracy: float = 0
var _accuracy: float = 100


func _ready() -> void:
	PerformanceCalculator.connect_stats(self)
	Signals.score.connect(scored)
	Signals.miss.connect(missed)


## points have been scored
func scored(amount: int) -> void:
	_score += amount
	_score_label.text = "Score: %d" % _score
	_combo += 1
	_max_combo = max(_combo, _max_combo)
	_combo_label.text = "Combo: %dx" % _combo
	
	update_acc()


## the player missed a bit
func missed(damage: int) -> void:
	_combo = 0
	_combo_label.text = "Combo: %dx" % _combo
	_health_bar.value -= damage
	
	update_acc()


## update player accuracy
func update_acc():
	_max_accuracy += PerformanceCalculator.PERFECT_CLICK_SCORE
	_accuracy = float(_score) / _max_accuracy * 100 # only works if score does not increase with higher combo!
	_accuracy_label.text = "Accuracy: %d%%" % _accuracy


func get_current_score() -> int:
	return _score


func get_combo() -> int:
	return _combo


func get_max_combo() -> int:
	return _max_combo


func get_accuracy() -> float:
	return _accuracy
