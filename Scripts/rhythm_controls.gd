extends Sprite2D

@onready var l_sprite: AnimatedSprite2D = $"Left Hit"
@onready var r_sprite: AnimatedSprite2D = $"Right Hit"
@onready var r_area: CollisionShape2D = $"Right Hit/R Area/R HitBox"
@onready var l_area: CollisionShape2D = $"Left Hit/L Area/L HitBox"
@onready var r_fx: AnimatedSprite2D = $"Right Hit/Miss FX"
@onready var l_fx: AnimatedSprite2D = $"Left Hit/Miss FX"
@onready var left_asp: AudioStreamPlayer = $"Left ASP"
@onready var right_asp: AudioStreamPlayer = $"Right ASP"

func _ready():
	r_area.disabled = true
	l_area.disabled = true

func _process(_delta: float) -> void:
	if Global.GAME_STATE == Global.STATES.PERFORM:
		input_handler()
	
func input_handler():
	if Input.is_action_just_pressed("left note"):
		l_sprite.play("hit")
		left_asp.play()
		if l_area.disabled:
			l_area.disabled = false
	if Input.is_action_just_pressed("right note"):
		r_sprite.play("hit")
		right_asp.play()
		if r_area.disabled:
			r_area.disabled = false
	
	if Input.is_action_just_released("left note"):
		l_sprite.play("idle")
		if !l_area.disabled:
			l_area.disabled = true
	if Input.is_action_just_released("right note"):
		r_sprite.play("idle")
		if !r_area.disabled:
			r_area.disabled = true

func miss_area(area: Area2D):
	var note_instance: Node = area.get_parent()
	if note_instance.get_meta("was_hit", false):
		return
	if note_instance.get_meta("is_timing_managed_tap", false):
		note_instance.set_meta("was_missed", true)
		Global.remove_tap_timing_note_instance(note_instance)
	if area.get_meta("isHold", false) and !note_instance.get_meta("is_active_hold", true):
		note_instance.queue_free()
		return
	if area.get_meta("isHold", false):
		var hold_id: int = note_instance.get_meta("hold_id", 0)
		Global.fail_hold_chain(hold_id)

	note_instance.queue_free()
	if area.get_meta("isRight"):
		r_fx.play("miss")
	else:
		l_fx.play("miss")
