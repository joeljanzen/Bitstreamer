extends AnimatedSprite2D
## the cursor indicating to the player when to click a bit

@export var bit_label: Label

@onready var start_x_pos = position.x
@onready var start_y_pos = position.y
@onready var bit = preload("res://Scenes/bit.tscn")

## stack of bits currently on screen
var bit_stream = []
# the speed the cursor blinks while idle
var flicker_speed = 4


func _process(delta: float) -> void:
	# default animation
	if !is_playing():
		play("Flicker")
	
	# input handling
	if Input.is_action_just_pressed("0 bit"):
		# sound and animation here
		play("Click")
		click_bit(0)
	if Input.is_action_just_pressed("1 bit"):
		#sound and animation here
		play("Click")
		click_bit(1)
	if Input.is_action_just_pressed("Enter"):
		#sound and animation here
		if click_enter():
			play("Enter")
		else:
			play("Cannot Enter")
	
	# let go of 1 or 0
	if Input.is_action_just_released("0 bit") || Input.is_action_just_released("1 bit"):
		play("Flicker")
	
	# delete bit if it goes offscreen
	if !bit_stream.is_empty() && bit_stream[0].missed(position.x):
		var missed = bit_stream.pop_front()
		# still clicks enter if you miss it
		if missed.get_value() == BitType.Type.ENTER:
			play("Cannot Enter")
			missed.clicked(position.x)
			bit_label.text += "\n"
			position.y += Bit.get_height()
			position.x = start_x_pos

	# DEBUG
	if Input.is_action_just_pressed("Spawn 0 bit"):
		send_bit(BitType.Type.ZERO, 400)
	elif Input.is_action_just_pressed("Spawn 1 bit"):
		send_bit(BitType.Type.ONE, 400)
	elif Input.is_action_just_pressed("Spawn Enter"):
		send_bit(BitType.Type.ENTER, 400)


## send a bit down the current line
func send_bit(value: BitType.Type, speed: int = 500):
	var new_bit = bit.instantiate()
	new_bit.create(value, position.y, speed)
	get_tree().root.call_deferred("add_child", new_bit)
	bit_stream.push_back(new_bit)


## try to click the next bit in the stream, returning if it's successful
func click_bit(value: BitType.Type) -> bool:
	if !bit_stream.is_empty():
		var curr_bit = bit_stream[0]
		if curr_bit.get_value() == value && curr_bit.clickable(position):
			curr_bit = bit_stream.pop_front()
			curr_bit.clicked(position.x)
			if value == BitType.Type.ZERO:
				bit_label.text += "0"
			elif value == BitType.Type.ONE:
				bit_label.text += "1"
			return true
	return false


## try to click an enter bit, returning if it's successful
func click_enter() -> bool:
	if !bit_stream.is_empty():
		var curr_bit: Bit = bit_stream[0]
		if curr_bit.clickable(position) && curr_bit.get_value() == BitType.Type.ENTER:
			curr_bit = bit_stream.pop_front()
			curr_bit.clicked(position.x)
			bit_label.text += "\n"
			position.y += Bit.get_height()
			position.x = start_x_pos
			return true
	return false
