extends Node
## Manages active mods and has methods to apply them to the level.

const STABLE_ICON_PATH: String = "res://Resources/Sprites/Mods/stable_mod.png"
const UNSTABLE_ICON_PATH: String = "res://Resources/Sprites/Mods/unstable_mod.png"
const OVERCLOCKED_ICON_PATH: String = "res://Resources/Sprites/Mods/overclocked_mod.png"
const UNDERCLOCKED_ICON_PATH: String = "res://Resources/Sprites/Mods/underclocked_mod.png"

## The types of mods that can be applied to a level.
enum ModType {
	STABLE,
	UNSTABLE,
	OVERCLOCKED,
	UNDERCLOCKED,
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
		_:
			return load("res://icon.svg")


## Return the icons for all currently active mods.
func get_active_mod_icons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []
	for mod in _active_mods:
		icons.push_back(get_icon(mod.type))
	
	return icons


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
	
	_toggle_incompatible_mods(mod)


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


func _toggle_button_disabled(button_type: ModType) -> void:
	for button in mod_buttons:
		if button.mod == button_type:
			button.toggle_disabled()


func _set_button_pressed(button_type: ModType) -> void:
	for button in mod_buttons:
		if button.mod == button_type:
			button.set_pressed()


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
