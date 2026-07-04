extends MidiPlayer

# to instantiate notes
const LEFT_NOTE = preload("res://Scenes/Interface/Notes/left_note.tscn")
const RIGHT_NOTE = preload("res://Scenes/Interface/Notes/right_note.tscn")
const L_HOLD = preload("res://Scenes/Interface/Notes/l_hold_note.tscn")
const R_HOLD = preload("res://Scenes/Interface/Notes/r_hold_note.tscn")

const LEFT_TAP_NOTE := 38
const RIGHT_TAP_NOTE := 36
const LEFT_HOLD_NOTE := 39
const RIGHT_HOLD_NOTE := 35
const HOLD_SPAWN_INTERVAL := 0.08

@onready var left_holder: Node2D = $"../Notes/Left Holder"
@onready var right_holder: Node2D = $"../Notes/Right Holder"

# MidiPlayer & audio
@onready var player: MidiPlayer = $"."
@onready var asp: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_delay: Timer = $"Audio Delay"

var active_hold_notes := {}
var hold_spawn_timers := {}
var active_hold_ids := {}
var hold_start_times := {}
var cached_hold_durations := {}
var hold_duration_indices := {}
var next_hold_id := 1

func _ready():
	cache_hold_durations()
	setup_hold_spawning()
	Global.clear_tap_timing_notes()
	Global.reset_score()

	audio_delay.wait_time = Global.AUDIO_START_DELAY
	audio_delay.one_shot = true
	audio_delay.start()
	
	player.note.connect(note_callback) # on MIDI note/signal, trigger note_callback
	player.play()

func _process(delta: float):
	spawn_active_hold_notes(delta)

func setup_hold_spawning():
	active_hold_notes.clear()
	active_hold_notes[LEFT_HOLD_NOTE] = false
	active_hold_notes[RIGHT_HOLD_NOTE] = false

	hold_spawn_timers.clear()
	hold_spawn_timers[LEFT_HOLD_NOTE] = 0.0
	hold_spawn_timers[RIGHT_HOLD_NOTE] = 0.0

	active_hold_ids.clear()
	active_hold_ids[LEFT_HOLD_NOTE] = 0
	active_hold_ids[RIGHT_HOLD_NOTE] = 0
	hold_start_times.clear()

	hold_duration_indices.clear()
	hold_duration_indices[LEFT_HOLD_NOTE] = 0
	hold_duration_indices[RIGHT_HOLD_NOTE] = 0
	next_hold_id = 1

func note_callback(event, _track):
	if !event.has("note"):
		return

	var midi_note = event["note"]

	match midi_note:
		LEFT_TAP_NOTE:
			if is_note_on(event):
				var left_instance := instantiate_note(LEFT_NOTE, left_holder)
				Global.register_tap_timing_note("left", left_instance, get_target_hit_time())
		RIGHT_TAP_NOTE:
			if is_note_on(event):
				var right_instance := instantiate_note(RIGHT_NOTE, right_holder)
				Global.register_tap_timing_note("right", right_instance, get_target_hit_time())
		LEFT_HOLD_NOTE:
			handle_hold_event(LEFT_HOLD_NOTE, event)
		RIGHT_HOLD_NOTE:
			handle_hold_event(RIGHT_HOLD_NOTE, event)

func is_note_on(event: Dictionary) -> bool:
	return event.get("subtype", -1) == MIDI_MESSAGE_NOTE_ON and event.get("data", 1) > 0

func is_note_off(event: Dictionary) -> bool:
	return event.get("subtype", -1) == MIDI_MESSAGE_NOTE_OFF or (event.get("subtype", -1) == MIDI_MESSAGE_NOTE_ON and event.get("data", 1) == 0)

func handle_hold_event(midi_note: int, event: Dictionary):
	if event.get("subtype", -1) == MIDI_MESSAGE_NOTE_ON:
		start_hold_note(midi_note)
	elif is_note_off(event):
		stop_hold_note(midi_note)

func start_hold_note(midi_note: int):
	if !active_hold_notes.has(midi_note):
		return

	active_hold_notes[midi_note] = true
	active_hold_ids[midi_note] = next_hold_id
	next_hold_id += 1
	hold_start_times[midi_note] = Time.get_ticks_msec() / 1000.0
	var hold_duration := get_next_cached_hold_duration(midi_note)
	if hold_duration >= Global.LONG_HOLD_ALT_THRESHOLD:
		Global.mark_long_hold_chain(active_hold_ids[midi_note])
		Global.activate_long_hold_lane(get_hold_lane(midi_note), Time.get_ticks_msec() / 1000.0)
	hold_spawn_timers[midi_note] = 0.0
	spawn_hold_note(midi_note)

func stop_hold_note(midi_note: int):
	if !active_hold_notes.has(midi_note):
		return

	mark_long_hold_if_needed(midi_note)
	if Global.is_long_hold_chain(active_hold_ids[midi_note]):
		Global.release_long_hold_lane(get_hold_lane(midi_note), Time.get_ticks_msec() / 1000.0)
	active_hold_notes[midi_note] = false
	active_hold_ids[midi_note] = 0
	hold_start_times.erase(midi_note)
	hold_spawn_timers[midi_note] = 0.0

func spawn_active_hold_notes(delta: float):
	for midi_note in active_hold_notes:
		if !active_hold_notes[midi_note]:
			continue

		mark_long_hold_if_needed(midi_note)
		hold_spawn_timers[midi_note] += delta
		if hold_spawn_timers[midi_note] < HOLD_SPAWN_INTERVAL:
			continue

		hold_spawn_timers[midi_note] -= HOLD_SPAWN_INTERVAL
		spawn_hold_note(midi_note)

func spawn_hold_note(midi_note: int):
	var hold_instance: Node = null

	match midi_note:
		LEFT_HOLD_NOTE:
			hold_instance = instantiate_note(L_HOLD, left_holder)
		RIGHT_HOLD_NOTE:
			hold_instance = instantiate_note(R_HOLD, right_holder)

	if hold_instance == null:
		return

	var hold_id: int = active_hold_ids[midi_note]
	hold_instance.set_meta("hold_id", hold_id)
	hold_instance.set_meta("is_long_hold_chain", Global.is_long_hold_chain(hold_id))
	Global.register_hold_piece(hold_id, hold_instance)

func mark_long_hold_if_needed(midi_note: int):
	var hold_id: int = active_hold_ids.get(midi_note, 0)
	if hold_id <= 0 or Global.is_long_hold_chain(hold_id):
		return
	if !hold_start_times.has(midi_note):
		return

	var hold_duration: float = Time.get_ticks_msec() / 1000.0 - hold_start_times[midi_note]
	if hold_duration >= Global.LONG_HOLD_ALT_THRESHOLD:
		Global.mark_long_hold_chain(hold_id)
		Global.activate_long_hold_lane(get_hold_lane(midi_note), Time.get_ticks_msec() / 1000.0)

func get_hold_lane(midi_note: int) -> String:
	if midi_note == RIGHT_HOLD_NOTE:
		return "right"

	return "left"

func cache_hold_durations():
	cached_hold_durations.clear()
	cached_hold_durations[LEFT_HOLD_NOTE] = []
	cached_hold_durations[RIGHT_HOLD_NOTE] = []

	var open_hold_starts := {}
	open_hold_starts[LEFT_HOLD_NOTE] = []
	open_hold_starts[RIGHT_HOLD_NOTE] = []

	if midi == null:
		return

	for track in midi.tracks:
		var events: Array = track.get("events", [])
		for event in events:
			if !event.has("note") or !event.has("time"):
				continue

			var midi_note: int = event["note"]
			if !cached_hold_durations.has(midi_note):
				continue

			var event_time: float = event["time"]
			if is_note_on(event):
				open_hold_starts[midi_note].append(event_time)
			elif is_note_off(event) and !open_hold_starts[midi_note].is_empty():
				var start_time: float = open_hold_starts[midi_note].pop_back()
				cached_hold_durations[midi_note].append(maxf(event_time - start_time, 0.0))

func get_next_cached_hold_duration(midi_note: int) -> float:
	var durations: Array = cached_hold_durations.get(midi_note, [])
	var duration_index: int = hold_duration_indices.get(midi_note, 0)
	hold_duration_indices[midi_note] = duration_index + 1

	if duration_index >= durations.size():
		return 0.0

	return durations[duration_index]

func instantiate_note(note_res: Resource, location: Node2D) -> Node:
	var instance = note_res.instantiate()
	location.add_child(instance)
	return instance

func get_target_hit_time() -> float:
	return Time.get_ticks_msec() / 1000.0 + Global.AUDIO_DELAY

func restart_song():
	if player.has_method("stop"):
		player.call("stop")
	asp.stop()
	audio_delay.stop()
	clear_spawned_notes()
	setup_hold_spawning()
	Global.clear_tap_timing_notes()
	Global.reset_score()
	audio_delay.wait_time = Global.AUDIO_START_DELAY
	audio_delay.start()
	player.play()

func clear_spawned_notes():
	for holder in [left_holder, right_holder]:
		for child in holder.get_children():
			child.set_process(false)
			child.queue_free()

func play_audio():
	asp.stop()
	asp.play()
