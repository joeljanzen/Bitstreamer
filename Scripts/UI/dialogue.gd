class_name Dialogue
extends Control

## Emitted when a dialogue sequence has been initiated.
signal dialogue_entered

## Emitted when a dialogue sequence has ended.
signal dialogue_exited

## When an asterisk followed by an event name ending with a colon is at the 
## start of the sequence this event signal is emitted.
signal dialogue_event(event_name: String)

const DIALOGUE_PATH: String = "res://Resources/Text/tutorial_1_eng.json"

## The speed that text is typed into the textbox.
const ANIM_SPEED: float = 30

@onready var textbox = $MarginContainer/Panel/MarginContainer/RichTextLabel
@onready var typing_sound = $TypeText
@onready var panel = $MarginContainer/Panel
@onready var anim_player = $AnimationPlayer

## True when a dialogue sequence is currently in progress.
var sequence_active := false

## Stores text for dialogue sequences.
var _dialogue: Dictionary

## The current dialogue sequence being displayed.
var _dialogue_sequence: String

## The current line of dialogue in the sequence being displayed.
var _curr_line

## The current number of characters visible in the textbox.
var _curr_visible_chars: int


func _ready() -> void:
	_dialogue = _load_dialogue(DIALOGUE_PATH)
	visible = false


## Play the typing sound for every next visible character.
func _process(_delta: float) -> void:
	if anim_player.is_playing():
		if _curr_visible_chars < textbox.visible_characters - 1:
			typing_sound.play()
			_curr_visible_chars = textbox.visible_characters


## Catch events to advance or skip dialogue.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("click")):
		if anim_player.is_playing():
			anim_player.stop()
			textbox.visible_ratio = 1
		else:
			_next_dialogue()


## Start new dialog sequence.
func display_dialogue(passed_dialogue_sequence: String) -> void:
	_dialogue_sequence = passed_dialogue_sequence
	_curr_line = 0
	_next_dialogue()
	visible = true
	sequence_active = true
	dialogue_entered.emit()


## Pauses typing animation if it is currently playing.
func pause_dialogue() -> void:
	anim_player.pause()


## Resumes typing animation if it was paused.
func resume_dialogue() -> void:
	if anim_player.current_animation_position != anim_player.get_section_end_time():
		anim_player.play()


## Load next line of text in the sequence.
func _next_dialogue() -> void:
	_curr_visible_chars = 0
	
	var line = _dialogue[_dialogue_sequence][_curr_line]
	if line != "":
		if line.begins_with('*'):
			var event_name = line.substr(1,line.find(':') - 1)
			dialogue_event.emit(event_name)
			line = line.substr(line.find(':') + 1)
		
		textbox.text = line
		_curr_line += 1
		# Animation speed scales with the amount of text there is.
		anim_player.speed_scale = ANIM_SPEED / textbox.get_parsed_text().length()
		anim_player.play("type_text")
	else:
		visible = false
		sequence_active = false
		dialogue_exited.emit()


## Loads dialogue text from its JSON file.
func _load_dialogue(filePath: String):
	if FileAccess.file_exists(filePath):
		var data = FileAccess.open(filePath, FileAccess.READ)
		var parsed = JSON.parse_string(data.get_as_text())
		if parsed is Dictionary:
			return parsed
		else:
			push_error("Dialogue failed to load!")
