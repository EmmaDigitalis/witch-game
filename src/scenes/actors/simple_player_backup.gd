extends CharacterBody2D

signal mode(angle)

@export_group("Defaults")
@export var ray_length: int = 200
@export var position_radius: int = 65
@export var base_angle_vector: Vector2 = Vector2.DOWN
@export var rotation_smoothing: float = 6.0
#TODO: implement layer switching and visual priority stuff
@export var col_layer: int = 1
@export var visual_priority: String = "high"

@export_group("Player Constants")
@export var max_speed: float = 1000.0
@export var min_speed: float = 100.0
@export var jump_force: float = 2400.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 6000.0
@export var friction: float = 1200.0

@onready var slipdown_speed: float = max_speed * (2.5 / 6)

@export_group("Gravity")
@export var jump_gravity: int = 4000;
@export var fall_gravity: int = 4000;

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
var air_speed: float = 0

var grounded: bool = false
var control_lock: bool = false

func _ready():
	floor_snap_length = 100
	switch_mode(base_angle_vector)
	sprite.rotation = base_angle - (PI / 2)

func _physics_process(delta):
	var d = Global.cool_delta(delta)
	if !control_lock:
		direction = Input.get_axis("inp_left", "inp_right")
		
	if not is_on_floor():
		grounded = false
		switch_mode(Vector2.DOWN)
		ground_speed = 0
		gravity(d)
		air_movement(d)
		sprite.rotation = move_toward(sprite.rotation, 0, rotation_smoothing * d)
		land_on_ceiling()
		air_speed = velocity.y
	else:
		ground_angle = find_angle_alt(ray_down_left, ray_down_right)
		if !grounded:
			if control_lock:
				print("set timer")
				control_lock_timer.start()
			landing(d)
		if direction:
			ground_speed = move_toward(ground_speed, direction * max_speed, acceleration * d) 
		else:
			if ground_speed < max_speed:
				ground_speed = move_toward(ground_speed, 0, friction * d)
			else:
				ground_speed = move_toward(ground_speed, 0, friction * d)
#		sprite.rotation = move_toward(sprite.rotation, ground_angle, 0.06)
		sprite.rotation = ground_angle

		match base_angle_vector:
			Vector2.RIGHT:
				right_wall_movement(d)
			Vector2.DOWN:
				floor_movement(d)
				ledge_detection()
			Vector2.LEFT:
				left_wall_movement(d)
			Vector2.UP:
				ceiling_movement()
		jump()
		slipdown()
	
#	print(velocity)
	move_and_slide()
	queue_redraw()

func _draw():
	var rays = [ray_down_left, ray_down_right, ray_up_left, ray_up_right]
	draw_rays(rays)

# movement while on floor
func floor_movement(delta) -> void:
	
	ground_speed -= slope_factor_normal * -sin(ground_angle) * delta
	velocity.x = ground_speed
	var normal_angle = Global.positive_radian(ground_angle)
	# to right wall
	if normal_angle < deg_to_rad(315) and normal_angle > deg_to_rad(180):
		switch_mode(Vector2.RIGHT)
	#to left wall
	if normal_angle > deg_to_rad(45) and normal_angle < deg_to_rad(180):
		switch_mode(Vector2.LEFT)

# movement while on right wall
func right_wall_movement(delta) -> void:
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
func left_wall_movement(delta) -> void:
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
func ceiling_movement() -> void:
	velocity.x = -ground_speed
	var normal_angle = Global.positive_radian(ground_angle)
	# to right wall
	if normal_angle > deg_to_rad(226):
		switch_mode(Vector2.RIGHT)
	#to left wall
	if normal_angle < deg_to_rad(135):
		switch_mode(Vector2.LEFT)

func slipdown():
	var normal_angle = rad_to_deg(Global.positive_radian(ground_angle))
	if (normal_angle < 315 and normal_angle > 45) and ground_speed < slipdown_speed and !control_lock: 
		print("lock")
		switch_mode(Vector2.DOWN)
		control_lock = true
		ground_speed = 0

#TODO: jump
func jump() -> void:
#	if Input.is_action_just_pressed("inp_primary") and !control_lock:
	if Input.is_action_just_pressed("inp_primary"):
		velocity.y = -jump_force

func landing(delta) -> void:
	var normal_angle = rad_to_deg(Global.positive_radian(ground_angle))
	if (normal_angle > 337 or normal_angle < 23): 
		ground_speed = velocity.x
	elif ((normal_angle > 315 and normal_angle < 337) or (normal_angle < 45 and normal_angle > 23)):
		if mostly_towards(Vector2(velocity.x, air_speed)) == Vector2.DOWN:
			ground_speed = air_speed * 0.25 * sign(sin(ground_angle))
		else:
			ground_speed = velocity.x
	elif ((normal_angle > 270 and normal_angle < 315) or (normal_angle < 90 and normal_angle > 45)):
		if mostly_towards(Vector2(velocity.x, air_speed)) == Vector2.DOWN:
			ground_speed = air_speed * 0.5 * sign(sin(ground_angle))
		else:
			ground_speed = velocity.x
	
	if normal_angle >= 315 or normal_angle <= 45:
		velocity.y = 0
		switch_mode(Vector2.DOWN)
	if normal_angle < 315 and normal_angle > 225:
		velocity.x = 0
		switch_mode(Vector2.RIGHT)
	if normal_angle > 45 and normal_angle < 135:
		velocity.x = 0
		switch_mode(Vector2.LEFT)
		
	grounded = true

#movement permitted to the player when in the air
func air_movement(delta) -> void:
	velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta) 

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
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += jump_gravity * delta
		else:
			velocity.y += fall_gravity * delta

func land_on_ceiling() -> void:
	if is_on_ceiling():
		var collision_angle = find_angle_alt(ray_up_left, ray_up_right)
		if (collision_angle < deg_to_rad(135) or collision_angle > deg_to_rad(225)) and (mostly_towards(Vector2(velocity.x, air_speed)) == Vector2.UP):
			ground_speed = air_speed * sign(sin(collision_angle))
			if collision_angle < deg_to_rad(135):
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


func _on_control_lock_timeout():
	print("unlocking")
	control_lock = false
