class_name Bit
extends Node2D
## A bit to send to the player to click.

@onready var _label: Label = $BitLabel
@onready var _sprite: Sprite2D = $BitSprite
@onready var _timer: Timer = $Timer

## The types of bits.
enum Type {ZERO, ONE, ENTER}

## The type of effects that can play when a bit is missed.
enum MissEffectType {MOVE_OFFSCREEN, DISAPPEAR, FADE_OUT}

## Fades the bit away when it is clicked instead of disappearing instantly.
static var bit_fade_effect := true

## The effect that plays when a bit is missed.
## FADE_OUT does the same as DISAPPEAR unless bit_fade_effect is set to true.
static var miss_effect: MissEffectType = MissEffectType.FADE_OUT

## How quickly the bit fades away after being clicked (default is 5).
## Set to 0 to disable fade entirely.
static var clicked_fade_speed := 5

## The default bit damage when a bit is missed or incorrectly clicked.
const DEFAULT_DAMAGE = 1

## Where the bit starts.
var _starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()

## The value of the bit.
var _value: Bit.Type

## The x position of the cursor.
var _cursor_x: float

## The speed at which the bit travels across the screen.
var _speed: int

## How much damage missing this bit does.
var _damage: int

## Dictates when the bit should fade, if bit_fade_effect is set to true.
var _fade_bit = false

## If the bit has been missed (and also hasn't been deleted yet).
var _is_missed = false


## The width of a bit, in pixels.
## WARNING: NOT GOOD TO HARDCODE THIS, SHOULD BE CALCULATED SOMEHOW
static func get_width() -> int:
	return 28
	
	
func get_value() -> Bit.Type:
	return _value


## Set the bit's appearance.
func _ready() -> void:
	match _value:
		Bit.Type.ZERO:
			_sprite.hide()
			_label.text = "0"
		Bit.Type.ONE:
			_sprite.hide()
			_label.text = "1"
		Bit.Type.ENTER:
			_label.hide()


## Update bit position and effects, and check if it has been missed.
func _process(delta: float) -> void:
	if !_fade_bit or !bit_fade_effect:
		position.x -= _speed * delta
	elif bit_fade_effect:
		# Decrease alpha value (opacity).
		if modulate.a < 0:
			queue_free()
		else:
			modulate.a -= clicked_fade_speed * delta
	
	# Bit is missed.
	if !_is_missed and PerformanceCalculator.is_missed(get_accuracy()):
		Signals.missed.emit(_damage)
		_is_missed = true
		
		match miss_effect:
			MissEffectType.DISAPPEAR:
				queue_free()
			MissEffectType.FADE_OUT:
				kill()
	
	# Bit is offscreen.
	if position.x < -Bit.get_width():
		if !_is_missed:
			Signals.missed.emit(_damage)
		queue_free()


## Set bit data before appending it to a scene.
## Cursor_x position is used for accuracy calculations.
func create(value: Bit.Type, y_pos: float, cursor_x: float, speed: int, 
	damage: int = DEFAULT_DAMAGE) -> void:
	_value = value
	_cursor_x = cursor_x
	_speed = speed
	_damage = damage
	position = Vector2(_starting_x, y_pos)


## Try to click the bit, returning if the player did.
## If not, the bit keeps going and can try to be clicked again.
func click(value: Bit.Type) -> bool:
	var accuracy = get_accuracy()
	
	if PerformanceCalculator.is_clickable(accuracy):
		# Successfully clicked the bit.
		if get_value() == value:
			Signals.scored.emit(PerformanceCalculator.get_score(accuracy), 
					PerformanceCalculator.get_raw_score(accuracy))
		# Clicked the bit in time, but clicked the wrong key.
		else:
			# Enter key can only be clicked if you actually press enter, and
			# clicking enter does nothing to the other bits.
			if get_value() == Bit.Type.ENTER or value == Bit.Type.ENTER:
				return false 
			# Take damage and lose combo, as if you missed the bit.
			elif get_value() == Bit.Type.ZERO or get_value() == Bit.Type.ONE:
				Signals.missed.emit(_damage)
				_is_missed = true
		kill()
		return true
	else:
		return false


## Get rid of the bit (either right away, or let it fade away).
func kill() -> void:
	_timer.paused = true
	if bit_fade_effect:
		_fade_bit = true
	else:
		queue_free()


## Get the accuracy of clicking the bit right now, in milliseconds off the 
## perfect cursor click. A positive value is early by that many milliseconds, 
## and a negative value is late.
func get_accuracy() -> int:
	var time_to_click = _timer.wait_time - _timer.time_left
	var distance_to_cursor = _starting_x - _cursor_x # In pixels.
	var time_to_cursor = distance_to_cursor / _speed # In seconds.
	var error_milliseconds: int = round((time_to_cursor - time_to_click) * 1000)
	#print("calculated milliseconds off perfect click: %s" % error_milliseconds)
	return error_milliseconds
