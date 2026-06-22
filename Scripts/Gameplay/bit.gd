class_name Bit
extends Node2D
## A bit to send to the player to click.

@onready var _bit_label: Label = $BitLabel
@onready var _bit_sprite: Sprite2D = $BitSprite
@onready var _timer: Timer = $Timer
@onready var _bit_click_effect = preload("res://Scenes/bit_click_effect.tscn")
## Used to swap from the enter texture which is on by default.
@onready var _back_texture = preload("res://Resources/Sprites/Cursor/cursor_up.png")

## The types of bits.
enum Type {
	ZERO, 
	ONE, 
	ENTER,
	BACK,
}

## Where the bit starts.
static var starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()

## The value of the bit.
var _value: Bit.Type

## The x position of the cursor.
var _cursor_x: float

## The time it takes the bit to reach the cursor after being sent.
var _time_to_cursor: float

## The speed at which the bit travels across the screen, in pixels per second.
var _speed: int

## How much damage missing this bit does.
var _damage: int

## Dictates when the bit should fade (this is only a thing when game settings
## have disabled the bit click effect).
var _fade_bit = false

## If the bit has been clicked (and also hasn't been deleted yet).
var _is_clicked = false

## If the bit has been missed (and also hasn't been deleted yet).
var _is_missed = false


## The width of a bit, in pixels.
## WARNING: NOT GOOD TO HARDCODE THIS, SHOULD BE CALCULATED SOMEHOW
static func get_width() -> int:
	return 28


func get_value() -> Bit.Type:
	return _value


## Update bit position and effects, and check if it has been missed.
func _physics_process(delta: float) -> void:
	if !_fade_bit:
		position.x -= _speed * delta
	else:
		# Decrease alpha value (opacity).
		if modulate.a < 0:
			queue_free()
		else:
			var fade_time := GameSettings.clicked_fade_time
			if fade_time == 0:
				process_mode = Node.PROCESS_MODE_DISABLED
			else:
				modulate.a -= delta / fade_time
	
	# Bit is missed.
	if !_is_missed and PerformanceCalculator.is_missed(get_accuracy()):
		Signals.missed.emit(_damage, PerformanceCalculator.ClickQuality.MISS)
		_is_missed = true
		_score_animation(PerformanceCalculator.ClickQuality.MISS)
		
		if !GameSettings.move_offscreen_on_bit_miss:
			if !GameSettings.bit_click_effect:
				# This triggers a fade out instead of instant deletion, since we
				# want a fade when the bit click effect is not active.
				kill(false)
			else:
				# Since the bit click effect is active, we want the bit gone
				# right away so the "miss" text can display with no obstructions.
				queue_free()
	
	# Bit is offscreen.
	if global_position.x < -Bit.get_width():
		# _is_clicked prevents the rare case where the bit is clicked AND it goes
		# offscreen, making sure it doesn't emit the missed signal right after 
		# the scored signal.
		if !_is_missed and !_is_clicked: 
			Signals.missed.emit(_damage, PerformanceCalculator.ClickQuality.MISS)
			_score_animation(PerformanceCalculator.ClickQuality.MISS)
		queue_free()


## Set bit data AFTER appending it to a scene as a child.
## Send global x and y positions.
func create(value: Bit.Type, cursor_y: float, cursor_x: float, time_to_cursor: float, 
	damage: int) -> void:
	_value = value
	_cursor_x = cursor_x
	_time_to_cursor = time_to_cursor
	var distance_to_cursor = starting_x - cursor_x # In pixels.
	_speed = distance_to_cursor / time_to_cursor
	_damage = damage
	global_position = Vector2(starting_x, cursor_y)
	
	set_bit_visuals(value)


## Set how the bit will appear on screen, based on its type.
func set_bit_visuals(type: Type) -> void:
	match type:
		Bit.Type.ZERO:
			set("modulate", Color(GameSettings.zero_bit_colour))
			_bit_sprite.hide()
			_bit_label.text = "0"
		Bit.Type.ONE:
			set("modulate", Color(GameSettings.one_bit_colour))
			_bit_sprite.hide()
			_bit_label.text = "1"
		Bit.Type.ENTER:
			set("modulate", Color(GameSettings.enter_bit_colour))
			_bit_label.hide()
		Bit.Type.BACK:
			set("modulate", Color(GameSettings.back_bit_colour))
			_bit_label.hide()
			_bit_sprite.texture = _back_texture


## Try to click the bit, returning if the player did.
## If not, the bit keeps going and can try to be clicked again.
func click(value: Bit.Type) -> bool:
	var accuracy = get_accuracy()
	#print("Click accuracy: %.2f ms" % accuracy)
	var is_perfect_click = false
	
	if PerformanceCalculator.is_clickable(accuracy):
		# Successfully clicked the bit.
		if get_value() == value:
			_is_clicked = true
			var raw_score = PerformanceCalculator.get_raw_score(accuracy)
			Signals.scored.emit(PerformanceCalculator.get_score(accuracy), raw_score)
			var click_quality: PerformanceCalculator.ClickQuality = PerformanceCalculator.get_click_quality(raw_score)
			_score_animation(click_quality)
			
			if click_quality == PerformanceCalculator.ClickQuality.PERFECT:
				is_perfect_click = true
			
		# Clicked the bit in time, but clicked the wrong key.
		else:
			# Enter bit can only be clicked if you actually press enter, and
			# clicking enter does nothing to the other bits.
			if get_value() == Bit.Type.ENTER or value == Bit.Type.ENTER:
				return false
			# Back bit behaves the same as the enter key.
			if get_value() == Bit.Type.BACK or value == Bit.Type.BACK:
				return false
			# Take damage and lose combo, as if you missed the bit.
			elif get_value() == Bit.Type.ZERO or get_value() == Bit.Type.ONE:
				_is_clicked = true
				Signals.missed.emit(_damage, PerformanceCalculator.ClickQuality.ERROR)
				_score_animation(PerformanceCalculator.ClickQuality.ERROR)
				_is_missed = true
		kill(is_perfect_click)
		return true
	else:
		return false


## Get rid of the bit (either right away, or let it fade away).
## Pass if the bit was a perfect click, in the event that we need to fade the
## bit away instead of queue_free it when the bit click effect is being 
## ignored for perfect clicks (this is a game setting).
func kill(is_perfect_click: bool) -> void:
	_timer.paused = true
	if !GameSettings.bit_click_effect or (GameSettings.ignores_perfect_clicks and is_perfect_click):
		_fade_bit = true
	else:
		queue_free()


## Get the accuracy of clicking the bit right now, in milliseconds off the 
## perfect cursor click. A positive value is early by that many milliseconds, 
## and a negative value is late.
func get_accuracy() -> int:
	var time_to_click = _timer.wait_time - _timer.time_left
	return round((_time_to_cursor - time_to_click) * 1000)


## Play animations for a correct click.
func _score_animation(click_quality: PerformanceCalculator.ClickQuality) -> void:
	if GameSettings.bit_click_effect:
		var effect: BitClickEffect = _bit_click_effect.instantiate()
		get_tree().root.call_deferred("add_child", effect)
		var pos: Vector2 = global_position
		@warning_ignore("integer_division")
		var pos_offset: int = BitClickEffect.get_width() / 2
		# bit is somewhat offscreen or entirely offscreen
		if global_position.x < pos_offset:
			pos = Vector2(pos_offset, global_position.y)
		effect.call_deferred("create", pos, click_quality)
