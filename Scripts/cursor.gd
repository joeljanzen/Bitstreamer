extends AnimatedSprite2D
## the cursor indicating to the player when to click a bit

@export var bit_label: Label

@onready var start_x_pos = position.x
@onready var start_y_pos = position.y
@onready var bit = preload("res://Scenes/bit.tscn")

## stack of bits currently on screen
var bit_stream = []


func _process(delta: float) -> void:
	# input handling
	if !bit_stream.is_empty():
		var curr_bit
		if Input.is_action_just_pressed("0 bit") && !bit_stream[0].get_value() && bit_stream[0].clickable(position.x):
			curr_bit = bit_stream.pop_front()
			curr_bit.clicked(position.x)
			bit_label.text += "0"
			position.x += Bit.get_width()
		elif Input.is_action_just_pressed("1 bit") && bit_stream[0].get_value() && bit_stream[0].clickable(position.x):
			curr_bit = bit_stream.pop_front()
			curr_bit.clicked(position.x)
			bit_label.text += "1"
			position.x += Bit.get_width()
		# delete bit if it goes offscreen
		elif bit_stream[0].missed(position.x):
			bit_stream.pop_front()
	if Input.is_action_just_pressed("Enter"):
		bit_label.text += "\n"
		position.y += Bit.get_height()
		position.x = start_x_pos
		
	# DEBUG
	if Input.is_action_just_pressed("Spawn 0 bit"):
		send_bit(0, 400)
	elif Input.is_action_just_pressed("Spawn 1 bit"):
		send_bit(1, 400)


## send a bit down the current line
func send_bit(value: bool, speed: int = 500):
	var new_bit = bit.instantiate()
	new_bit.create(value, position.y, speed)
	get_tree().root.call_deferred("add_child", new_bit)
	bit_stream.push_back(new_bit)
	
