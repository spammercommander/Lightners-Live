extends Node2D

func _ready():
	print("Pause successful!")
	
func _process(_delta: float) -> void:
	if Global.GAME_STATE == Global.STATES.PAUSE:
		nav()
			
func nav():
	if Input.is_action_just_pressed("pause_next"):
		print("Next item")
		return
	if Input.is_action_just_pressed("pause_prev"):
		print("Prev item")
		return
	if Input.is_action_just_pressed("escape"):
		pass
