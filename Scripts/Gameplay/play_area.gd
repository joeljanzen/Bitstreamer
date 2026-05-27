extends Node2D
## the cursor indicating to the player when to click a bit

@onready var cursor = $Cursor
@onready var bit_label = $BitLabel
@onready var bit = preload("res://Scenes/bit.tscn")

## the last line before the cursor resets back to the top, clearing the bit_label
const MAX_LINE_NUM = 10

## stack of bits currently on screen
var bit_stream = []
## the speed the cursor blinks while idle
var flicker_speed = 4
## how far the cursor moves to change lines
var line_height = 84
## the current line number
var line_num = 1

## aesthetic stuff
var entered_bit_color = "#0D4C25"
var incorrect_bit_color = "#4c0d0d"


func _ready() -> void:
	bit_label.add_theme_color_override("default_color", Color(entered_bit_color))


func _process(_delta: float) -> void:
	# default animation
	if !cursor.is_playing():
		cursor.play("Flicker")
	
	# input handling
	if Input.is_action_just_pressed("0 bit"):
		# sound and animation here
		cursor.play("Click")
		click_bit(BitType.Type.ZERO)
	if Input.is_action_just_pressed("1 bit"):
		#sound and animation here
		cursor.play("Click")
		click_bit(BitType.Type.ONE)
	if Input.is_action_just_pressed("Enter"):
		#sound and animation here
		if click_enter():
			cursor.play("Enter")
		else:
			cursor.play("Cannot Enter")
	
	# let go of 1 or 0
	if Input.is_action_just_released("0 bit") || Input.is_action_just_released("1 bit"):
		cursor.play("Flicker")
	
	# delete bit if it goes offscreen
	if !bit_stream.is_empty() && bit_stream[0].missed(cursor.global_position.x):
		var missed = bit_stream.pop_front()
		# still clicks enter if you miss it
		if missed.get_value() == BitType.Type.ENTER:
			cursor.play("Enter")
			missed.auto_clicked()
			if line_num < MAX_LINE_NUM:
				line_num += 1
				bit_label.text += "\n"
				cursor.position.y += line_height
				cursor.position.x = 0
			else:
				clear_lines()
	
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
	new_bit.create(value, cursor.global_position.y, speed)
	get_tree().root.call_deferred("add_child", new_bit)
	bit_stream.push_back(new_bit)


## try to click the next bit in the stream, returning if it's successful.
## do not pass an enter bit into this function
func click_bit(value: BitType.Type) -> bool:
	if !bit_stream.is_empty():
		var curr_bit = bit_stream[0]
		
		if curr_bit.clickable(cursor.global_position):
			bit_stream.pop_front()

			if curr_bit.get_value() == value: 	
				curr_bit.clicked(cursor.global_position.x)
				if value == BitType.Type.ZERO:
					bit_label.text += "0"
				elif value == BitType.Type.ONE:
					bit_label.text += "1"
			else:
				curr_bit.wrong_clicked()
				if value == BitType.Type.ZERO:
					bit_label.text += "[color=%s]0[/color]" % incorrect_bit_color
				elif value == BitType.Type.ONE:
					bit_label.text += "[color=%s]1[/color]" % incorrect_bit_color
			return true
	return false


## try to click an enter bit, returning if the player can
func click_enter() -> bool:
	if !bit_stream.is_empty():
		var curr_bit: Bit = bit_stream[0]
		if curr_bit.clickable(cursor.global_position) && curr_bit.get_value() == BitType.Type.ENTER:
			bit_stream.pop_front()
			curr_bit.clicked(cursor.global_position.x)
			if line_num < MAX_LINE_NUM:
				line_num += 1
				bit_label.text += "\n"
				cursor.position.y += line_height
				cursor.position.x = 0
			else: 
				clear_lines()
			return true
	return false


## clears all lines and resets the cursor to the top
func clear_lines():
	line_num = 1
	cursor.position = Vector2.ZERO
	bit_label.text = ""
