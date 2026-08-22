class_name OverclockedMod
extends Node
## Mod that makes the level harder (in most cases).

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.OVERCLOCKED


func mod_difficulty(base_difficulty: float) -> float:
	var new_difficulty = base_difficulty + 2
	return min(new_difficulty, LevelInfo.DIFFICULTY_MAX)


func mod_speed(base_speed: float) -> float:
	var effective_speed = PerformanceCalculator.get_effective_speed(base_speed)
	# If the effective speed is already at or above the maximum speed, we
	# do nothing.
	if effective_speed >= LevelInfo.SPEED_MAX:
		return base_speed
	else:
		# We want to change the effective speed value by 2, not the actual
		# speed, and ensure effective speed doesn't go above speed 12.
		var new_speed = min(effective_speed + 2, LevelInfo.SPEED_MAX)
		# convert our new effective speed into actual speed then return it.
		return PerformanceCalculator.get_speed_from_effective_speed(new_speed)


func mod_damage(base_damage: int) -> int:
	var new_damage = base_damage * 1.5
	return min(new_damage, LevelInfo.DAMAGE_MAX)


## Swap zeroes and ones to make the level feel different from the original.
func mod_bits(base_bit: Bit.Type, _last_bit: Bit.Type) -> Bit.Type:
	match base_bit:
		Bit.Type.ONE:
			return Bit.Type.ZERO
		Bit.Type.ZERO:
			return Bit.Type.ONE
		_:
			return base_bit


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 1.25


## A mod simply having this method will enable the damage.
func enable_enters_and_backs_damage() -> void:
	pass
