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
var bloom_strength: float = 1.0

## Toggles Flowerwall CRT shader. Use set_crt_effect() to change it, do not
## manually change this value!
var crt_filter := true
## The CRT shader singleton.
var _crt_shader: flowerwallCRT

## The colour of zero bits. Default is "#00FF00"
var zero_bit_colour := Color("00FF00")
## The colour of one bits. Default is "#DB236C"
var one_bit_colour := Color("#DB236C")
## The colour of enter bits. Default is "#FFFFFF"
var enter_bit_colour := Color("#FFFFFF")
## The colour of back bits. Default is "#FFFFFF"
var back_bit_colour := Color("#FFFFFF")

## The colour displayed for correctly entered bits on the terminal.
## Default is "#454545"
var entered_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
## Default is "#454545"
var missed_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
## Default is "#2E0606"
var incorrect_bit_colour := "#2E0606"

## The colour associated with perfect clicks.
## Default is "C347FF"
var perfect_click_colour := "FF66FF"
## The colour associated with good clicks.
## Default is "0066FF"
var good_click_colour := "0066FF"
## The colour associated with okay clicks.
## Default is "FFCC00"
var okay_click_colour := "FFCC00"
## The colour associated with missed clicks.
## Default is "FFFFFF"
var missed_click_colour := "FFFFFF"
## The colour associated with incorrect clicks.
## Default is "FF0000"
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
