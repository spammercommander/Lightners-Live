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

func _ready():
	setup_hold_spawning()

	audio_delay.wait_time = 1.1
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

func note_callback(event, _track):
	if !event.has("note"):
		return

	var midi_note = event["note"]

	match midi_note:
		LEFT_TAP_NOTE:
			if is_note_on(event):
				instantiate_note(LEFT_NOTE, left_holder)
		RIGHT_TAP_NOTE:
			if is_note_on(event):
				instantiate_note(RIGHT_NOTE, right_holder)
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
	hold_spawn_timers[midi_note] = 0.0
	spawn_hold_note(midi_note)

func stop_hold_note(midi_note: int):
	if !active_hold_notes.has(midi_note):
		return

	active_hold_notes[midi_note] = false
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
	match midi_note:
		LEFT_HOLD_NOTE:
			instantiate_note(L_HOLD, left_holder)
		RIGHT_HOLD_NOTE:
			instantiate_note(R_HOLD, right_holder)

func instantiate_note(note_res: Resource, location: Node2D):
	var instance = note_res.instantiate()
	print("Spawning %s" % note_res)

	location.add_child(instance)

func play_audio():
	asp.play()
