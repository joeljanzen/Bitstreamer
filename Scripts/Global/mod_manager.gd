extends Node
## Manages active mods and has methods to apply them to the level.

const STABLE_ICON_PATH: String = "res://Resources/Sprites/Mods/stable_mod.png"
const UNSTABLE_ICON_PATH: String = "res://Resources/Sprites/Mods/unstable_mod.png"
const OVERCLOCKED_ICON_PATH: String = "res://Resources/Sprites/Mods/overclocked_mod.png"
const UNDERCLOCKED_ICON_PATH: String = "res://Resources/Sprites/Mods/underclocked_mod.png"
const ZEROED_OUT_ICON_PATH: String = "res://Resources/Sprites/Mods/zeroed_out_mod.png"
const SINGLE_LANE_ICON_PATH: String = "res://Resources/Sprites/Mods/single_lane_mod.png"
const DOUBLE_TIME_ICON_PATH: String = "res://Resources/Sprites/Mods/double_time_mod.png"
const HALF_TIME_ICON_PATH: String = "res://Resources/Sprites/Mods/half_time_mod.png"

## The types of mods that can be applied to a level.
enum ModType {
	STABLE,
	UNSTABLE,
	OVERCLOCKED,
	UNDERCLOCKED,
	ZEROED_OUT,
	SINGLE_LANE,
	DOUBLE_TIME,
	HALF_TIME,
}

## An array of all mod buttons. Used to disable mods that are incompatible with
## others after calling toggle_mod_active. Also sets buttons as pressed when
## reloading the level select scene, if mods were previously set to active.
var mod_buttons: Array[ModButton]

## An array of all active mods. There is no base Mod type since interfaces are
## not a thing in Godot, we just use duck typing to check if mods have 
## particular methods and then make use of those.
var _active_mods: Array = []


## Returns true if there are any active mods.
func has_active_mods() -> bool:
	return !_active_mods.is_empty()


## Get the list of active mods.
func get_mod_list() -> Array[ModType]:
	var mods: Array[ModType] = []
	
	for mod in _active_mods:
		mods.push_back(mod.type)
	
	return mods


## Get the associated icon for a mod.
func get_icon(mod: ModType) -> Texture2D:
	match mod:
		ModManager.ModType.STABLE:
			return load(STABLE_ICON_PATH)
		ModManager.ModType.UNSTABLE:
			return load(UNSTABLE_ICON_PATH)
		ModManager.ModType.OVERCLOCKED:
			return load(OVERCLOCKED_ICON_PATH)
		ModManager.ModType.UNDERCLOCKED:
			return load(UNDERCLOCKED_ICON_PATH)
		ModManager.ModType.ZEROED_OUT:
			return load(ZEROED_OUT_ICON_PATH)
		ModManager.ModType.SINGLE_LANE:
			return load(SINGLE_LANE_ICON_PATH)
		ModManager.ModType.DOUBLE_TIME:
			return load(DOUBLE_TIME_ICON_PATH)
		ModManager.ModType.HALF_TIME:
			return load(HALF_TIME_ICON_PATH)
		_:
			return load("res://icon.svg")


## Return the icons for all currently active mods.
func get_active_mod_icons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []
	for mod in _active_mods:
		icons.push_back(get_icon(mod.type))
	
	return icons


## Ensures all mods are sorted so that they are applied in the correct 
## order. Call this before applying mods to anything!
func fix_mod_order() -> void:
	# Bit mods should be applied in the order of:
	# overclocked -> single-lane -> zeroed out.
	# Underclocked must be applied before unstable otherwise unstable's 100 
	# damage will be reduced to 75 by underclocked.
	var bit_mods = []
	var unstable_mod = null
	var all_mods = []
	
	for mod in _active_mods:
		if mod.has_method("mod_bits"):
			# It's first in bit mod order so you can push it with the other mods.
			if mod.type == ModType.OVERCLOCKED:
				all_mods.push_back(mod)
			else:
				bit_mods.push_back(mod)
		elif mod.type == ModType.UNSTABLE:
			unstable_mod = mod
		else:
			all_mods.push_back(mod)
	
	# If unstable mod exists, push it to the array now. If underclocked is also
	# active it will have already been added in the for loop above.
	if unstable_mod != null:
		all_mods.push_back(unstable_mod)
	
	# If there are one or more bit mods left to order, continue.
	var remaining_bit_mods = bit_mods.size()
	if remaining_bit_mods == 1:
			all_mods.push_back(bit_mods.front())
	elif remaining_bit_mods > 1:
		# Only one case left where we have to ensure zeroed out is after
		# single-lane.
		if bit_mods.front().type == ModType.ZEROED_OUT:
			all_mods.push_back(bit_mods.back())
			all_mods.push_back(bit_mods.front())
		else:
			all_mods.push_back(bit_mods.front())
			all_mods.push_back(bit_mods.back())
	
	_active_mods = all_mods


## Prints out all active mods in their order of application to the level.
## Only for debugging purposes.
func _print_mods() -> void:
	for mod in _active_mods:
		print(ModType.keys()[mod.type] + ", ")


## When loading the level select scene, set all mod buttons to their correct
## states (as some mods may be active currently).
func set_mod_button_states() -> void:
	if has_active_mods():
		for mod in _active_mods:
			_set_button_pressed(mod.type)
			_toggle_incompatible_mods(mod.type)


## If the mod given is inactive, activate it. Otherwise, deactivate it.
func toggle_mod_active(mod: ModType) -> void:
	# Search for the mod to remove it.
	var mod_was_active = false
	for i in range(_active_mods.size()):
		if _active_mods[i].type == mod:
			_active_mods.remove_at(i)
			mod_was_active = true
			break
	
	# If the mod was not already in the array, add it.
	# This also disables any mods that are incompatible with the new one.
	if !mod_was_active:
		match mod:
			ModManager.ModType.STABLE:
				_active_mods.push_back(StableMod.new())
			ModManager.ModType.UNSTABLE:
				_active_mods.push_back(UnstableMod.new())
			ModManager.ModType.OVERCLOCKED:
				_active_mods.push_back(OverclockedMod.new())
			ModManager.ModType.UNDERCLOCKED:
				_active_mods.push_back(UnderclockedMod.new())
			ModManager.ModType.ZEROED_OUT:
				_active_mods.push_back(ZeroedOutMod.new())
			ModManager.ModType.SINGLE_LANE:
				_active_mods.push_back(SingleLaneMod.new())
			ModManager.ModType.DOUBLE_TIME:
				_active_mods.push_back(DoubleTimeMod.new())
			ModManager.ModType.HALF_TIME:
				_active_mods.push_back(HalfTimeMod.new())
	
	_toggle_incompatible_mods(mod)


## Remove all currently active mods.
func clear_all_mods() -> void:
	_active_mods = []
	for button in mod_buttons:
		if button.is_disabled():
			button.toggle_disabled()
		button.set_pressed(false)


## Toggle the disabled state of mod buttons incompatible with the mod given.
func _toggle_incompatible_mods(mod: ModType) -> void:
	match mod:
		ModManager.ModType.STABLE:
			_toggle_button_disabled(ModType.UNSTABLE)
		ModManager.ModType.UNSTABLE:
			_toggle_button_disabled(ModType.STABLE)
		ModManager.ModType.OVERCLOCKED:
			_toggle_button_disabled(ModType.UNDERCLOCKED)
		ModManager.ModType.UNDERCLOCKED:
			_toggle_button_disabled(ModType.OVERCLOCKED)
		ModManager.ModType.DOUBLE_TIME:
			_toggle_button_disabled(ModType.HALF_TIME)
		ModManager.ModType.HALF_TIME:
			_toggle_button_disabled(ModType.DOUBLE_TIME)


func _toggle_button_disabled(button_type: ModType) -> void:
	for button in mod_buttons:
		if button.mod == button_type:
			button.toggle_disabled()


func _set_button_pressed(button_type: ModType) -> void:
	for button in mod_buttons:
		if button.mod == button_type:
			button.set_pressed(true)


## Apply all active mods with difficulty adjustment to a base difficulty, 
## returning the modified difficulty.
func apply_difficulty_mods(base_difficulty: float) -> float:
	var final_difficulty = base_difficulty
	for mod in _active_mods:
		if mod.has_method("mod_difficulty"):
			final_difficulty = mod.mod_difficulty(final_difficulty)
	return final_difficulty


## Apply all active mods with speed adjustment to a base speed, 
## returning the modified speed.
func apply_speed_mods(base_speed: float) -> float:
	var final_speed = base_speed
	for mod in _active_mods:
		if mod.has_method("mod_speed"):
			final_speed = mod.mod_speed(final_speed)
	return final_speed


## Apply all active mods with damage adjustment to a base damage, 
## returning the modified damage.
func apply_damage_mods(base_damage: int) -> int:
	var final_damage = base_damage
	for mod in _active_mods:
		if mod.has_method("mod_damage"):
			final_damage = mod.mod_damage(final_damage)
	return final_damage


## Apply all active mods with bit type adjustment to a base bit, 
## returning the modified bit type. Some mods may also make use of the bit
## that was sent before this bit.
func apply_bit_mods(base_bit: Bit.Type, last_bit: Bit.Type) -> Bit.Type:
	var final_bit = base_bit
	for mod in _active_mods:
		if mod.has_method("mod_bits"):
			final_bit = mod.mod_bits(final_bit, last_bit)
	return final_bit


## Returns the speed factor to play the level at. For instance, a value of 2
## would mean the level should be played at 2x speed.
func get_playback_speed_factor() -> float:
	var final_playback_speed = 1
	for mod in _active_mods:
		if mod.has_method("mod_playback_speed"):
			final_playback_speed = mod.mod_playback_speed(final_playback_speed)
	return final_playback_speed


## Returns the value to multiply the player's score by, based on the active 
## mods. Some mods increase score, while others decrease it.
func get_score_multiplier() -> float:
	var final_score_multiplier = 1
	for mod in _active_mods:
		final_score_multiplier = mod.mod_score_multiplier(final_score_multiplier)
	return final_score_multiplier
