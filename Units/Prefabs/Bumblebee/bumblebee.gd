extends Bug
class_name Bumblebee

func process_targeting():
	if !is_instance_valid(target) || target.state != State.Active:
		target = null
	if target == null:
		coord.select_random_target(self, func(t): return t is Bee)
