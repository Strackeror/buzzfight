extends Node3D
class_name Bee

@export var detector: Area3D = null
@export var threat := 1.0
@export var target: Bee = null
@export var max_speed := 12.0

@export var separation_factor := 1.0
@export var alignment_factor := 1.0
@export var cohesion_factor := 1.0
@export var target_factor := 1.0

@export var y_min := -3.0
@export var y_max := 8.0
@export var y_factor := 0

@export var center:= Vector3.ZERO
@export var center_distance := 10.0
@export var centering_factor := 0.1

@export var team = 0
@export var coord: Coordinator = null


var velocity := Vector3.ZERO
var stun := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(coord)
	coord.register(self)

func kill():
	queue_free()
	coord.unregister(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var collision_nodes = detector.get_overlapping_areas().map(func(t): return t.get_parent())

	if !is_instance_valid(target) || target.stun > 0:
		target = null
	if target == null:
		coord.select_random_target(self)
	

	var bees_around: Array[Bee]
	bees_around.assign(
		collision_nodes
			.filter(func(t: Bee): return (
					t is Bee &&
					t != self &&
					t.team == self.team
				)
			)
	)

	if stun <= 0:
		if bees_around.size() > 0:
			var separation_velocity := Vector3.ZERO
			var alignment_velocity := Vector3.ZERO
			var cohesion_position := Vector3.ZERO

			for other in bees_around:
				var diff = position - other.position
				separation_velocity += diff.normalized() / diff.length()
				alignment_velocity += other.velocity
				cohesion_position += other.position

			separation_velocity /= bees_around.size()
			separation_velocity *= separation_factor

			alignment_velocity /= bees_around.size()
			alignment_velocity *= alignment_factor

			cohesion_position /= bees_around.size()
			var cohesion_velocity := (cohesion_position - position).normalized() * cohesion_factor;

			velocity += separation_velocity + alignment_velocity + cohesion_velocity
	
		if position.y < y_min:
			velocity += Vector3.UP * y_factor
		if position.y < y_max:
			velocity += Vector3.DOWN * y_factor
		# Stay around center
		var center_diff = (center - position)
		if center_diff.length() > center_distance:
			velocity += (center_diff).normalized() * centering_factor

		# Stay around center
		# var center_dir = (center - global_position)
		# DebugDraw.draw_line_3d(position, position + center_dir.normalized(), Color(1, 1, 0))
		# velocity += center_dir.normalized() * centering_factor * 50

		if target:
			var diff := (target.position - position)
			var target_velocity := (target.position - position).normalized() * target_factor
			velocity += target_velocity
			
			if diff.length_squared() < 1 && target is Bee:
				target.stun = 1.0
				target = null

		if velocity.length() > max_speed:
			velocity *= max_speed / velocity.length()
	else:
		stun -= delta
		self.velocity = self.velocity + Vector3.DOWN * delta * 100
		if stun <= 0:
			kill()
			stun = 1.0
			


	self.position += velocity * delta
	self.basis = Basis.looking_at(velocity)
	self.rotate_z(stun * PI * 5)
