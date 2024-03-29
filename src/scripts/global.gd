extends Node

@onready var playback_speed = 1;

func cool_delta(delta):
	return delta * playback_speed;

func lengthdir(distance: float, direction: float) -> Vector2:  
	var distance_x = cos(direction) * distance
	var distance_y = sin(direction) * distance
	return Vector2(distance_x, distance_y)

func positive_radian(radian: float) -> float:
	while radian < 0:
		radian += 2*PI
	return radian

func positive_degree(degree: float) -> float:
	while degree < 0:
		degree += 360
	return degree
