extends CharacterBody2D

# menu == 0, song == 1, perform == 2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rhythm_board: Sprite2D = $"../../RhythmBoard"


func _ready() -> void:
	Global.GAME_STATE = Global.STATES.PERFORM
	Global.IS_ALT_NOTE = false
	Engine.max_fps = 30
	# rhythm_board.visible = false

func _process(_delta: float) -> void:
	# apparently Godot's version of switch-case is match
	match Global.GAME_STATE:
		Global.STATES.MENU:
			pass
		Global.STATES.SONG_SELECT:
			pass
		Global.STATES.PERFORM:
			perform_input()
		_: # error handling
			push_error("The forbidden state has been achieved")
			
func perform_input() -> void:
	# low/left notes
	if Input.is_action_just_pressed("left note"):
		if Global.IS_ALT_NOTE:
			animated_sprite.play("alt_note_down")
		else:
			animated_sprite.play("low_note_down")
	elif Input.is_action_just_released("left note"):
		if Global.IS_ALT_NOTE:
			animated_sprite.play("alt_note_up")
		else:
			animated_sprite.play("low_note_up")
	# high/right notes
	if Input.is_action_just_pressed("right note"):
		if Global.IS_ALT_NOTE:
			animated_sprite.play("alt_note_down")
		else:
			animated_sprite.play("high_note_down")
	elif Input.is_action_just_released("right note"):
		if Global.IS_ALT_NOTE:
			animated_sprite.play("alt_note_up")
		else:
			animated_sprite.play("high_note_up")
			
	# misc. inputs

func hit_note():
	pass

func enter_menu():
	pass

func enter_song_select():
	pass

func enter_perform():
	Global.GAME_STATE = Global.STATES.PERFORM
	rhythm_board.visible = true
