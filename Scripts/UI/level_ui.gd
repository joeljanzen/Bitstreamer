extends Control

@onready var _score_label = $CanvasLayer/Score
@onready var _combo_label = $CanvasLayer/Combo
@onready var _health_bar = $CanvasLayer/ProgramHealth

var _score: int = 0
var _combo: int = 0
var _max_combo: int = 0


func _ready() -> void:
	Signals.score.connect(scored)
	Signals.combo_break.connect(combo_broke)
	Signals.damage.connect(damaged)


## points have been scored
func scored(amount: int) -> void:
	_score += amount
	_score_label.text = "Score: %d" % _score
	_combo += 1
	_max_combo = max(_combo, _max_combo)
		
	_combo_label.text = "Combo: %dx" % _combo


## something has broken the combo (a bit was missed, etc.)
func combo_broke() -> void:
	_combo = 0
	_combo_label.text = "Combo: %dx" % _combo


## something damaged the player
func damaged(amount: int) -> void:
	_health_bar.value -= amount


func get_score() -> int:
	return _score


func get_combo() -> int:
	return _combo


func get_max_combo() -> int:
	return _max_combo
