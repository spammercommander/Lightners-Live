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
var next_hold_id := 1

func _ready():
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
	hold_spawn_timers[midi_note] = 0.0
	spawn_hold_note(midi_note)

func stop_hold_note(midi_note: int):
	if !active_hold_notes.has(midi_note):
		return

	active_hold_notes[midi_note] = false
	active_hold_ids[midi_note] = 0
	hold_spawn_timers[midi_note] = 0.0

func spawn_active_hold_notes(delta: float):
	for midi_note in active_hold_notes:
		if !active_hold_notes[midi_note]:
			continue

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
	Global.register_hold_piece(hold_id, hold_instance)

func instantiate_note(note_res: Resource, location: Node2D) -> Node:
	var instance = note_res.instantiate()
	location.add_child(instance)
	return instance

func get_target_hit_time() -> float:
	return Time.get_ticks_msec() / 1000.0 + Global.AUDIO_DELAY

func play_audio():
	asp.play()
