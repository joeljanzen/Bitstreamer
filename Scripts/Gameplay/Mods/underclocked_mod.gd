class_name UnderclockedMod
extends Node
## Mod that makes the level easier (in most cases).

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.UNDERCLOCKED


func mod_difficulty(base_difficulty: float) -> float:
	var new_difficulty = base_difficulty - 2
	return max(new_difficulty, LevelInfo.DIFFICULTY_MIN)


func mod_speed(base_speed: float) -> float:
	var effective_speed = PerformanceCalculator.get_effective_speed(base_speed)
	# If the effective speed is already at or below the minimum speed, we
	# do nothing.
	if effective_speed <= LevelInfo.SPEED_MIN:
		return base_speed
	else:
		# We want to change the effective speed value by 2, not the actual
		# speed, and ensure effective speed doesn't go below speed 1.
		var new_speed = max(effective_speed - 2, LevelInfo.SPEED_MIN)
		# convert our new effective speed into actual speed then return it.
		return PerformanceCalculator.get_speed_from_effective_speed(new_speed)


func mod_damage(base_damage: int) -> int:
	var new_damage = base_damage * 0.75
	return max(new_damage, LevelInfo.DAMAGE_MIN)


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.75
