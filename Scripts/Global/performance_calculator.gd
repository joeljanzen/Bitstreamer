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
## how many milliseconds + or - a perfect click is actually clickable 
## (gives a bad score within this range).
var clickable_range = 150 # 500 by default
## holds statistics for the current level
var statistics: LevelStatistics


## connect the statistics for the current level to the performance calculator
func connect_stats(stats: LevelStatistics):
	statistics = stats


## returns if a click is close enough to the perfect click time to be clickable,
## given accuracy in milliseconds off the perfect click
func is_clickable(accuracy: float) -> bool:
	return abs(accuracy) <= clickable_range


## returns if a click is past the cursor and not clickable,
## given accuracy in milliseconds off the perfect click
func is_missed(accuracy: float) -> bool:
	return accuracy < 0 && !is_clickable(accuracy)


## calculate the score to gain on a correct click, 
## given accuracy in milliseconds off a perfect click
func get_score(accuracy: float) -> int:
	accuracy = abs(accuracy)
	if accuracy <= perfect_click_range:
		return PERFECT_CLICK_SCORE
	elif accuracy <= good_click_range:
		return GOOD_CLICK_SCORE
	else:
		return BAD_CLICK_SCORE
