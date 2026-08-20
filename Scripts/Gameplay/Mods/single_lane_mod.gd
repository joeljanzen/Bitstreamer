class_name SingleLaneMod
extends Node
## Mod that turns all enter and back bits into regular bits, so you never switch
## lanes.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.SINGLE_LANE


## Replaces all enter and back bits with the opposite of the bit that came 
## before them.
func mod_bits(base_bit: Bit.Type, last_bit: Bit.Type) -> Bit.Type:
	match base_bit:
		Bit.Type.ENTER, Bit.Type.BACK:
			if last_bit == Bit.Type.ZERO:
				return Bit.Type.ONE
			else:
				return Bit.Type.ZERO
		_:
			return base_bit


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.25
