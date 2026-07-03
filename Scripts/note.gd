extends Sprite2D

@onready var left_end: Node2D = $"../../Left End"
@onready var right_end: Node2D = $"../../Right End"
@onready var parent_position = get_parent().position
@onready var hold_area: Area2D = get_node_or_null("Area2D")

var speed := 0.0
var is_hold_note := false

func _ready():
	var end_position
	if get_parent().name == "Left Holder":
		end_position = left_end.position
	else:
		end_position = right_end.position
	speed = (end_position.y - parent_position.y) / Global.AUDIO_DELAY

	is_hold_note = hold_area != null and hold_area.get_meta("isHold", false)
	if is_hold_note:
		set_meta("is_active_hold", true)
	
func _process(delta: float) -> void:
	self.position.y += speed * delta

func deactivate_hold():
	if !is_hold_note or !get_meta("is_active_hold", true):
		return

	set_meta("is_active_hold", false)
	modulate = Color(0.45, 0.45, 0.45, 0.7)
