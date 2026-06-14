extends Timer

@onready var label: Label = $"../QuitLabel"
@onready var timer: Timer = $"."
enum transparency {TRANSPARENT, OPAQUE}
var tween: Tween

func _ready():
	label.modulate.a = transparency.TRANSPARENT
	label.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		fade_in()
		timer.start()
	elif Input.is_action_just_released("escape"):
		hide_label()
		timer.stop()

func quit_game():
	get_tree().quit()

func fade_in():
	label.visible = true
	tween = get_tree().create_tween()
	tween.tween_property(label,
		"modulate:a",
		transparency.OPAQUE,
		timer.wait_time)
	tween.play()
	await tween.finished
	tween.kill()

func hide_label():
	tween.kill()
	label.modulate.a = transparency.TRANSPARENT
	label.visible = false
