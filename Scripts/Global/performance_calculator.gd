extends Node
## Calculates various performance statistics during gameplay.

## The quality asssociated with a click of a certain accuracy.
enum ClickQuality {
	PERFECT,
	GOOD,
	OKAY,
	MISS,
	ERROR,
}

# The base score given for a certain accuracy of click.
## The base score given for a click within the bounds of perfect_click_range.
const PERFECT_CLICK_SCORE := 300
## The base score given for a click within the bounds of good_click_range.
const GOOD_CLICK_SCORE := 100
## The base score given for a click within the bounds of clickable_range.
const OKAY_CLICK_SCORE := 50

## When a combo is high enough to start granting bonus score (inclusive).
const COMBO_SCORE_BONUS_START := 30

## How quickly the bonus score grows once the combo bonus start has been 
## reached.
const COMBO_BONUS_SCALER := 0.02

# The health restored for a certain accuracy of click.
## The health restored for a click within the bounds of perfect_click_range.
const PERFECT_CLICK_HEAL := 6
## The health restored for a click within the bounds of good_click_range.
const GOOD_CLICK_HEAL := 2
## The health restored for a click within the bounds of clickable_range.
const OKAY_CLICK_HEAL := 1

## When a combo is high enough to start restoring health (inclusive).
const COMBO_HEALTH_RESTORE_START := 5

# The accuracy ranges needed to achieve each click score.
## How many milliseconds + or - a perfect click gives you a perfect score.
var perfect_click_range: float = 80
## How many milliseconds + or - a perfect click gives you a good score.
var good_click_range: float = 140
## How many milliseconds + or - a perfect click is actually clickable
## (gives an okay score unless the click is within the good or perfect range).
var clickable_range: float = 200

## How much time it takes for a bit to reach the cursor after being sent, in
## seconds.
var approach_time: float

## Contains statistics for the current play.
var statistics: GameplayStatistics


## Connects the statistics for the current play to the PerformanceCalculator.
func connect_gameplay_stats(stats: GameplayStatistics) -> void:
	statistics = stats


## Set the difficulty for the performance calculator to use during gameplay.
func set_difficulty(difficulty: float) -> void:
	perfect_click_range = 80 - 6 * difficulty
	good_click_range = 140 - 8 * difficulty
	clickable_range = 200 - 10 * difficulty
	print("Perfect hit window: +- %.2f ms" % perfect_click_range)
	print("Good hit window: +- %.2f ms" % good_click_range)
	print("Okay hit window: +- %.2f ms" % clickable_range)


## Sets and returns the approach time of bits given a speed.
func set_approach_time(speed: float) -> float:
	if speed <= 10:
		approach_time = 3 - 0.25 * (speed - 1)
	else:
		approach_time = 0.75 - 0.125 * (speed - 10)
	
	print("Approach time: %.2f ms" % (approach_time * 1000))
	return approach_time


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
		return OKAY_CLICK_SCORE
	else:
		push_error("Tried to get the score of an accuracy outside of clickable_range!")
		return 0


## Calculate the score to gain on a correct click including all bonuses, 
## given accuracy in milliseconds off a perfect click.
func get_score(accuracy: float) -> int:
	accuracy = abs(accuracy)
	var score = get_raw_score(accuracy)
	#print("raw score was %d" % score)
	
	# Calculate combo bonus.
	var multiplier := 1.0
	if statistics.combo >= COMBO_SCORE_BONUS_START:
		# The part of the combo considered for bonuses.
		var considered_combo: float = statistics.combo - COMBO_SCORE_BONUS_START + 1
		multiplier += float(considered_combo) * COMBO_BONUS_SCALER
	#print("multiplier is %f" % multiplier)
	score *= multiplier
	#print("full score is %d\n" % score)
	return score


## Get the click quality for a given raw score (get the raw score from the
## get_raw_score function of this class).
## If the score is 0, it is treated as a miss, and if it's negative, it is
## treated as an error.
func get_click_quality(raw_score: int) -> ClickQuality:
	if raw_score >= 0:
		match raw_score:
			PERFECT_CLICK_SCORE:
				return ClickQuality.PERFECT
			GOOD_CLICK_SCORE:
				return ClickQuality.GOOD
			OKAY_CLICK_SCORE:
				return ClickQuality.OKAY
			0:
				return ClickQuality.MISS
			_:
				push_error("Tried to get click quality of a non-standard raw score!")
				return ClickQuality.MISS
	else:
		return ClickQuality.ERROR


## Calculate the amount of health regained from a click, given the raw score 
## gained before any bonuses. Also takes into account the current combo.
func calculate_health_gain(raw_score: int) -> int:
	var health: int
	# Only start healing after reaching the required combo.
	if statistics.combo >= COMBO_HEALTH_RESTORE_START:
		match raw_score:
			PERFECT_CLICK_SCORE:
				return PERFECT_CLICK_HEAL
			GOOD_CLICK_SCORE:
				return GOOD_CLICK_HEAL
			OKAY_CLICK_SCORE:
				return OKAY_CLICK_HEAL
			_:
				push_error("Tried to get the health regen for a non-standard raw score!")
				return 0
	return health
