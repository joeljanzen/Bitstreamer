class_name PlayArea
extends Node2D
## The cursor indicating to the player when to click a bit.

@onready var _cursor: AnimatedSprite2D = $Cursor
@onready var _bit_label: RichTextLabel = $BitLabel
@onready var _bit = preload("res://Scenes/bit.tscn")

## The speed of manually spawned bits.
const DEBUG_BIT_SPEED := 1600

## The damage manually spawned bits deal.
const DEBUG_BIT_DAMAGE := 5

## The last line before the cursor resets back to the top, 
## clearing the bit_label.
const MAX_LINE_NUM := 10

## All bits have been clicked or missed.
signal no_bits_left

## The stack of bits currently on screen (commonly referred to as the "stream").
var _bitstream = []

## How far the cursor moves to change lines (in pixels).
var _line_height: int = 84

## The current line number.
var _line_num: int = 1

## The starting y position of the cursor.
var _starting_cursor_y

## The last bits have been sent, prepare to send the no_bits_left signal.
var _last_bits_sent := false

# Aesthetic variables.
## The colour displayed for correctly entered bits.
## Change to ffffff for a cool glow, but less visibility.
var entered_bit_color := "#454545"
## The colour displayed for incorrectly entered bits.
var incorrect_bit_color := "#2E0606"
## The colour displayed for incorrectly entered bits.
var missed_bit_color := "#454545"


## Connect to the missed (a bit) gameplay signal and set default bit colour.
func _ready() -> void:
	_bit_label.text = ""
	Signals.missed.connect(_missed_bit)
	_bit_label.add_theme_color_override("default_color", Color(entered_bit_color))
	
	_starting_cursor_y = _cursor.global_position.y


## Handles inputs and animations.
func _process(_delta: float) -> void:
	# Ensure default cursor animation.
	if !_cursor.is_playing():
		_cursor.play("flicker")
	
	# Input handling.
	if Input.is_action_just_pressed("0 bit"):
		if !_click_bit(Bit.Type.ZERO):
			_miss_click_zero_one()
	if Input.is_action_just_pressed("1 bit"):
		if !_click_bit(Bit.Type.ONE):
			_miss_click_zero_one()
	if Input.is_action_just_pressed("enter"):
		if !_click_bit(Bit.Type.ENTER):
			_miss_click_enter()
	
	# Go back to flickering cursor when letting go of 1 or 0.
	if Input.is_action_just_released("0 bit") or Input.is_action_just_released("1 bit"):
		_cursor.play("flicker")
	
	# Signals that the level has been completed.
	if _last_bits_sent and _bitstream.is_empty():
		no_bits_left.emit()
	
	# DEBUG!
	if Input.is_action_just_pressed("spawn 0 bit"):
		send_bit(Bit.Type.ZERO, DEBUG_BIT_SPEED, DEBUG_BIT_DAMAGE)
	elif Input.is_action_just_pressed("spawn 1 bit"):
		send_bit(Bit.Type.ONE, DEBUG_BIT_SPEED, DEBUG_BIT_DAMAGE)
	elif Input.is_action_just_pressed("spawn enter"):
		send_bit(Bit.Type.ENTER, DEBUG_BIT_SPEED, 0)


## Set the speed the cursor flickers, based on a BPM.
func set_cursor_flicker_speed(bpm: float) -> void:
	var FPS = bpm / 60.0
	print("should be flickering at %f FPS" % FPS)
	_cursor.play("flicker")
	_cursor.get_sprite_frames().set_animation_speed("flicker", FPS)


## Send a bit down the current line.
func send_bit(value: Bit.Type, speed: int, damage: int):
	var new_bit: Bit = _bit.instantiate()
	# Calculate y value based on the current line number offset from where the
	# cursor started.
	var y_value = _starting_cursor_y + (_line_height * (_line_num - 1))
	add_child(new_bit)
	new_bit.create(value, y_value, _cursor.global_position.x, speed, damage)
	_bitstream.push_back(new_bit)
	
	# Increase line number for next bit when an enter is sent:
	if value == Bit.Type.ENTER:
		if _line_num < MAX_LINE_NUM:
			_line_num += 1
		else:
			_line_num = 1


## Get the amount of time it takes for the bit to reach the cursor, in seconds
## given the speed of the bit (in pixels per second).
func get_time_to_cursor(speed: float) -> float:
	# Distance in pixels.
	var distance_to_cursor = Bit.starting_x - _cursor.global_position.x
	#print("distance to cursor is %d" % distance_to_cursor)
	return distance_to_cursor / speed


## Notify the play area that the last bits have been sent.
## It will then emit its no_bits_left signal once there are no more bits
## on the screen.
func last_bits_sent() -> void:
	_last_bits_sent = true


## Try to click the next bit in the stream.
## Returns true if the click worked.
func _click_bit(value: Bit.Type) -> bool:
	if !_bitstream.is_empty():
		var curr_bit: Bit = _bitstream[0]
		
		if curr_bit.click(value): # if this isn't true, bit is not clickable
			var correct_click = curr_bit.get_value() == value
			if correct_click: # will be popped off in the missed_bit func otherwise
				_bitstream.pop_front()
			
			match value:
				Bit.Type.ZERO:
					_click_zero(correct_click)
				Bit.Type.ONE:
					_click_one(correct_click)
				Bit.Type.ENTER:
					_click_enter()
			return true
	return false # bit stream was empty


## Missed a bit, so remove from the stream.
func _missed_bit(_damage, _click_quality):
	if !_bitstream.is_empty():
		var missed: Bit = _bitstream.pop_front()
		
		match missed.get_value():
			Bit.Type.ZERO:
				if _click_quality == PerformanceCalculator.ClickQuality.MISS:
					_miss_zero_one()
			Bit.Type.ONE:
				if _click_quality == PerformanceCalculator.ClickQuality.MISS:
					_miss_zero_one()
			Bit.Type.ENTER:
				_miss_enter()

# Updating the play area in response to inputs,
# including animations and sounds.

## The animations and sounds that trigger when miss-clicking a zero or one bit.
func _miss_click_zero_one() -> void:
	_cursor.play("click")


## The animations and sounds that trigger when miss-clicking an enter bit.
func _miss_click_enter() -> void:
	_cursor.play("cannot_enter")


## The animations and sounds that trigger when missing a zero or one bit.
func _miss_zero_one():
	_bit_label.text += "[color=%s]_[/color]" % missed_bit_color


## The animations and sounds that trigger when entirely missing an enter bit.
func _miss_enter():
	# Literally the same as clicking enter for now 
	# (will play different sound and animation later).
	_click_enter() 


## The animations and sounds that trigger when clicking a zero bit
## (different outcome depending on correct or incorrect click).
func _click_zero(correct_click: bool):
	_cursor.play("click")
	if correct_click:
		_bit_label.text += "0"
	else:
		_bit_label.text += "[color=%s]0[/color]" % incorrect_bit_color


## The animations and sounds that trigger when clicking a one bit
## (different outcome depending on correct or incorrect click).
func _click_one(correct_click: bool):
	_cursor.play("click")
	if correct_click:
		_bit_label.text += "1"
	else:
		_bit_label.text += "[color=%s]1[/color]" % incorrect_bit_color


## The animations and sounds that trigger when clicking an enter bit
## (you cannot incorrectly click an enter bit, you either click it right or 
## the game clicks it for you).
func _click_enter():
	_cursor.play("enter")
	if _line_num < MAX_LINE_NUM:
		_bit_label.text += "\n"
		_cursor.position.y += _line_height
	else: ## clears all lines and resets the cursor to the top
		_cursor.position.y -= _line_height * (MAX_LINE_NUM - 1)
		_bit_label.text = ""
