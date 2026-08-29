class_name ArrowTransition
extends Control

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

## Emits when the animation finishes.
signal animation_finished(_anim_name: StringName)

## How long it takes to fade out or in to a level. The total transition time is
## double this value.
const TRANSITION_FADE_SPEED: float = 0.25

func _ready() -> void:
	_animation_player.animation_finished.connect(func(_anim_name): animation_finished.emit())


## You have to position the dumb arrow like before "fade_out" is called because 
## for some reason it just isn't oriented properly right away and flickers weird.
## YOU ONLY HAVE TO CALL THIS IF FADE IN WASN'T ALREADY CALLED. FOR SOME REASON
## THE FADE IN ANIMATION FIXES THE POSITION AND THIS TRANSITION BECOMES SMOOTH
## AGAIN...
func prep_for_fade_out() -> void:
	_animation_player.play("RESET_FADE_OUT")


## Fade the screen to black.
func fade_out() -> void:
	show()
	_animation_player.play("fade_out", -1, 1 / TRANSITION_FADE_SPEED)


## Fade in the screen from black.
func fade_in() -> void:
	show()
	_animation_player.play("fade_in", -1, 1 / TRANSITION_FADE_SPEED)
	await _animation_player.animation_finished
	hide()
