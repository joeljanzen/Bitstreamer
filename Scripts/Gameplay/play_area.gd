class_name PlayArea
extends Node2D
## The cursor indicating to the player when to click a bit.

@onready var _cursor: AnimatedSprite2D = $Cursor
@onready var _bit_label: RichTextLabel = $BitLabel
@onready var _border: ColorRect = $Border
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

## The number of bits shown on the terminal before additional bits are ignored.
## It's good practice to move to the next line before this limit is reached.
const MAX_BITS_DISPLAYED_PER_LINE := 32

## All bits have been clicked or missed.
signal no_bits_left

## The stack of bits currently on screen (commonly referred to as the "stream").
var _bitstream = []

## An array of all 10 lines that the cursor types bits onto.
var _label_lines = []

## How far the cursor moves to change lines (in pixels).
var _line_height: int = 84

## The current line number.
var _line_num: int = 1

## The line number to send the next bit down.
var _bit_send_line_num: int = 1

## The starting y position of the cursor.
var _starting_cursor_y

## The ending y position of the cursor (when it's on the last line).
var _ending_cursor_y

## Signifies when to reset the cursor back to the top.
var _ready_for_line_clear := false

## The last bits have been sent, prepare to send the no_bits_left signal.
var _last_bits_sent := false


## Connect to the missed (a bit) gameplay signal and set default bit colour.
func _ready() -> void:
	_label_lines.resize(MAX_LINE_NUM)
	_clear_bit_label_lines()
	Signals.missed.connect(_missed_bit)
	_bit_label.add_theme_color_override("default_color", Color(GameSettings.entered_bit_colour))
	_border.color = GameSettings.zero_bit_colour
	
	set_cursor_animation(GameSettings.cursor_flicker)
	
	_starting_cursor_y = _cursor.global_position.y
	_ending_cursor_y = _starting_cursor_y + _line_height * (MAX_LINE_NUM - 1)


## Ensure the cursor plays default animation and poll for level completion.
func _process(_delta: float) -> void:
	# Needed when the enter or back bit is missed, but an animation still plays.
	# After that animation ends, this code brings us back to "flicker" or "static"
	if !_cursor.is_playing():
		if GameSettings.cursor_flicker:
			_cursor.play("flicker")
		elif _cursor.animation != "static":
			_cursor.play("static")
	
	if _last_bits_sent and _bitstream.is_empty():
		no_bits_left.emit()
		_last_bits_sent = false # Ensure the signal is only emitted once.


## Input handling.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("0_bit"):
		if !_click_bit(Bit.Type.ZERO):
			_miss_click_zero_one()
	if event.is_action_pressed("1_bit"):
		if !_click_bit(Bit.Type.ONE):
			_miss_click_zero_one()
	if event.is_action_pressed("enter_bit"):
		if !_click_bit(Bit.Type.ENTER):
			_miss_click_enter_back()
	if event.is_action_pressed("back_bit"):
		if !_click_bit(Bit.Type.BACK):
			_miss_click_enter_back()
	
	if (
				event.is_action_released("0_bit") or 
				event.is_action_released("1_bit") or 
				event.is_action_released("enter_bit") or 
				event.is_action_released("back_bit")
	):
		if GameSettings.cursor_flicker:
			_cursor.play("flicker")
		else:
			_cursor.play("static")


## Updates the border color, in the event of theme color changes.
func update_border_color() -> void:
	_border.color = GameSettings.zero_bit_colour


## Manually set the current cursor animation.
func set_cursor_animation(flicker: bool) -> void:
	if flicker:
		_cursor.play("flicker")
	else:
		_cursor.play("static")


## Send a bit down the current line.
func send_bit(value: Bit.Type, time_to_cursor: float, damage: int, 
		conductor: Conductor):
	var new_bit: Bit = _bit.instantiate()
	# Calculate y value based on the current line number offset from where the
	# cursor started.
	var y_value = _starting_cursor_y + (_line_height * (_bit_send_line_num - 1))
	add_child(new_bit)
	new_bit.create(value, y_value, _cursor.global_position.x, time_to_cursor, 
			damage, conductor)
	_bitstream.push_back(new_bit)
	
	# Increase line number for next bit when an enter is sent:
	if value == Bit.Type.ENTER:
		if _bit_send_line_num < MAX_LINE_NUM:
			_bit_send_line_num += 1
		else:
			_ready_for_line_clear = true
			_bit_send_line_num = 1
	if value == Bit.Type.BACK:
		if _bit_send_line_num > 1:
			_bit_send_line_num -= 1


## Notify the play area that the last bits have been sent.
## It will then emit its no_bits_left signal once there are no more bits
## on the screen.
func last_bits_sent() -> void:
	_last_bits_sent = true


## Manually set the line number of the cursor. This will affect where the 
## next bits will spawn.
func override_line_num(override_value: int) -> void:
	if override_value > MAX_LINE_NUM:
		override_value = MAX_LINE_NUM
	elif override_value < 1:
		override_value = 1
		
	if override_value != _bit_send_line_num:
		# Set proper cursor position.
		var cursor_line_offset = override_value - _bit_send_line_num
		_cursor.position.y += _line_height * cursor_line_offset
		
		_bit_send_line_num = override_value
		_line_num = override_value


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
				Bit.Type.BACK:
					_click_back()
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
			Bit.Type.BACK:
				_miss_back()

# Updating the play area in response to inputs,
# including animations and sounds.

## The animations and sounds that trigger when miss-clicking a zero or one bit.
func _miss_click_zero_one() -> void:
	_cursor.play("click")
	_empty_click_sound.play()


## The animations and sounds that trigger when miss-clicking an enter or back 
## bit.
func _miss_click_enter_back() -> void:
	_cursor.play("cannot_enter")
	_empty_click_sound.play()


## The animations and sounds that trigger when missing a zero or one bit.
## Not the same as incorrectly clicking a zero or one bit. That still counts
## as clicking it, see those functions below.
func _miss_zero_one() -> void:
	_add_to_bit_label_line("[color=%s]_[/color]" % GameSettings.missed_bit_colour)
	_fill_bit_label_lines()
	_bit_miss_sound.play()


## The animations and sounds that trigger when entirely missing an enter bit.
func _miss_enter() -> void:
	_cursor.play("enter")
	_bit_miss_sound.play()
	_new_line(true)


## The animations and sounds that trigger when entirely missing a back bit.
func _miss_back() -> void:
	_cursor.play("back")
	_bit_miss_sound.play()
	_new_line(false)


## The animations and sounds that trigger when clicking a zero bit
## (different outcome depending on correct or incorrect click).
func _click_zero(correct_click: bool) -> void:
	_cursor.play("click")
	if correct_click:
		_bit_click_sound.play()
		_add_to_bit_label_line("0")
	else:
		_bit_miss_sound.play()
		_add_to_bit_label_line("[color=%s]0[/color]" % GameSettings.incorrect_bit_colour)
	_fill_bit_label_lines()


## The animations and sounds that trigger when clicking a one bit
## (different outcome depending on correct or incorrect click).
func _click_one(correct_click: bool) -> void:
	_cursor.play("click")
	if correct_click:
		_bit_click_sound.play()
		_add_to_bit_label_line("1")
	else:
		_bit_miss_sound.play()
		_add_to_bit_label_line("[color=%s]1[/color]" % GameSettings.incorrect_bit_colour)
	_fill_bit_label_lines()


## The animations and sounds that trigger when clicking an enter bit
## (you cannot incorrectly click an enter bit, you either click it right or 
## the game clicks it for you).
func _click_enter() -> void:
	_cursor.play("enter")
	_bit_click_sound.play()
	_new_line(true)


## The animations and sounds that trigger when clicking a back bit
## (you cannot incorrectly click a back bit, you either click it right or 
## the game clicks it for you).
func _click_back() -> void:
	_cursor.play("back")
	_bit_click_sound.play()
	_new_line(false)


## The animations and sounds that trigger when moving to the next line. Moves 
## down if passed true, or up otherwise.
## Triggered by an enter or back bit click (or miss).
func _new_line(move_down: bool) -> void:
	# Check for the cursor to be at the right y position, to ensure the other 
	# enter bits before the one on the last line have all been hit/missed 
	# already.
	if _ready_for_line_clear and _cursor.global_position.y == _ending_cursor_y and move_down:
		_line_clear_sound.play()
		_cursor.position.y -= _line_height * (MAX_LINE_NUM - 1)
		_ready_for_line_clear = false
		_clear_bit_label_lines()
		_line_num = 1
	elif move_down:
		_cursor.position.y += _line_height
		_line_num += 1
	elif _cursor.global_position.y != _starting_cursor_y: # Move up.
		_cursor.position.y -= _line_height
		_line_num -= 1


## Add a string to the current active line on the terminal (the bit label).
func _add_to_bit_label_line(string: String) -> void:
	var curr_line = _line_num - 1
	
	# Need to remove potential BBCode markup from the string to get its 
	# actual length (error bits are colored with BBCode markup).
	var temp_label = RichTextLabel.new()
	temp_label.bbcode_enabled = true
	temp_label.text = _label_lines[curr_line]
	
	if temp_label.get_parsed_text().length() < MAX_BITS_DISPLAYED_PER_LINE:
		_label_lines[curr_line] += string


## Fills in the bit label using the values in the _label_lines array.
func _fill_bit_label_lines() -> void:
	_bit_label.text = ""
	
	for index in range(_label_lines.size()):
		var curr_line = _label_lines[index]
		_bit_label.text += curr_line + "\n"


## Reset the bit label and _label_lines array to empty.
func _clear_bit_label_lines() -> void:
	_label_lines.fill("")
	_bit_label.text = ""
