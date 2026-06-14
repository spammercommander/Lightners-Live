extends Node

@onready var left_end: Node2D = $"../../Left End"
@onready var right_end: Node2D = $"../../Right End"
@onready var parent_position = get_parent().position
var speed
var direction

func _ready():
	var end_position
	if get_parent().name == "Left Holder":
		end_position = left_end.position
	else:
		end_position = right_end.position
	speed = (end_position.y - parent_position.y) / Global.AUDIO_DELAY
	
func _process(delta: float) -> void:
	self.position.y += speed * delta
