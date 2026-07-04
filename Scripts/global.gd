extends Node

var GAME_STATE: int # determine current state of the game
enum STATES {PAUSE, SONG_SELECT, PERFORM} # values for GAME_STATE
var IS_ALT_NOTE: bool 
var AUDIO_DELAY: float = 5.0
var AUDIO_START_DELAY: float = 1.1

const PERFECT_WINDOW := 0.20
const GOOD_WINDOW := 0.35
const PERFECT_SCORE := 50
const GOOD_SCORE := 25
const HOLD_SCORE_PER_SECOND := 10.0
const HOLD_SCORE_INTERVAL := 0.08
const LONG_HOLD_ALT_THRESHOLD := 2.0

signal score_changed(score: int)

var tap_timing_notes := {
	"left": [],
	"right": [],
}
var failed_hold_ids := {}
var hold_pieces_by_id := {}
var long_hold_ids := {}
var score := 0.0

func clear_tap_timing_notes():
	tap_timing_notes["left"].clear()
	tap_timing_notes["right"].clear()
	failed_hold_ids.clear()
	hold_pieces_by_id.clear()
	long_hold_ids.clear()

func reset_score():
	score = 0.0
	score_changed.emit(get_display_score())

func add_score(points: float):
	score += points
	score_changed.emit(get_display_score())

func get_display_score() -> int:
	return floori(score)

func register_hold_piece(hold_id: int, hold_piece: Node):
	if hold_id <= 0:
		return

	if !hold_pieces_by_id.has(hold_id):
		hold_pieces_by_id[hold_id] = []
	hold_pieces_by_id[hold_id].append(hold_piece)

	if is_hold_chain_failed(hold_id) and hold_piece.has_method("deactivate_hold"):
		hold_piece.deactivate_hold()

func mark_long_hold_chain(hold_id: int):
	if hold_id <= 0:
		return

	long_hold_ids[hold_id] = true

func is_long_hold_chain(hold_id: int) -> bool:
	return long_hold_ids.has(hold_id)

func fail_hold_chain(hold_id: int):
	if hold_id <= 0:
		return

	failed_hold_ids[hold_id] = true
	for hold_piece in hold_pieces_by_id.get(hold_id, []):
		if is_instance_valid(hold_piece) and hold_piece.has_method("deactivate_hold"):
			hold_piece.deactivate_hold()

func is_hold_chain_failed(hold_id: int) -> bool:
	return failed_hold_ids.has(hold_id)

func register_tap_timing_note(lane: String, note_instance: Node, target_time: float):
	if !tap_timing_notes.has(lane):
		return

	tap_timing_notes[lane].append({
		"target_time": target_time,
		"instance": note_instance,
	})

func consume_tap_timing_note(lane: String, current_time: float) -> Dictionary:
	if !tap_timing_notes.has(lane):
		return {}

	var lane_notes: Array = tap_timing_notes[lane]
	while !lane_notes.is_empty():
		var tap_note: Dictionary = lane_notes[0]
		var target_time: float = tap_note["target_time"]
		var time_diff := current_time - target_time
		var abs_diff := absf(time_diff)

		if time_diff > GOOD_WINDOW:
			lane_notes.pop_front()
			if is_instance_valid(tap_note["instance"]):
				tap_note["instance"].queue_free()
			continue

		if abs_diff <= PERFECT_WINDOW:
			lane_notes.pop_front()
			tap_note["judgment"] = "perfect"
			return tap_note

		if abs_diff <= GOOD_WINDOW:
			lane_notes.pop_front()
			tap_note["judgment"] = "good"
			return tap_note

		return {}

	return {}
