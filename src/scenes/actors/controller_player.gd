extends Controller

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("inp_left"):
		left.emit()
	
	if Input.is_action_pressed("inp_right"):
		right.emit()
	
	if Input.is_action_pressed("inp_up"):
		up.emit()
	
	if Input.is_action_pressed("inp_down"):
		down.emit()
	
	if Input.is_action_just_pressed("inp_primary"):
		primary.emit()
	
	if Input.is_action_just_pressed("inp_secondary"):
		secondary.emit()
	
