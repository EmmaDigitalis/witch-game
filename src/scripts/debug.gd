extends Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("inp_debug"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("inp_debug_pause"):
		if Global.playback_speed == 0:
			Global.playback_speed = 1
		else:
			Global.playback_speed = 0

