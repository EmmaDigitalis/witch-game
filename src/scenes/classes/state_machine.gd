extends Node
class_name StateMachine

@export var state: State

func _ready():
	change_state(state)

func change_state(new_state: State):
	state.leave_state()
	new_state.set_state()
	state = new_state
