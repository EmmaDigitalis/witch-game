extends CharacterBody2D
class_name Actor

@onready var color_rect = $ColorRect

@onready var gravity_component = $GravityComponent
@onready var angle_component = $AngleComponent as AngleComponent
@onready var movement_component = $MovementComponent

@onready var collision_shape_2d = $CollisionShape2D

func _ready():
#	movement_component.set_floor_snapping()
	angle_component.initial_angle(self, color_rect)

func _physics_process(delta):
	if is_on_floor():
		angle_component.set_angle_to_floor(self, color_rect, delta)
		movement_component.move(delta)
		movement_component.jump()
	else:
		movement_component.move(delta)
		gravity_component.apply_gravity(self, delta)
	
	if not is_on_floor():
		up_direction = Vector2(0, -1)
		angle_component.switch_mode(90, self)
	
	move_and_slide()


func _on_angle_component_mode(angle):
	angle_component.switch_mode(angle, self)
	collision_shape_2d.set_rotation_degrees(angle+90)
	print(collision_shape_2d.get_rotation_degrees())
