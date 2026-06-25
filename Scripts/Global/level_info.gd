class_name LevelInfo
extends Node
## Stores information about a level.

## The name of the level.
var level_name: String = ""
## The name of the audio file of the song to play.
var song_filename: String = ""
## The beats per minute of the music (good luck if the song changes bpm bro).
var bpm: float = -1
## The speed at which bits fly across the screen.
var speed: float = -1
## The difficulty of the level, AKA how accurate clicks need to be in order to
## get a perfect score (a good or okay score is also harder to achieve).
var difficulty: float = -1
## The damage each bit does when missed or incorrectly clicked.
## Override damage value to 0 to make the level impossible to fail.
var damage: int = -1
## The length of the level in seconds (how long the gameplay lasts).
var length: float = -1

## Initialize the level button, given its full filename.
func _init(filename: String) -> void:
	## This is where level files will actually be loaded, instead of in the 
	## level script.
	pass
