extends Node2D
class_name MovementComponent

@export var angle_component: AngleComponent
@export var max_speed: float = 1000.0
@export var min_speed: float = 100.0
@export var jump_force: float = 2000.0
@export var acceleration: float = 700.0
@export var traction: float = 2000.0
@export var slope_traction: float = 300.0

var speed_x: float = 0
var speed_y: float = 0
var ground_speed: float = 0

func set_floor_snapping() -> void:
	get_parent().floor_snap_length = max_speed / 55

func jump() -> void:
	if Input.is_action_just_pressed("inp_primary") and get_parent().is_on_floor():
		get_parent().velocity.y = -jump_force

func move(delta) -> void:
	var direction = Input.get_axis("inp_left", "inp_right")
	
	if get_parent().is_on_floor():
		if direction:
			ground_speed = move_toward(ground_speed, direction * max_speed, acceleration * delta) 
		else:
			ground_speed = move_toward(ground_speed, 0, traction * delta)
		var ground_angle = angle_component.detect_angle()
		get_parent().velocity = Global.lengthdir(ground_speed, get_parent().get_floor_normal().angle()+deg_to_rad(90))
		queue_redraw()
	else:
		get_parent().velocity.x = move_toward(get_parent().velocity.x, direction * max_speed, acceleration * delta) 

func _draw():
	draw_line(Vector2(0, 0), Global.lengthdir(200, get_parent().get_floor_normal().angle()+deg_to_rad(90)), Color.ROYAL_BLUE, 20)
