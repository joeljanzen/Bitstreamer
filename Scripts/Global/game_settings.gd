extends Node
## Holds game settings for the player. These persist throughout levels.

# Gameplay options
## Displays an effect indicating the acccuracy of the bit click (or miss).
## If disabled, bits just fade away when clicked.
var bit_click_effect := true

## Ignores the bit click effect for perfect clicks, regardless of the bit click 
## effect being enabled.
var ignores_perfect_clicks = false

## When true if a bit is missed it moves off screen. Otherwise it disappears.
var move_offscreen_on_bit_miss := true

## How quickly the bit fades away after being clicked (in seconds).
## Setting to 0 disables fade entirely.
## Make sure to disable the bit click effect for all bits to fade instead of 
## disappear. This affects perfect clicks regardless of the effect being 
## enabled if perfect clicks are set to be ignored.
var clicked_fade_time: float = 0.15

## The cursor flickers like a real cursor. Set false to disable flickering.
var cursor_flicker := true

# UI options
## Toggles the level UI
var level_UI_enabled := true

# Aesthetic variables.
## The strength of bloom.
var bloom_strength: float = 0.5

## Toggles Flowerwall CRT shader. Use set_crt_effect() to change it, do not
## manually change this value!
var crt_filter := true
## The CRT shader singleton.
var _crt_shader: flowerwallCRT

## The colour of zero bits.
var zero_bit_colour := Color("#00FF00")
## The colour of one bits.
var one_bit_colour := Color("#FF0066")
## The colour of enter bits.
var enter_bit_colour := Color("#FFFFFF")
## The colour of back bits.
var back_bit_colour := Color("#FFFFFF")

## The colour displayed for correctly entered bits on the terminal.
var entered_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
var missed_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
var incorrect_bit_colour := "#330000"

## The colour associated with perfect clicks.
var perfect_click_colour := "FF66FF"
## The colour associated with good clicks.
var good_click_colour := "3399FF"
## The colour associated with okay clicks.
var okay_click_colour := "FFCC00"
## The colour associated with missed clicks.
var missed_click_colour := "FFFFFF"
## The colour associated with incorrect clicks.
var incorrect_click_colour := "FF0000"


## Connect the Flowerwall CRT script when it is loaded.
func connect_crt_shader(crt_shader: flowerwallCRT) -> void:
	_crt_shader = crt_shader
	if !crt_filter:
		_crt_shader.disable_shader()


## Set the CRT filter on or off.
func set_crt_filter(enabled: bool) -> void:
	crt_filter = enabled
	if enabled and !_crt_shader.is_enabled:
		_crt_shader.enable_shader()
	elif _crt_shader.is_enabled:
		_crt_shader.disable_shader()


## Returns an array of all theme colors used in UI, in order of primary, 
## secondary, and so on.
func get_theme_colors() -> Array[Color]:
	return [zero_bit_colour, one_bit_colour, enter_bit_colour]
