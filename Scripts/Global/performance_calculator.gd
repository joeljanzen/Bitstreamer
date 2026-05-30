extends Node
## Calculates various performance statistics during gameplay.

# The score given for a certain accuracy of click.
## The score given for a click within the bounds of perfect_click_range.
const PERFECT_CLICK_SCORE := 300
## The score given for a click within the bounds of good_click_range.
const GOOD_CLICK_SCORE := 100
## The score given for a click within the bounds of clickable_range.
const BAD_CLICK_SCORE := 50

## When a combo is high enough to start granting bonus score.
const COMBO_BONUS_START := 30

## How quickly the bonus score grows once the combo bonus start has been 
## reached.
const COMBO_BONUS_SCALER := 0.02

# The accuracy ranges needed to achieve each click score.
## How many milliseconds + or - a perfect click gives you a perfect score.
var perfect_click_range := 30
## How many milliseconds + or - a perfect click gives you a good score.
var good_click_range := 150
## How many milliseconds + or - a perfect click is actually clickable
## (gives a bad score unless the click is within the good or perfect range).
var clickable_range := 500

## Contains statistics for the current level.
var statistics: LevelStatistics


## Connects the statistics for the current level to the PerformanceCalculator.
func connect_stats(stats: LevelStatistics) -> void:
	statistics = stats


## Returns if a click is close enough to the perfect click time to be clickable,
## given accuracy in milliseconds off the perfect click.
func is_clickable(accuracy: float) -> bool:
	return abs(accuracy) <= clickable_range


## Returns if a click is past the cursor and not clickable,
## given accuracy in milliseconds off the perfect click.
func is_missed(accuracy: float) -> bool:
	return accuracy < 0 and !is_clickable(accuracy)


## Calculate the raw score to gain on a correct click before any bonuses, 
## given accuracy in milliseconds off a perfect click.
func get_raw_score(accuracy: float) -> int:
	accuracy = abs(accuracy)
	if accuracy <= perfect_click_range:
		return PERFECT_CLICK_SCORE
	elif accuracy <= good_click_range:
		return GOOD_CLICK_SCORE
	elif accuracy <= clickable_range:
		return BAD_CLICK_SCORE
	else:
		push_error("tried to get the score of an accuracy outside of clickable_range!")
		return 0


## Calculate the score to gain on a correct click including all bonuses, 
## given accuracy in milliseconds off a perfect click.
func get_score(accuracy: float) -> int:
	accuracy = abs(accuracy)
	var score = get_raw_score(accuracy)
	#print("raw score was %d" % score)
	
	# Calculate combo bonus.
	var multiplier := 1.0
	if statistics.combo >= COMBO_BONUS_START:
		# The part of the combo considered for bonuses.
		var considered_combo: float = statistics.combo - COMBO_BONUS_START + 1
		multiplier += float(considered_combo) * COMBO_BONUS_SCALER
	#print("multiplier is %f" % multiplier)
	score *= multiplier
	#print("full score is %d\n" % score)
	return score
