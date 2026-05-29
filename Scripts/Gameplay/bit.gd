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
## how quickly the bit fades away after being clicked.
## set to 0 to disable fade entirely
const CLICKED_FADE_SPEED = 5
## default bit damage if missed
const DEFAULT_DAMAGE = 1

## where the bit starts
var _starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()
## the value of the bit (false is 0, true is 1)
var _value: BitType.Type
## the speed at which the bit travels across the screen
var _speed
## how much damage missing this bit does
var _damage
## if bit_fade_effect is true, this bool triggers that when true
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
		if modulate.a < 0:
			queue_free()
		else:
			modulate.a -= CLICKED_FADE_SPEED * delta
	
	# bit is offscreen
	if position.x < -Bit.get_width():
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


## try to click the bit, returning if the player did.
## if not, the bit keeps going and can try to be clicked again
func click(cursor_x: float, value: BitType.Type) -> bool:
	var accuracy = get_accuracy(cursor_x)
	
	if PerformanceCalculator.is_clickable(accuracy):
		# successfully clicked
		if get_value() == value:
			Signals.score.emit(PerformanceCalculator.get_score(accuracy))
		# clicked in time, but clicked the wrong key
		else:
			# enter key can only be clicked if you actually press enter, and
			# clicking enter does nothing to the other bits
			if get_value() == BitType.Type.ENTER || value == BitType.Type.ENTER:
				return false 
			# score decreases, take extra damage, and lose combo
			elif get_value() == BitType.Type.ZERO || get_value() == BitType.Type.ONE:
				Signals.score.emit(PerformanceCalculator.get_score_on_incorrect())
				Signals.damage.emit(PerformanceCalculator.get_damage_on_incorrect(_damage))
				Signals.combo_break.emit()
		
		kill()
		return true
	else:
		return false


## the game clicked the bit for you! (combo breaks and you don't get score)
func auto_click() -> void:
	Signals.combo_break.emit()
	kill()


## get rid of the bit (either right away, or let it fade away)
func kill() -> void:
	if bit_fade_effect:
		_clicked_bit = true
	else:
		queue_free()


## returns if the bit has been missed (it has passed the clickable window)
func missed(cursor_x: float) -> bool:
	return PerformanceCalculator.is_missed(get_accuracy(cursor_x))


## get the accuracy of clicking the bit right now, in milliseconds off the perfect cursor click.
## a positive value is early by that many milliseconds, and a negative value is late
func get_accuracy(cursor_x: float) -> int:
	var time_to_click = timer.wait_time - timer.time_left
	#print("time to current: %s" % time_to_click)
	
	var distance_to_cursor = _starting_x - cursor_x # in pixels
	var time_to_cursor = distance_to_cursor / _speed # speed is in pixels per second, so we get seconds back
	var error_milliseconds: int = round((time_to_cursor - time_to_click) * 1000)
	#print("calculated time to cursor (seconds): %s" % time_to_cursor)
	#print("calculated milliseconds off perfect click: %s" % error_milliseconds)
	return error_milliseconds


## get the value of the bit (false is 0, true is 1)
func get_value() -> BitType.Type:
	return _value


## NOT GOOD TO HARDCODE THESE IDK WHAT TO DO
static func get_width() -> int:
	return 28
