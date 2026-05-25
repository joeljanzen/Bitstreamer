class_name Bit
extends Node2D
## a bit the player should click when it reaches the cursor

@onready var _label = $Label

static var bit_font: Theme = load("res://Resources/Themes/bit_font.tres")
static var bit_fade_effect = true

## default bit speed
const DEFAULT_SPEED = 500
## how quickly the bit fades away after being clicked.
## set to 0 to disable fade entirely
const CLICKED_FADE_SPEED = 5

## how many pixels before/past the cursor where the bit is considered clickable
var _click_range = 100
## where the bit starts
var _starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()
## the value of the bit (false is 0, true is 1)
var _value
## the speed at which the bit travels across the screen
var _speed
var clicked_bit = false


func _ready() -> void:
	if _value == false:
		_label.text = "0"
	else:
		_label.text = "1"


func _process(delta: float) -> void:
	if !clicked_bit || !bit_fade_effect:
		position.x -= _speed * delta
	elif bit_fade_effect:
		# decrease alpha value (opacity)
		modulate.a -= CLICKED_FADE_SPEED * delta
	
	# bit is offscreen
	if position.x < -Bit.get_width() || (bit_fade_effect && modulate.a == 0):
		queue_free()


## set bit data before appending to scene
func create(value: bool, y_pos: int, speed: int = DEFAULT_SPEED) -> void:
	_value = value
	_speed = speed
	position = Vector2(_starting_x, y_pos)


## click the bit
func clicked(cursor_x: int) -> void:
	#play animation and sound idk
	var acc = abs(position.x - cursor_x)
	print("distance to cursor: %s" % acc)
	if bit_fade_effect:
		clicked_bit = true
	else:
		queue_free()


## get the value of the bit (false is 0, true is 1)
func get_value() -> bool:
	return _value


## returns if the bit is clickable
func clickable(cursor_x: int) -> bool:
	return position.x <= cursor_x + _click_range && !missed(cursor_x)


## returns if the bit has been missed (it has passed the clickable window)
func missed(cursor_x: int) -> bool:
	return position.x < cursor_x - _click_range


## set the distance before/past the cursor where the bit is considered clickable
## (in pixels)
func set_click_range(click_range: int):
	_click_range = click_range

# NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_width() -> int:
	return 28
# NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_height() -> int:
	# DOESNT WORK SADGE
	#return bit_font.default_font_size 
	return 54
