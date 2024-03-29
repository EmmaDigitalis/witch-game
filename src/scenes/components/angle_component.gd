extends Node2D
class_name AngleComponent

signal mode(angle)

@export var detection_method: Node
@export var ray_length: int = 350
@export var position_radius: int = 68
@export var base_angle: int = 90
@export var return_to_zero: float = 6.0

@onready var ray_1 = $RayRight
@onready var ray_2 = $RayLeft
@onready var RAYS: Array = [ray_1, ray_2];

func initial_angle(object: Node2D, sprite: Node) -> void:
	switch_mode(base_angle, object)
	object.color_rect.rotation = deg_to_rad(base_angle-90)

func set_angle_to_floor(object: Node2D, sprite: Node, delta) -> void:
	var right = ray_1.get_collision_point()
	var left = ray_2.get_collision_point()
	var floor_angle = left.angle_to_point(right)
	if object.is_on_floor(): 
		sprite.rotation = floor_angle
	else:
		sprite.rotation = move_toward(sprite.rotation, deg_to_rad(0), return_to_zero * delta)

func detect_angle():
	var floor_angle = rad_to_deg(get_parent().get_floor_normal().angle())+90
	
	var simple_angle = round(Global.positive_degree(floor_angle))
#	print("angle")
#	print(simple_angle)
	match base_angle:
		0: #on right wall, 315 to 225 
			if simple_angle > 314:
				mode.emit(90)
			if simple_angle < 226:
				mode.emit(270)
		90: #on the floor,  315 to 0 and 0 to 45
			if simple_angle < 315 and simple_angle > 180:
				mode.emit(0) # to right wall
			if simple_angle > 45 and simple_angle < 180:
				mode.emit(180) # to left wall
		180: #on left wall, 45 to 135
			if simple_angle < 46:
				mode.emit(90)
			if simple_angle > 134:
				mode.emit(270)
		270: #on ceiling, 135 to 225
			if simple_angle < 135:
				mode.emit(180)
			if simple_angle > 226:
				mode.emit(0)
			
	return floor_angle

func switch_mode(new_base_angle: int, object: Node2D) -> void:
	base_angle = new_base_angle
	ray_1.position = Global.lengthdir(position_radius, deg_to_rad(base_angle-90))
	ray_2.position = Global.lengthdir(position_radius, deg_to_rad(base_angle+90))
	var new_direction = Global.lengthdir(ray_length, deg_to_rad(base_angle))
	for i in RAYS.size():
		RAYS[i].target_position = new_direction
	object.up_direction = -new_direction.normalized()
	
