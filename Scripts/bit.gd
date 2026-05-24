extends Node2D

## The value of the bit. Off is 0, on is 1
@export var value: bool = false

@onready var _label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if value == false:
		_label.text = "0"
	else:
		_label.text = "1"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
