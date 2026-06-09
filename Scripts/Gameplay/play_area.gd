class_name PlayArea
extends Node2D
## The cursor indicating to the player when to click a bit.

@onready var _cursor: AnimatedSprite2D = $Cursor
@onready var _bit_label: RichTextLabel = $BitLabel
@onready var _bit_click_sound: AudioStreamPlayer = $BitClick
@onready var _bit_miss_sound: AudioStreamPlayer = $BitMiss
@onready var _empty_click_sound: AudioStreamPlayer = $EmptyClick
@onready var _line_clear_sound: AudioStreamPlayer = $LineClear
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

## The ending y position of the cursor (when it's on the last line).
var _ending_cursor_y

## Signifies when to reset the cursor back to the top.
var _ready_for_line_clear := false

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
	_ending_cursor_y = _starting_cursor_y + _line_height * (MAX_LINE_NUM - 1)


## Handles inputs and animations.
func _process(_delta: float) -> void:
	# Ensure default cursor animation.
	if !_cursor.is_playing():
		_cursor.play("flicker")
	
	# Input handling.
	if Input.is_action_just_pressed("0_bit"):
		if !_click_bit(Bit.Type.ZERO):
			_miss_click_zero_one()
	if Input.is_action_just_pressed("1_bit"):
		if !_click_bit(Bit.Type.ONE):
			_miss_click_zero_one()
	if Input.is_action_just_pressed("enter_bit"):
		if !_click_bit(Bit.Type.ENTER):
			_miss_click_enter()
	
	# Go back to flickering cursor when letting go of 1 or 0.
	if Input.is_action_just_released("0_bit") or Input.is_action_just_released("1_bit") or Input.is_action_just_released("enter_bit"):
		_cursor.play("flicker")
	
	# Signals that the level has been completed.
	if _last_bits_sent and _bitstream.is_empty():
		no_bits_left.emit()
	
	# DEBUG!
	if Input.is_action_just_pressed("spawn_0_bit"):
		send_bit(Bit.Type.ZERO, DEBUG_BIT_SPEED, DEBUG_BIT_DAMAGE)
	elif Input.is_action_just_pressed("spawn_1_bit"):
		send_bit(Bit.Type.ONE, DEBUG_BIT_SPEED, DEBUG_BIT_DAMAGE)
	elif Input.is_action_just_pressed("spawn_enter"):
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
			_ready_for_line_clear = true
			_line_num = 1


## Get the amount of time it takes for the bit to reach the cursor in seconds,
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
	_empty_click_sound.play()


## The animations and sounds that trigger when miss-clicking an enter bit.
func _miss_click_enter() -> void:
	_cursor.play("cannot_enter")
	_empty_click_sound.play()


## The animations and sounds that trigger when missing a zero or one bit.
## Not the same as incorrectly clicking a zero or one bit. That still counts
## as clicking it, see those functions below.
func _miss_zero_one() -> void:
	_bit_label.text += "[color=%s]_[/color]" % missed_bit_color
	_bit_miss_sound.play()


## The animations and sounds that trigger when entirely missing an enter bit.
func _miss_enter() -> void:
	# Literally the same as clicking enter for now 
	# (will play different sound and animation later).
	_cursor.play("enter")
	_bit_miss_sound.play()
	_new_line()


## The animations and sounds that trigger when clicking a zero bit
## (different outcome depending on correct or incorrect click).
func _click_zero(correct_click: bool) -> void:
	_cursor.play("click")
	if correct_click:
		_bit_click_sound.play()
		_bit_label.text += "0"
	else:
		_bit_miss_sound.play()
		_bit_label.text += "[color=%s]0[/color]" % incorrect_bit_color


## The animations and sounds that trigger when clicking a one bit
## (different outcome depending on correct or incorrect click).
func _click_one(correct_click: bool) -> void:
	_cursor.play("click")
	if correct_click:
		_bit_click_sound.play()
		_bit_label.text += "1"
	else:
		_bit_miss_sound.play()
		_bit_label.text += "[color=%s]1[/color]" % incorrect_bit_color


## The animations and sounds that trigger when clicking an enter bit
## (you cannot incorrectly click an enter bit, you either click it right or 
## the game clicks it for you).
func _click_enter() -> void:
	_cursor.play("enter")
	_bit_click_sound.play()
	_new_line()


## The animations and sounds that trigger when moving down to the next line. 
## Triggered by an enter bit click (or miss).
func _new_line() -> void:
	# Check for the cursor to be at the right y position, to ensure the other 
	# enter bits before the one on the last line have all been hit/missed 
	# already.
	if _ready_for_line_clear and _cursor.global_position.y == _ending_cursor_y:
		_line_clear_sound.play()
		_cursor.position.y -= _line_height * (MAX_LINE_NUM - 1)
		_bit_label.text = ""
		_ready_for_line_clear = false
	else:
		_bit_label.text += "\n"
		_cursor.position.y += _line_height
