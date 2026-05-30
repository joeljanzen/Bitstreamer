class_name Bit
extends Node2D
## a bit to send to the player


@onready var _label: Label = $BitLabel
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _timer: Timer = $Timer

static var bit_font: Theme = load("res://Resources/Themes/bit_font.tres")
## fades the bit away when it is clicked instead of disappearing instantly
static var bit_fade_effect = true

enum miss_effect_type {MOVE_OFFSCREEN, DISAPPEAR, FADE_OUT}
## the effect that plays when a bit is missed.
## FADE_OUT does the same as disappear unless bit_fade_effect is enabled
static var miss_effect: miss_effect_type = miss_effect_type.FADE_OUT
## how quickly the bit fades away after being clicked (default is 5).
## set to 0 to disable fade entirely
static var clicked_fade_speed = 5

## default bit speed
const DEFAULT_SPEED = 500
## default bit damage if missed
const DEFAULT_DAMAGE = 1

## where the bit starts
var _starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()
## the value of the bit (false is 0, true is 1)
var _value: BitType.Type
## the x position of the cursor
var _cursor_x: float
## the speed at which the bit travels across the screen
var _speed: int
## how much damage missing this bit does
var _damage: int
## dictates if it should start fading if bit_fade_effect is enabled
var _fade_bit = false
## if the bit has been missed (and isn't deleted yet)
var _is_missed = false


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
	if !_fade_bit || !bit_fade_effect:
		position.x -= _speed * delta
	elif bit_fade_effect:
		# decrease alpha value (opacity)
		if modulate.a < 0:
			queue_free()
		else:
			modulate.a -= clicked_fade_speed * delta
	
	# bit is missed
	if !_is_missed && PerformanceCalculator.is_missed(get_accuracy()):
		Signals.miss.emit(_damage)
		_is_missed = true
		
		match miss_effect:
			miss_effect_type.DISAPPEAR:
				queue_free()
			miss_effect_type.FADE_OUT:
				kill()
	
	# bit is offscreen
	if position.x < -Bit.get_width():
		if !_is_missed:
			Signals.miss.emit(_damage)
		queue_free()


## set bit data before appending to scene.
## cursor x position is used for accuracy calculations.
## a default speed and damage will be set if no values are provided
func create(value: BitType.Type, y_pos: int, cursor_x: float, speed: int = DEFAULT_SPEED, 
	damage: int = DEFAULT_DAMAGE) -> void:
	_value = value
	_cursor_x = cursor_x
	_speed = speed
	_damage = damage
	position = Vector2(_starting_x, y_pos)


## try to click the bit, returning if the player did.
## if not, the bit keeps going and can try to be clicked again
func click(value: BitType.Type) -> bool:
	var accuracy = get_accuracy()
	
	if PerformanceCalculator.is_clickable(accuracy):
		# successfully clicked
		if get_value() == value:
			Signals.score.emit(PerformanceCalculator.get_score(accuracy), 
				PerformanceCalculator.get_raw_score(accuracy))
		# clicked in time, but clicked the wrong key
		else:
			# enter key can only be clicked if you actually press enter, and
			# clicking enter does nothing to the other bits
			if get_value() == BitType.Type.ENTER || value == BitType.Type.ENTER:
				return false 
			# take damage and lose combo, as if you missed the bit
			elif get_value() == BitType.Type.ZERO || get_value() == BitType.Type.ONE:
				Signals.miss.emit(_damage)
				_is_missed = true
		
		kill()
		return true
	else:
		return false


## get rid of the bit (either right away, or let it fade away)
func kill() -> void:
	_timer.paused = true
	if bit_fade_effect:
		_fade_bit = true
	else:
		queue_free()


## get the accuracy of clicking the bit right now, in milliseconds off the perfect cursor click.
## a positive value is early by that many milliseconds, and a negative value is late
func get_accuracy() -> int:
	var time_to_click = _timer.wait_time - _timer.time_left
	var distance_to_cursor = _starting_x - _cursor_x # in pixels
	var time_to_cursor = distance_to_cursor / _speed # speed is in pixels per second, so we get seconds back
	var error_milliseconds: int = round((time_to_cursor - time_to_click) * 1000)
	#print("calculated milliseconds off perfect click: %s" % error_milliseconds)
	return error_milliseconds


## get the value of the bit (false is 0, true is 1)
func get_value() -> BitType.Type:
	return _value


## NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_width() -> int:
	return 28
