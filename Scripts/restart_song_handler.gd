extends Node2D

@export var hold_time := 1.25
@export var radius := 22.0
@export var fill_color := Color(1.0, 1.0, 1.0, 0.85)
@export var background_color := Color(0.0, 0.0, 0.0, 0.45)
@export var outline_color := Color(1.0, 1.0, 1.0, 0.95)

@onready var restart_label: Label = $RestartLabel
@onready var midi_player: Node = $"../MidiPlayer"

var hold_elapsed := 0.0
var is_holding_restart := false
var has_triggered_restart := false

func _ready() -> void:
	restart_label.visible = false
	queue_redraw()

func _process(delta: float) -> void:
	var is_pressed := Input.is_key_pressed(KEY_R)

	if is_pressed:
		if has_triggered_restart:
			return
		is_holding_restart = true
		restart_label.visible = true
		hold_elapsed = minf(hold_elapsed + delta, hold_time)
		if hold_elapsed >= hold_time and !has_triggered_restart:
			has_triggered_restart = true
			restart_current_song()
	else:
		reset_restart_hold()

	queue_redraw()

func _draw() -> void:
	if !is_holding_restart:
		return

	var progress := clampf(hold_elapsed / hold_time, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, background_color)
	draw_progress_slice(progress)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, outline_color, 2.0)

func draw_progress_slice(progress: float) -> void:
	if progress <= 0.0:
		return

	var points: PackedVector2Array = [Vector2.ZERO]
	var start_angle := -PI / 2.0
	var end_angle := start_angle + TAU * progress
	var segment_count := maxi(2, ceili(48.0 * progress))

	for segment_index in range(segment_count + 1):
		var segment_progress := float(segment_index) / float(segment_count)
		var angle := lerpf(start_angle, end_angle, segment_progress)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(points, fill_color)

func restart_current_song() -> void:
	if midi_player != null and midi_player.has_method("restart_song"):
		midi_player.call("restart_song")
	is_holding_restart = false
	hold_elapsed = 0.0
	restart_label.visible = false
	queue_redraw()

func reset_restart_hold() -> void:
	is_holding_restart = false
	has_triggered_restart = false
	hold_elapsed = 0.0
	restart_label.visible = false

func _on_timeout() -> void:
	restart_current_song()
