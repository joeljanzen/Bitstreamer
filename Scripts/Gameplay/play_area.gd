extends Node2D
## the cursor indicating to the player when to click a bit

@onready var cursor = $Cursor
@onready var bit_label = $BitLabel
@onready var bit = preload("res://Scenes/bit.tscn")

## speed of manually spawned bits
const DEBUG_BIT_SPEED = 800
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
	Signals.miss.connect(missed_bit)
	bit_label.add_theme_color_override("default_color", Color(entered_bit_color))


func _process(_delta: float) -> void:
	# ensure default cursor animation
	if !cursor.is_playing():
		cursor.play("flicker")
	
	# input handling
	if Input.is_action_just_pressed("0 bit"):
		if !click_bit(BitType.Type.ZERO):
			miss_click_zero_one()
	if Input.is_action_just_pressed("1 bit"):
		if !click_bit(BitType.Type.ONE):
			miss_click_zero_one()
	if Input.is_action_just_pressed("enter"):
		if !click_bit(BitType.Type.ENTER):
			miss_click_enter()
	
	# let go of 1 or 0, go back to flickering cursor
	if Input.is_action_just_released("0 bit") || Input.is_action_just_released("1 bit"):
		cursor.play("flicker")
	
	# DEBUG
	if Input.is_action_just_pressed("spawn 0 bit"):
		send_bit(BitType.Type.ZERO, DEBUG_BIT_SPEED)
	elif Input.is_action_just_pressed("spawn 1 bit"):
		send_bit(BitType.Type.ONE, DEBUG_BIT_SPEED)
	elif Input.is_action_just_pressed("spawn enter"):
		send_bit(BitType.Type.ENTER, DEBUG_BIT_SPEED)


## send a bit down the current line
func send_bit(value: BitType.Type, speed: int):
	var new_bit: Bit = bit.instantiate()
	new_bit.create(value, cursor.global_position.y, cursor.global_position.x, speed)
	get_tree().root.call_deferred("add_child", new_bit)
	bit_stream.push_back(new_bit)


## try to click the next bit in the stream.
## returns true if the click worked
func click_bit(value: BitType.Type) -> bool:
	if !bit_stream.is_empty():
		var curr_bit: Bit = bit_stream[0]
		
		if curr_bit.click(value): # if this isn't true, bit is not clickable
			var correct_click = curr_bit.get_value() == value
			if correct_click: # will be popped off in the missed_bit func otherwise
				bit_stream.pop_front()
			
			match value:
				BitType.Type.ZERO:
					click_zero(correct_click)
				BitType.Type.ONE:
					click_one(correct_click)
				BitType.Type.ENTER:
					click_enter()
			return true
	return false # bit stream was empty


## missed a bit, so remove from stream
func missed_bit(_damage):
	var missed: Bit = bit_stream.pop_front()
	
	match missed.get_value():
		BitType.Type.ZERO:
			miss_zero_one()
		BitType.Type.ONE:
			miss_zero_one()
		BitType.Type.ENTER:
			miss_enter()

# updating the play area in response to inputs
# including animations and sounds

## the animations and sounds that trigger when miss-clicking a zero or one bit
func miss_click_zero_one() -> void:
	cursor.play("click")


## the animations and sounds that trigger when miss-clicking an enter bit
func miss_click_enter() -> void:
	cursor.play("cannot_enter")


## the animations and sounds that trigger when missing a zero or one bit.
## WARNING: this will also trigger if there is an incorrect bit click 
func miss_zero_one():
	pass


## the animations and sounds that trigger when entirely missing an enter bit
func miss_enter():
	#literally the same for now (will play different sound and animation later)
	click_enter() 


## the animations and sounds that trigger when clicking a zero bit
## (different outcome depending on correct or incorrect click)
func click_zero(correct_click: bool):
	cursor.play("click")
	if correct_click:
		bit_label.text += "0"
	else:
		bit_label.text += "[color=%s]0[/color]" % incorrect_bit_color


## the animations and sounds that trigger when clicking a one bit
## (different outcome depending on correct or incorrect click)
func click_one(correct_click: bool):
	cursor.play("click")
	if correct_click:
		bit_label.text += "1"
	else:
		bit_label.text += "[color=%s]1[/color]" % incorrect_bit_color


## ## the animations and sounds that trigger when clicking an enter bit
## (you cannot incorrectly click an enter bit, you either click it right or 
## the game clicks it for you)
func click_enter():
	cursor.play("enter")
	if line_num < MAX_LINE_NUM:
		line_num += 1
		bit_label.text += "\n"
		cursor.position.y += line_height
		cursor.position.x = 0
	else: ## clears all lines and resets the cursor to the top
		line_num = 1
		cursor.position = Vector2.ZERO
		bit_label.text = ""
