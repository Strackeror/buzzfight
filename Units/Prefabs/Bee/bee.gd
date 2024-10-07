extends Bug
class_name Bee

@export var separation_factor := 5.0
@export var alignment_factor := 0.1
@export var cohesion_factor := 1.0


func process_movement(delta):
	var collision_nodes = detector.get_overlapping_areas().map(func(t): return t.get_parent())
	
	var bees_around: Array[Bee]
	bees_around.assign(
		collision_nodes
			.filter(func(t): return (
					t is Bee &&
					t != self &&
					t.team == team
				)
			)
	)
	
	if bees_around.size() > 0:
		var separation_velocity := Vector3.ZERO
		var alignment_velocity := Vector3.ZERO
		var cohesion_position := Vector3.ZERO

		for other in bees_around:
			var diff = position - other.position
			if diff != Vector3.ZERO:
				separation_velocity += diff.normalized() / diff.length()
			alignment_velocity += other.velocity.normalized()
			cohesion_position += other.position

		separation_velocity /= bees_around.size()
		separation_velocity *= separation_factor

		alignment_velocity /= bees_around.size()
		alignment_velocity *= alignment_factor

		cohesion_position /= bees_around.size()
		var cohesion_velocity := (cohesion_position - position).normalized() * cohesion_factor;

		DebugDraw.draw_line_3d(global_position, global_position + separation_velocity, Color(1, 0, 0))
		DebugDraw.draw_line_3d(global_position, global_position + alignment_velocity, Color(0, 1, 0))
		DebugDraw.draw_line_3d(global_position, global_position + cohesion_velocity, Color(0, 0, 1))

		velocity += separation_velocity + alignment_velocity + cohesion_velocity

	super(delta)


