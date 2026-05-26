class_name Bit
extends Node2D
## a bit the player should click when it reaches the cursor

@onready var _label = $"Bit Label"
@onready var _sprite = $Sprite2D

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
var _value: BitType.Type
## the speed at which the bit travels across the screen
var _speed
var clicked_bit = false


func _ready() -> void:
	match _value:
		BitType.Type.ZERO:
			_sprite.hide()
			_label.text = "0"
		BitType.Type.ONE:
			_sprite.hide()
			_label.text = "1"
		BitType.Type.ENTER:
			_label.hide()


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
func create(value: BitType.Type, y_pos: int, speed: int = DEFAULT_SPEED) -> void:
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
func get_value() -> BitType.Type:
	return _value


## returns if the bit is clickable
func clickable(cursor_pos: Vector2) -> bool:
	return position.x <= cursor_pos.x + _click_range && !missed(cursor_pos.x) && cursor_pos.y == position.y


## returns if the bit has been missed (it has passed the clickable window)
func missed(cursor_x: int) -> bool:
	return position.x < cursor_x - _click_range


## set the distance before/past the cursor where the bit is considered clickable
## (in pixels)
func set_click_range(click_range: int) -> void:
	_click_range = click_range

# NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_width() -> int:
	return 28
# NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_height() -> int:
	# DOESNT WORK SADGE
	#return bit_font.default_font_size 
	return 54
