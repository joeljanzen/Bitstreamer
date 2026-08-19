class_name Bit
extends Node2D
## A bit to send to the player to click.

@onready var _bit_label: Label = $BitLabel
@onready var _bit_sprite: Sprite2D = $BitSprite
@onready var _bit_click_effect = preload("res://Scenes/bit_click_effect.tscn")
## Used to swap from the enter texture which is on by default.
@onready var _back_texture = preload("res://Resources/Sprites/Cursor/cursor_up.png")

## Signifies a bit flying across the background has been clicked while in the 
## main menu.
signal bit_clicked_in_menu(correct_click: bool)

## The types of bits.
enum Type {
	ZERO, 
	ONE, 
	ENTER,
	BACK,
}

## Where the bit starts.
static var starting_x = ProjectSettings.get_setting("display/window/size/viewport_width") + Bit.get_width()

## Slightly changes bit behaviour when in the main menu (disable bit effects
## and don't do as much in physics process)
static var in_main_menu := false

## Determines if you're actually at the part in the main menu where the bits can
## be clicked (AKA, you're not in the level select, or settings, or whatever 
## else).
static var clickable_in_main_menu := false

## The value of the bit.
var _value: Bit.Type

## The x position of the cursor.
var _cursor_x: float

## The time it takes the bit to reach the cursor after being sent.
var _time_to_cursor: float

## The point in the song considered the perfect time to click this bit.
var _time_of_perfect_click: float

## The conductor playing the music, used to determine bit click accuracy.
var _conductor: Conductor

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

## True if the mouse is within the bit's area2D currently.
var _mouse_hovered_in_menu = false

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
	# Note that we need to stop polling for this if the bit is fading, as
	# it has been clicked already and cannot be missed afterwards.
	if (!in_main_menu and !_is_missed and !_is_clicked
			and PerformanceCalculator.is_missed(get_accuracy())):
			Signals.missed.emit(_damage, PerformanceCalculator.ClickQuality.MISS)
			
			_is_missed = true
			_score_animation(PerformanceCalculator.ClickQuality.MISS)
			
			if !GameSettings.move_offscreen_on_bit_miss:
				kill(false)
	
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
func create(value: Bit.Type, cursor_y: float, cursor_x: float, 
		time_to_cursor: float, damage: int, conductor: Conductor) -> void:
	_value = value
	_cursor_x = cursor_x
	_time_to_cursor = time_to_cursor
	var distance_to_cursor = starting_x - cursor_x # In pixels.
	_speed = distance_to_cursor / time_to_cursor
	if !in_main_menu:
		@warning_ignore("narrowing_conversion")
		_speed *= ModManager.get_playback_speed_factor()
	
	_damage = damage
	_conductor = conductor
	
	_time_of_perfect_click = conductor.get_time() + time_to_cursor
	
	global_position = Vector2(starting_x, cursor_y)
	set_bit_visuals(value)


## Set how the bit will appear on screen, based on its type.
func set_bit_visuals(type: Type) -> void:
	match type:
		Bit.Type.ZERO:
			set("modulate", GameSettings.zero_bit_colour)
			_bit_sprite.hide()
			_bit_label.text = "0"
		Bit.Type.ONE:
			set("modulate", GameSettings.one_bit_colour)
			_bit_sprite.hide()
			_bit_label.text = "1"
		Bit.Type.ENTER:
			set("modulate", GameSettings.enter_bit_colour)
			_bit_label.hide()
		Bit.Type.BACK:
			set("modulate", GameSettings.back_bit_colour)
			_bit_label.hide()
			_bit_sprite.texture = _back_texture


## Try to click the bit, returning if the player did.
## If not, the bit keeps going and can try to be clicked again.
func click(value: Bit.Type) -> bool:
	var accuracy = get_accuracy()
	#print("Click accuracy: %.2f ms for bit of type %d" % [accuracy, _value])
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
	if !GameSettings.bit_click_effect or (GameSettings.ignores_perfect_clicks and is_perfect_click):
		_fade_bit = true
	else:
		queue_free()


## Get the accuracy of clicking the bit right now, in milliseconds off the 
## perfect cursor click. A positive value is early by that many milliseconds, 
## and a negative value is late.
func get_accuracy() -> int:
	var time_of_click = _conductor.get_time()
	return round((_time_of_perfect_click - time_of_click) * 1000) / ModManager.get_playback_speed_factor()


## Play animations for a correct click.
func _score_animation(click_quality: PerformanceCalculator.ClickQuality) -> void:
	if GameSettings.bit_click_effect and !in_main_menu:
		_add_score_effect_child(click_quality)


## Makes the score animation actually happen, given conditions are met when
## _score_animation is called.
func _add_score_effect_child(click_quality: PerformanceCalculator.ClickQuality):
	var effect: BitClickEffect = _bit_click_effect.instantiate()
	get_tree().root.call_deferred("add_child", effect)
	var pos: Vector2 = global_position
	@warning_ignore("integer_division")
	var pos_offset: int = BitClickEffect.get_width() / 2
	# bit is somewhat offscreen or entirely offscreen
	if global_position.x < pos_offset:
		pos = Vector2(pos_offset, global_position.y)
	effect.call_deferred("create", pos, click_quality)


## Allow destroying bits in the main menu.
func _on_bit_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (clickable_in_main_menu and event is InputEventMouseButton and event.is_pressed() 
			and event.button_index == MOUSE_BUTTON_LEFT):
		_click_bit_in_menu(PerformanceCalculator.ClickQuality.PERFECT)


func _on_mouse_entered() -> void:
	if clickable_in_main_menu:
		_mouse_hovered_in_menu = true


func _on_mouse_exited() -> void:
	if clickable_in_main_menu:
		_mouse_hovered_in_menu = false


func _unhandled_key_input(event: InputEvent) -> void:
	if _mouse_hovered_in_menu:
		if event.is_action_pressed("0_bit"):
			if _value == Type.ZERO:
				_click_bit_in_menu(PerformanceCalculator.ClickQuality.PERFECT)
			elif _value == Type.ONE:
				_click_bit_in_menu(PerformanceCalculator.ClickQuality.ERROR)
		elif event.is_action_pressed("1_bit"):
			if _value == Type.ONE:
				_click_bit_in_menu(PerformanceCalculator.ClickQuality.PERFECT)
			elif _value == Type.ZERO:
				_click_bit_in_menu(PerformanceCalculator.ClickQuality.ERROR)
		elif event.is_action_pressed("enter_bit") and _value == Type.ENTER:
			_click_bit_in_menu(PerformanceCalculator.ClickQuality.PERFECT)


## The bit was clicked while in the main menu.
func _click_bit_in_menu(click_quality: PerformanceCalculator.ClickQuality) -> void:
	if click_quality == PerformanceCalculator.ClickQuality.PERFECT:
		bit_clicked_in_menu.emit(true)
	else:
		bit_clicked_in_menu.emit(false)
	
	if GameSettings.bit_click_effect:
		_add_score_effect_child(click_quality)
		queue_free()
	else:
		kill(false)
