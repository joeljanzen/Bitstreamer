extends Resource
class_name SaveDataResource
## Where game data is stored.

## True if the player completed the tutorial.
@export var tutorial_played := false

## Stores the last used sorting method in the level selection scene.
@export var sorting_method: LevelSelect.SortingType = LevelSelect.SortingType.DIFFICULTY

## The total score of all completed non-practice plays. Divide by the 
## completed_play_count to get the average score over those plays.
@export var total_score: int = 0

## The total number of non-practice plays that have been finished, either by 
## completion or failure. Quitting or restarting before that point will not 
## count as a play.
@export var play_count: int = 0

## THe total number of completed non-practice plays. Used to determine average
## accuracy. Can also determine average score.
@export var completed_play_count: int = 0

## The total accuracy summed from all completed non-practice plays. Divide by 
## the completed_play_count to get the average accuracy over those plays.
@export var cumulative_accuracy: float = 0

## The total number of bits clicked without receiving a miss or error, in any
## plays excluding the tutorial (even practice plays or uncompleted plays).
@export var total_bits_received: int = 0

## The maximum combo achieved out of all finished non-practice plays, either by 
## completion or failure.
@export var maximum_combo: int = 0


## Update global player statistics, given a completed play (not a practice play 
## or failed play). Not the same as SaveLoad.save_play().
## You still need to call SaveLoad.save_game() for this data to be saved.
func update_stats_from_completed_play(play_data: PlayData) -> void:
	total_score += play_data.score
	play_count += 1
	completed_play_count += 1
	cumulative_accuracy += play_data.accuracy
	update_bits_received(play_data)
	maximum_combo = max(maximum_combo, play_data.max_combo)


## Update global player statistics, given a failed play (not a practice play). 
## Not the same as SaveLoad.save_play().
## You still need to call SaveLoad.save_game() for this data to be saved.
func update_stats_from_failed_play(play_data: PlayData) -> void:
	play_count += 1
	update_bits_received(play_data)
	maximum_combo = max(maximum_combo, play_data.max_combo)


## Update the global count for bits received (that were not misses or errors).
## If you already called update_stats from a failed or completed play, this will
## be updated automatically.
## You still need to call SaveLoad.save_game() for this data to be saved.
func update_bits_received(play_data: PlayData) -> void:
	var bits_received = play_data.perfect_clicks + play_data.good_clicks + play_data.okay_clicks
	total_bits_received += bits_received
