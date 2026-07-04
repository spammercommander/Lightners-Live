extends CharacterBody2D

# menu == 0, song == 1, perform == 2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rhythm_board: Sprite2D = $"../../RhythmBoard"
@onready var l_hit_sprite: AnimatedSprite2D = $"../../RhythmBoard/Left Hit"
@onready var r_hit_sprite: AnimatedSprite2D = $"../../RhythmBoard/Right Hit"
@onready var l_hit_area: Area2D = $"../../RhythmBoard/Left Hit/L Area"
@onready var r_hit_area: Area2D = $"../../RhythmBoard/Right Hit/R Area"
@onready var l_hit_box: CollisionShape2D = $"../../RhythmBoard/Left Hit/L Area/L HitBox"
@onready var r_hit_box: CollisionShape2D = $"../../RhythmBoard/Right Hit/R Area/R HitBox"
@onready var l_hit_fx: AnimatedSprite2D = $"../../RhythmBoard/Left Hit/Hit FX"
@onready var r_hit_fx: AnimatedSprite2D = $"../../RhythmBoard/Right Hit/Hit FX"
@onready var left_asp: AudioStreamPlayer = $"../../RhythmBoard/Left ASP"
@onready var right_asp: AudioStreamPlayer = $"../../RhythmBoard/Right ASP"
@onready var score_label: Label = $"../../ScoreLabel"
@onready var midi_player: Node = $"../../MidiPlayer"
@onready var pause_menu: Node = $"../../Menus/PauseMenu"

func _ready() -> void:
	Global.GAME_STATE = Global.STATES.PERFORM
	Global.IS_ALT_NOTE = false
	Engine.max_fps = 30
	# rhythm_board.visible = false
	update_score_label(Global.get_display_score())
	if !Global.score_changed.is_connected(update_score_label):
		Global.score_changed.connect(update_score_label)
	call_deferred("setup_rhythm_board")

func setup_rhythm_board():
	rhythm_board.set_process(false)
	l_hit_box.disabled = false
	r_hit_box.disabled = false

func _process(_delta: float) -> void:
	# apparently Godot's version of switch-case is match
	if Global.GAME_STATE == Global.STATES.PERFORM:
		perform_input()
		update_hold_note_state(false)
		update_hold_note_state(true)
			
func perform_input() -> void:
	# non-game controls
	if Input.is_action_just_released("escape"):
		pause_game()

	# low/left notes
	if Input.is_action_just_pressed("left note"):
		l_hit_sprite.play("hit")
		left_asp.play()
		animated_sprite.play("low_note_down")
		hit_note(false)
	elif Input.is_action_just_released("left note"):
		l_hit_sprite.play("idle")
		animated_sprite.play("low_note_up")
	# high/right notes
	if Input.is_action_just_pressed("right note"):
		r_hit_sprite.play("hit")
		right_asp.play()
		animated_sprite.play("high_note_down")
		hit_note(true)
	elif Input.is_action_just_released("right note"):
		r_hit_sprite.play("idle")
		animated_sprite.play("high_note_up")
		
func pause_game():
		pause_song()
		open_pause_menu()
	
func pause_song():
	Global.GAME_STATE = Global.STATES.PAUSE
	if midi_player != null and midi_player.has_method("pause_song"):
		midi_player.call("pause_song")

func open_pause_menu():
	if pause_menu == null:
		return
		
	pause_menu.visible = true
	pause_menu.set_process(true)

func hit_note(is_right: bool):
	var lane := "right" if is_right else "left"
	var timing_result: Dictionary = Global.consume_tap_timing_note(lane, Time.get_ticks_msec() / 1000.0)

	if !timing_result.is_empty():
		play_hit_judgment(is_right, timing_result["judgment"])
		if is_instance_valid(timing_result["instance"]):
			remove_hit_note(timing_result["instance"])
		return

	var hit_area = r_hit_area if is_right else l_hit_area
	var best_area = get_best_note_area(hit_area, is_right, false)

	if best_area == null:
		return

	if best_area.get_meta("isPerfect", false):
		play_hit_judgment(is_right, "perfect")
	else:
		play_hit_judgment(is_right, "good")

	remove_hit_note(best_area.get_parent())

func play_hit_judgment(is_right: bool, judgment: String, award_score := true):
	var hit_fx = r_hit_fx if is_right else l_hit_fx

	if judgment == "perfect":
		hit_fx.play("perfect")
		if award_score:
			Global.add_score(Global.PERFECT_SCORE)
	else:
		hit_fx.play("almost")
		if award_score:
			Global.add_score(Global.GOOD_SCORE)

func update_hold_note_state(is_right: bool):
	var hit_area = r_hit_area if is_right else l_hit_area
	var input_name := "right note" if is_right else "left note"
	var is_holding := Input.is_action_pressed(input_name)

	for area in hit_area.get_overlapping_areas():
		if !is_matching_note_area(area, is_right):
			continue
		if !area.get_meta("isHold", false):
			continue

		var hold_note: Node = area.get_parent()
		if !hold_note.get_meta("is_active_hold", true):
			continue

		var hold_id: int = hold_note.get_meta("hold_id", 0)
		if Global.is_hold_chain_failed(hold_id):
			if hold_note.has_method("deactivate_hold"):
				hold_note.deactivate_hold()
			continue

		if is_holding:
			play_hit_judgment(is_right, "perfect", false)
			Global.add_score(Global.HOLD_SCORE_PER_SECOND * Global.HOLD_SCORE_INTERVAL)
			remove_hit_note(hold_note)

func get_best_note_area(hit_area: Area2D, is_right: bool, hold_only: bool) -> Area2D:
	var fallback_area: Area2D = null

	for area in hit_area.get_overlapping_areas():
		if !is_matching_note_area(area, is_right):
			continue
		if area.get_meta("isHold", false):
			continue
		if hold_only and !area.get_meta("isHold", false):
			continue
		if area.get_meta("isPerfect", false):
			return area
		if fallback_area == null:
			fallback_area = area

	return fallback_area

func is_matching_note_area(area: Area2D, is_right: bool) -> bool:
	return area.has_meta("isRight") and area.get_meta("isRight") == is_right

func remove_hit_note(note_instance: Node):
	if !is_instance_valid(note_instance):
		return

	note_instance.set_meta("was_hit", true)
	if note_instance.get_meta("is_timing_managed_tap", false):
		Global.remove_tap_timing_note_instance(note_instance)
	disable_note_collisions(note_instance)
	note_instance.hide()
	note_instance.set_process(false)
	note_instance.queue_free()

func disable_note_collisions(node: Node):
	if node is Area2D:
		node.monitoring = false
		node.monitorable = false
	if node is CollisionShape2D:
		node.disabled = true

	for child in node.get_children():
		disable_note_collisions(child)

func update_score_label(new_score: int):
	score_label.text = "SCORE " + str(new_score)

func enter_menu():
	pass

func enter_song_select():
	pass

func enter_perform():
	Global.GAME_STATE = Global.STATES.PERFORM
	rhythm_board.visible = true
