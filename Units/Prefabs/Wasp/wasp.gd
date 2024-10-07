extends Bug

class_name Wasp

@export var evasion_chance:= 0.75

func hit(by: Bug):
	if by is Bee && randf() < evasion_chance:
		return
	super(by)

func proces_targeting():
	if !is_instance_valid(target) || target.state != State.Active:
		target = null
	if target == null:
		coord.select_random_target(self, func(t): return t is Bumblebee)

