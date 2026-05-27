class_name Bit
extends Node2D
## a bit to send to the player

@onready var _label = $BitLabel
@onready var _sprite = $Sprite2D
@onready var timer = $Timer

static var bit_font: Theme = load("res://Resources/Themes/bit_font.tres")
static var bit_fade_effect = true

## default bit speed
const DEFAULT_SPEED = 500
## default bit damage if missed
const DEFAULT_DAMAGE = 2
## how quickly the bit fades away after being clicked.
## set to 0 to disable fade entirely
const CLICKED_FADE_SPEED = 5

# the score given for a certain accuracy of click
const PERFECT_CLICK_SCORE = 300
const GOOD_CLICK_SCORE = 100
const BAD_CLICK_SCORE = 50
## multiply the base damage by this amount on an incorrect click
const INCORRECT_DAMAGE_MULT = 3

## how many pixels before/past the cursor where the bit is considered clickable
var _click_range = 100
## where the bit starts
var _starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()
## the value of the bit (false is 0, true is 1)
var _value: BitType.Type
## the speed at which the bit travels across the screen
var _speed
## how much damage missing this bit does
var _damage
var _clicked_bit = false


func _ready() -> void:
	# set bit appearance
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
	if !_clicked_bit || !bit_fade_effect:
		position.x -= _speed * delta
	elif bit_fade_effect:
		# decrease alpha value (opacity)
		modulate.a -= CLICKED_FADE_SPEED * delta
		
	if !timer.is_stopped() && position.x < 306: # x pos of the cursor here
		print("time to cursor: %s" % (timer.wait_time - timer.time_left))
		timer.stop()
	
	# bit is offscreen
	if position.x < -Bit.get_width() || (bit_fade_effect && modulate.a == 0):
		Signals.combo_break.emit()
		Signals.damage.emit(_damage)
		queue_free()


## set bit data before appending to scene.
## a default speed and damage will be set if no values are provided
func create(value: BitType.Type, y_pos: int, speed: int = DEFAULT_SPEED, 
	damage: int = DEFAULT_DAMAGE) -> void:
	_value = value
	_speed = speed
	_damage = damage
	position = Vector2(_starting_x, y_pos)


## click the bit
func clicked(cursor_x: float) -> void:
	#play animation and sound idk
	var acc = abs(position.x - cursor_x)
	print("distance to cursor: %s" % acc)
	
	print("time to click: %s" % (timer.wait_time - timer.time_left))
	timer.stop()
	
	Signals.score.emit(acc)
	
	if bit_fade_effect:
		_clicked_bit = true
	else:
		queue_free()


## the player clicked, but it was the wrong bit!
## your score decreases by the value of a perfect click, take double damage, and lose combo
func wrong_clicked() -> void:
	Signals.score.emit(-PERFECT_CLICK_SCORE)
	Signals.damage.emit(_damage * INCORRECT_DAMAGE_MULT)
	Signals.combo_break.emit()
	
	if bit_fade_effect:
		_clicked_bit = true
	else:
		queue_free()


## the game clicked the bit for you! (combo breaks and you don't get score)
func auto_clicked() -> void:
	Signals.combo_break.emit()
	
	if bit_fade_effect:
		_clicked_bit = true
	else:
		queue_free()


## get the value of the bit (false is 0, true is 1)
func get_value() -> BitType.Type:
	return _value


## returns if the bit is clickable
func clickable(cursor_pos: Vector2) -> bool:
	return position.x <= cursor_pos.x + float(_click_range) && !missed(cursor_pos.x) && cursor_pos.y == position.y


## returns if the bit has been missed (it has passed the clickable window)
func missed(cursor_x: float) -> bool:
	return position.x < cursor_x - float(_click_range)


## set the distance before/past the cursor where the bit is considered clickable
## (in pixels)
func set_click_range(click_range: int) -> void:
	_click_range = click_range

# NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_width() -> int:
	return 28
