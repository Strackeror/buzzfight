extends Bug
class_name Bumblebee

var separation_factor := 10

func process_targeting():
	if !is_instance_valid(target) || target.state != State.Active:
		target = null
	if target == null:
		coord.select_random_target(self, func(t): return t is Bee)

func process_movement(delta: float) -> void:
	var collision_nodes := detector.get_overlapping_areas().map(func(t: Area3D) -> Node: return t.get_parent())
	
	var bees_around: Array[Bug]
	bees_around.assign(
		collision_nodes
			.filter(func(t: Node) -> bool: return (
					t != self &&
					t.team == team
				)
			)
	)
	
	if bees_around:
		var separation_velocity := Vector3.ZERO
		for other in bees_around:
			var diff := position - other.position
			if diff != Vector3.ZERO:
				separation_velocity += diff.normalized() / diff.length()
		separation_velocity /= bees_around.size()
		separation_velocity *= separation_factor
		velocity += separation_velocity
		#DebugDraw.draw_line_3d(position, position+ separation_velocity, Color(0, 1, 0))
	super(delta)
