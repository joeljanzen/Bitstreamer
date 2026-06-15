extends Node
## Holds game settings for the player. These persist throughout levels.

# UI options
## Toggles the level UI
var level_UI_enabled := true

# Aesthetic variables.
## The strength of bloom.
var bloom_strength := 1

## Toggles Flowerwall CRT shader. Use set_crt_effect() to change it, do not
## manually change this value!
var _crt_effect := true
## The CRT shader singleton.
var _crt_shader: flowerwallCRT

## The colour of zero bits. Default is "#00FF00"
var zero_bit_colour := "#00FF00"
## The colour of one bits. Default is "#DB236C"
var one_bit_colour := "#DB236C"
## The colour of enter bits. Default is "#FFFFFF"
var enter_bit_colour := "#FFFFFF"
## The colour of back bits. Default is "#FFFFFF"
var back_bit_colour := "#FFFFFF"

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
var perfect_click_colour := "C347FF"
## The colour associated with good clicks.
## Default is "2665D4"
var good_click_colour := "2665D4"
## The colour associated with okay clicks.
## Default is "E6BE20"
var okay_click_colour := "E6BE20"
## The colour associated with missed clicks.
## Default is "FFFFFF"
var missed_click_colour := "FFFFFF"
## The colour associated with incorrect clicks.
## Default is "C21515"
var incorrect_click_colour := "C21515"


## Sets the default values that are set with functions (these values are not stored
## here)
func _ready() -> void:
	set_bit_click_effect(true)
	set_effect_ignores_perfect_clicks(false)
	set_bit_fade_effect(false)
	set_bit_miss_effect(Bit.MissEffectType.MOVE_OFFSCREEN)


## Connect the Flowerwall CRT script when it is loaded.
func connect_crt_shader(crt_shader: flowerwallCRT) -> void:
	_crt_shader = crt_shader
	if !_crt_effect:
		_crt_shader.disable_shader()


## Set the CRT effect on or off.
func set_crt_effect(enabled: bool) -> void:
	if enabled and !_crt_shader.is_enabled:
		_crt_shader.enable_shader()
	elif _crt_shader.is_enabled:
		_crt_shader.disable_shader()


## Set the effect indicating the acccuracy of the bit click (or miss) on or off.
func set_bit_click_effect(enabled: bool) -> void:
	Bit.bit_click_effect = enabled


## Set ignoring perfect clicks with the bit click effect on or off.
func set_effect_ignores_perfect_clicks(enabled: bool) -> void:
	BitClickEffect.ignores_perfect_clicks = enabled


## Set the effect that fades the bit away on or off.
func set_bit_fade_effect(enabled: bool) -> void:
	Bit.bit_fade_effect = enabled


## Set the effect that plays when a bit is missed on or off.
## FADE_OUT does the same as DISAPPEAR unless the bit fade effect is enabled.
func set_bit_miss_effect(effect: Bit.MissEffectType) -> void:
	Bit.miss_effect = effect
