extends AnimatedSprite2D

@onready var fx: AnimatedSprite2D = self.get_child(2)

func hit_area():
	if Input.is_action_just_pressed("left note") or Input.is_action_just_pressed("right note"):
		# ensure players have to tap and can't just hold notes
		var overlapping_areas = self.get_child(0).get_overlapping_areas()
		var isPerfect: bool = false
		for area in overlapping_areas:
			if area.get_meta("isPerfect"):
				isPerfect = true
				break
		if isPerfect:
			fx.play("perfect")
			overlapping_areas[0].get_parent().queue_free()
		else:
			fx.play("almost")
			overlapping_areas[0].get_parent().queue_free()
