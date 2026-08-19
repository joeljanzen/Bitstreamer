class_name GameCrashUI
extends Control
## Displays when the player loses (the program crashes).

@onready var _progress_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/ProgressPanel/MarginContainer/Progress
@onready var _score_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Score
@onready var _accuracy_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Combo
@onready var _extra_stats_container = $CanvasLayer/MarginContainer2/VBoxContainer/ExtraStatsPanel/MarginContainer/ExtraStats
@onready var _mods_container = $CanvasLayer/MarginContainer2/VBoxContainer/ModsContainer

# Sounds.
@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## The size of mod icons.
const MOD_ICON_SIZE: int = 100

var _level_UI: LevelUI

## Stores data for the current play of a level, including score, combo, etc.
var _play_data: PlayData


## Display statistics for the play.
func _ready() -> void:
	_progress_label.text = "%.2f%% Progress" % _level_UI.get_current_progress()
	_score_label.text = "%d Score" % _play_data.score
	_accuracy_label.text = "%.2f%% Accuracy" % _play_data.accuracy
	_combo_label.text = "%dx Maximum Combo" % _play_data.max_combo
	
	var stat_label = _extra_stats_container.get_children()
	stat_label[0].text = ("[color=%s]%d Perfect[/color]" % 
	[GameSettings.perfect_click_colour, _play_data.perfect_clicks])
	stat_label[1].text = ("[color=%s]%d Good[/color]" % 
	[GameSettings.good_click_colour, _play_data.good_clicks])
	stat_label[2].text = ("[color=%s]%d Okay[/color]" % 
	[GameSettings.okay_click_colour, _play_data.okay_clicks])
	stat_label[3].text = ("[color=%s]%d Miss[/color]" % 
	[GameSettings.missed_click_colour, _play_data.missed_clicks])
	stat_label[4].text = ("[color=%s]%d Error[/color]" % 
	[GameSettings.incorrect_click_colour, _play_data.error_clicks])
	
	if ModManager.has_active_mods():
		_mods_container.show()
		_add_mod_icons()


## For each active mod, display its icon on the crash screen.
func _add_mod_icons() -> void:
	var icons: Array[Texture2D] = ModManager.get_active_mod_icons()
	
	# Add current active icons as TextureRect nodes.
	for icon in icons:
		var texture_rect = TextureRect.new()
		texture_rect.texture = icon
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		texture_rect.custom_minimum_size.x = MOD_ICON_SIZE
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mods_container.add_child(texture_rect)


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## Connects the LevelUI to the GameCrashUI.
func connect_level_UI(UI: LevelUI) -> void:
	_level_UI = UI
	_play_data = UI.play_data


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	GameLevel.restart(get_tree())


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.quit(get_tree())


func _on_reboot_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
