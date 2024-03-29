extends Area2D
class_name HurtboxComponent

## Different types of hurtboxes. They function as follows:
## [br][br][b]Attackable:[/b] can be hit by the player & can hit player. Player will [code]bounce_off[/code] if in attack mode and [code]get_hurt[/code] and [code]lose_mana[/code] if not
## [br][br][b]Routine Counter Increment:[/b] when hit, moves to next state, such as moving a breakable wall from solid to broken
## [br][br][b]Hurt:[/b] when hit, player will [code]get_hurt[/code] and [code]lose_mana[/code]
## [br][br][b]Special:[/b] behaviour of hitbox is determined by specific code, determined by code in [code]SpecialHurtboxComponent[/code]
@export_enum("Attackable:0", "Routine Counter Increment:1", "Hurt:2", "Special:3") var hurtbox_type: int = 0

## Component with code performed when hurtbox is of Special-type
@export var special_hurtbox_component: Node

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass
