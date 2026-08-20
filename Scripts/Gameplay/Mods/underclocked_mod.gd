class_name UnderclockedMod
extends Node
## Mod that makes the level easier (in most cases).

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.UNDERCLOCKED


func mod_difficulty(base_difficulty: float) -> float:
	var new_difficulty = base_difficulty - 2
	return max(new_difficulty, LevelInfo.DIFFICULTY_MIN)


func mod_speed(base_speed: float) -> float:
	if base_speed >= LevelInfo.SPEED_MIN:
		var new_speed = base_speed - 2
		return max(new_speed, LevelInfo.SPEED_MIN)
	else:
	# If the half time mod decreased the speed below the minimum value, we 
	# simply do not change the speed value at all. We CANNOT increase it to the
	# minimum speed, and certainly shouldn't lower it even more.
		return base_speed


func mod_damage(base_damage: int) -> int:
	var new_damage = base_damage * 0.75
	return max(new_damage, LevelInfo.DAMAGE_MIN)


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.75
