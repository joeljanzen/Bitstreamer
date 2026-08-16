class_name UnstableMod
extends Node
## Mod that makes failing immediate after a single error or miss.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.UNSTABLE

func mod_damage(_base_damage: int) -> int:
	return 100
