extends Node2D
class_name GravityComponent

@export var jump_gravity: int = 4000;
@export var fall_gravity: int = 4000;

func apply_gravity(actor: CharacterBody2D, delta: float):
	if not actor.is_on_floor():
		if actor.velocity.y < 0:
			actor.velocity.y += jump_gravity * delta
		else:
			actor.velocity.y += fall_gravity * delta
