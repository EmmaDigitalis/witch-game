extends CharacterBody2D

signal mode(angle)

@export_group("Defaults")
@export var ray_length: int = 250
@export var position_radius: int = 65
@export var base_angle_vector: Vector2 = Vector2.DOWN
@export var rotation_smoothing: float = 6.0
#TODO: implement layer switching and visual priority stuff
@export var col_layer: int = 1
@export var visual_priority: String = "high"

@export_group("Player Constants")
@export var max_speed: float = 2400.0
@export var jump_force: float = 2800.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 3000.0
@export var friction: float = 1200.0
@export var air_acceleration: int = 2400

@onready var slipdown_threshold: float = 200

@export_group("Gravity")
@export var jump_gravity: int = 7000
@export var fall_gravity: int = 5000
@export var max_fall_speed: int = 2400

@onready var ray_down_right = $RayDownRight
@onready var ray_down_left = $RayDownLeft
@onready var ray_up_left = $RayUpLeft
@onready var ray_up_right = $RayUpRight

@onready var control_lock_timer = $ControlLock

@onready var sprite = $ColorRect
@onready var hitbox = $CollisionShape2D
@onready var base_angle = base_angle_vector.angle()

const slope_factor_normal: float = 1700.0
const slope_factor_rolling_up: float = 2000.0
const slope_factor_rolling_down: float = 8000.0

var speed_x: float = 0
var speed_y: float = 0
var ground_speed: float = 0
var ground_angle: float = 0
var direction: float = 0
var last_speed: Vector2 = Vector2.ZERO
var current_speed: Vector2 = Vector2.ZERO

var grounded: bool = false
var control_lock: bool = false


#general
func _ready():
	switch_mode(base_angle_vector)
	sprite.rotation = base_angle - (PI / 2)

func _physics_process(delta):
	var d = Global.cool_delta(delta)
	direction = Input.get_axis("inp_left", "inp_right")
		
	if grounded:
		state_on_ground(d)
	else:
		state_air(d)
	queue_redraw() #redraws draw thing, which handles some debug lines and shit

func _draw():
	var rays = [ray_down_left, ray_down_right, ray_up_left, ray_up_right]
	draw_rays(rays)
	if not control_lock_timer.is_stopped():
		$Label.text = str(control_lock_timer.time_left)
	else:
		$Label.text = "0"



#states
func state_on_ground(delta):
	start_control_lock_timer()
	set_ground_angle()
	set_ground_speed(delta)
	ground_movement(delta)
	falling_and_slipping()
	jump()
	move_and_slide()
	wall_speed_loss()
	ground_check()

func state_air(delta):
	sprite.rotation = move_toward(sprite.rotation, 0, rotation_smoothing * delta) #TODO: replace with jump animation
	gravity(delta)
	air_movement(delta)
	set_last_speed()
	move_and_slide()
	wall_speed_loss()
#	var collision = move_and_collide(velocity * delta)
	landing()







#functions
func ground_movement(delta):
	match base_angle_vector:
		Vector2.RIGHT:
			move_on_right_wall(delta)
		Vector2.DOWN:
			move_on_floor(delta)
			ledge_detection()
		Vector2.LEFT:
			move_on_left_wall(delta)
		Vector2.UP:
			move_on_ceiling()
#	if not is_on_floor():
#		leave_ground()

# movement while on floor
func move_on_floor(delta) -> void:
	if direction or control_lock:
		ground_speed -= slope_factor_normal * -sin(ground_angle) * delta
	velocity.x = ground_speed
	var normal_angle = round(rad_to_deg(Global.positive_radian(ground_angle)))
	# to right wall
	if normal_angle <= 315 and normal_angle > 180:
		switch_mode(Vector2.RIGHT)
	#to left wall
	if normal_angle >= 45 and normal_angle < 180:
		switch_mode(Vector2.LEFT)

# movement while on right wall
func move_on_right_wall(delta) -> void:
	if direction or control_lock:
		ground_speed -= slope_factor_normal * -sin(ground_angle) * delta
	velocity.y = -ground_speed
	var normal_angle = Global.positive_radian(ground_angle)
	# to floor
	if normal_angle > deg_to_rad(316):
		switch_mode(Vector2.DOWN)
	#to ceiling
	if normal_angle < deg_to_rad(224):
		switch_mode(Vector2.UP)

# movement while on left wall
func move_on_left_wall(delta) -> void:
	if direction or control_lock:
		ground_speed -= slope_factor_normal * -sin(ground_angle) * delta
	velocity.y = ground_speed
	var normal_angle = Global.positive_radian(ground_angle)
	# to floor
	if normal_angle < deg_to_rad(46):
		switch_mode(Vector2.DOWN)
	#to ceiling
	if normal_angle > deg_to_rad(134):
		switch_mode(Vector2.UP)

# movement while on ceiling
func move_on_ceiling() -> void:
	velocity.x = -ground_speed
	var normal_angle = Global.positive_radian(ground_angle)
	# to right wall
	if normal_angle > deg_to_rad(226):
		switch_mode(Vector2.RIGHT)
	#to left wall
	if normal_angle < deg_to_rad(135):
		switch_mode(Vector2.LEFT)
 
func jump() -> void:
#	if Input.is_action_just_pressed("inp_primary") and !control_lock:
	if Input.is_action_just_pressed("inp_primary"):
		var absolute_speed = Global.lengthdir(ground_speed, ground_angle)
		velocity.x = absolute_speed.x + jump_force * sin(Global.positive_radian(ground_angle))
		velocity.y = absolute_speed.y - jump_force * cos(Global.positive_radian(ground_angle))
		leave_ground()
		control_lock = false

#movement permitted to the player when in the air
func air_movement(delta) -> void:
	if direction:
		if abs(velocity.x) < max_speed:
			velocity.x += direction * air_acceleration * delta
	if (velocity.y < 0 and velocity.y > -1800):
		velocity.x -= (snapped((velocity.x / 0.125), 1) / 4) * delta

func set_ground_angle():
	ground_angle = find_angle_alt(ray_down_left, ray_down_right)
	sprite.rotation = ground_angle

func set_ground_speed(delta):
	if !control_lock:
		if direction:
			if sign(ground_speed) != direction:
				ground_speed += direction * deceleration * delta
				if ((ground_speed * -direction) <= 0):
					ground_speed = (max_speed * direction) / 10
			elif (abs(ground_speed) < max_speed): 
				ground_speed += direction * acceleration * delta
				if (abs(ground_speed) > max_speed):
					ground_speed = max_speed * direction
		else:
			if ground_speed < max_speed:
				ground_speed -= min(abs(ground_speed), friction * delta) * sign(ground_speed)

func leave_ground():
	grounded = false
	ground_speed = 0
	switch_mode(Vector2.DOWN)

func ground_check():
	if not ray_down_left.is_colliding() and not ray_down_right.is_colliding():
		leave_ground()

func find_angle() -> float:
	var right = ray_down_right.get_collision_point()
	var left = ray_down_left.get_collision_point()
	return left.angle_to_point(right) 

func find_angle_alt(left_ray: RayCast2D, right_ray: RayCast2D) -> float:
	var len_right = right_ray.global_position.distance_to(right_ray.get_collision_point())
	var len_left = left_ray.global_position.distance_to(left_ray.get_collision_point())
	if len_left > len_right:
		return right_ray.get_collision_normal().angle()+(PI/2)
	else:
		return left_ray.get_collision_normal().angle()+(PI/2)

func ledge_detection() -> void:
	var right = ray_down_right.is_colliding()
	var left = ray_down_left.is_colliding()
	if right != left && velocity == Vector2.ZERO:
		sprite.color = Color.CORNFLOWER_BLUE
	else:
		sprite.color = Color.HOT_PINK

func gravity(delta: float) -> void:
	if velocity.y < max_fall_speed:
		if velocity.y < 0:
			velocity.y += jump_gravity * delta
		else:
			velocity.y += fall_gravity * delta
	else:
		velocity.y = max_fall_speed

func set_last_speed():
	last_speed = velocity

func landing():
	if get_last_slide_collision():
		if round(rad_to_deg(get_last_slide_collision().get_angle())) < 90:
			land_on_floor()
		else:
			land_on_ceiling()

func land_on_floor() -> void:
	var collision_angle = round(rad_to_deg(Global.positive_radian(find_angle_alt(ray_down_left, ray_down_right))))
	if (collision_angle >= 315 or collision_angle <= 45):
		if (collision_angle > 337) or (collision_angle < 23):
			ground_speed = last_speed.x
		else:
			if mostly_towards(last_speed) == Vector2.LEFT or mostly_towards(last_speed) == Vector2.RIGHT:
				ground_speed = last_speed.x
			else:
				ground_speed = last_speed.y * 0.5 * sign(sin(deg_to_rad((collision_angle))))
		switch_mode(Vector2.DOWN)
	else:
		ground_speed = last_speed.y * sign(sin(deg_to_rad((collision_angle))))
		if collision_angle < 180:
			switch_mode(Vector2.LEFT)
		else:
			switch_mode(Vector2.RIGHT)
	grounded = true
	ground_angle = deg_to_rad(collision_angle)

func land_on_ceiling() -> void:
	var collision_angle = round(rad_to_deg(Global.positive_radian(find_angle_alt(ray_up_left, ray_up_right))))
	if ((collision_angle < 135 and collision_angle > 95) or (collision_angle > 225 and collision_angle < 185)) and mostly_towards(last_speed) == Vector2.UP:
		grounded = true
		ground_speed = last_speed.y * sign(sin(deg_to_rad(collision_angle)))
		if collision_angle < 135:
			switch_mode(Vector2.LEFT)
		else:
			switch_mode(Vector2.RIGHT)

#switches what mode the player is currently in, to UP, DOWN, LEFT or RIGHT
func switch_mode(new_direction: Vector2) -> void:
	base_angle_vector = new_direction
	base_angle = new_direction.angle()
	#spreads rays along new rotation
	#also points rays in new direction
	var p = -1
	var RAYS = [ray_down_right, ray_down_left, ray_up_right, ray_up_left]
	var i = 0
	while i < 2:
		RAYS[i].position = Global.lengthdir(position_radius, base_angle+((PI / 2) * p))
		RAYS[i].target_position = new_direction * ray_length
		
		RAYS[i+2].position = Global.lengthdir(position_radius, base_angle+((PI / 2) * p))
		RAYS[i+2].target_position = -new_direction * ray_length
		p += 2
		i += 1
	#reset hitbox
	hitbox.rotation = base_angle - (PI / 2)
	#sets new up direction for player, which determines what counts as walls, floors and ceilings
	up_direction = -new_direction
	
func falling_and_slipping():
	var collision_angle = round(rad_to_deg(Global.positive_radian(ground_angle)))
	if collision_angle <= 315 and collision_angle >= 45:
		if abs(ground_speed) < slipdown_threshold:
			if collision_angle <= 270 and collision_angle >= 90:
				leave_ground()
			else:
				control_lock = true

func wall_speed_loss():
	if is_on_wall():
		ground_speed = 0;

func mostly_towards(vector) -> Vector2:
	return vector.normalized().round()

func draw_rays(rays: Array) -> void:
	var colors = [Color.SPRING_GREEN, Color.CYAN, Color.BLUE, Color.YELLOW]
	for i in rays.size():
		draw_line(rays[i].position, rays[i].position+rays[i].target_position, colors[i], 10)
		if rays[i].is_colliding():
			draw_circle(rays[i].get_collision_point() - position, 12, Color.RED)
		else:
			draw_circle(rays[i].position+rays[i].target_position, 12, Color.RED)

func start_control_lock_timer():
	if control_lock == true and control_lock_timer.is_stopped(): 
		control_lock_timer.start()

func _on_control_lock_timeout():
	var collision_angle = round(rad_to_deg(Global.positive_radian(ground_angle)))
	if collision_angle <= 315 and collision_angle >= 45:
		control_lock_timer.start()
	else:
		control_lock = false
