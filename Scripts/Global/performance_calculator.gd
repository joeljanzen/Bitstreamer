extends Node

# the score given for a certain accuracy of click
const PERFECT_CLICK_SCORE = 300
const GOOD_CLICK_SCORE = 100
const BAD_CLICK_SCORE = 50
# the accuracy ranges needed to achieve each click score
## how many milliseconds + or - a perfect click gives you a perfect score
var perfect_click_range = 30
## how many milliseconds + or - a perfect click gives you a good score
var good_click_range = 150
## how many milliseconds + or - a perfect click is actually clickable (and gives a bad score)
var clickable_range = 500

## multiply the base damage by this amount on an incorrect click
const INCORRECT_DAMAGE_MULT = 3


## returns if a click is close enough to the perfect click time to be clickable,
## given accuracy in milliseconds off the perfect click
func is_clickable(accuracy: float) -> bool:
	return accuracy <= clickable_range


## calculate the score to gain on a correct click, 
## given accuracy in milliseconds off the perfect click
func get_score(accuracy: float) -> int:
	if accuracy <= perfect_click_range:
		return PERFECT_CLICK_SCORE
	elif accuracy <= good_click_range:
		return GOOD_CLICK_SCORE
	else:
		return BAD_CLICK_SCORE


## get the amount of score to lose on an incorrect click
func get_score_on_incorrect() -> int:
	return -PERFECT_CLICK_SCORE


## get the amount of damage to take on an incorrect click, given the base damage
func get_damage_on_incorrect(base_damage: int) -> int:
	return base_damage * INCORRECT_DAMAGE_MULT
