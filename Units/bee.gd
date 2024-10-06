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

@export var center := Vector3.ZERO
@export var center_distance := 15.0
@export var centering_factor := 0.1

@export var team = 0
@export var coord: Coordinator = null


var velocity := Vector3.ZERO
var stun_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func kill():
	state = State.Dead
	queue_free()
	coord.unregister(self)

func stun():
	state = State.Stunned
	stun_time = 1.0

func start():
	state = State.Active


enum State {
	Placed,
	Active,
	Stunned,
	Dead,
}

var state := State.Placed

func process_active(delta: float):
	var collision_nodes = detector.get_overlapping_areas().map(func(t): return t.get_parent())
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
	
	if !is_instance_valid(target) || target.stun_time > 0:
		target = null
	if target == null:
		coord.select_random_target(self)

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

	# Stay around center
	var center_diff = (center - position)
	if center_diff.length() > center_distance:
		var outside_dist = center_diff.length() - center_distance
		var centering_velocity = (center_diff.normalized() * centering_factor * outside_dist)
		DebugDraw.draw_line_3d(global_position, global_position + centering_velocity, Color(1, 0, 1))
		velocity += centering_velocity

	if target:
		var diff := (target.position - position)
		var target_velocity := (target.position - position).normalized() * target_factor
		velocity += target_velocity
		if diff.length_squared() < 1:
			target.stun()

	if velocity.length() > max_speed:
		velocity *= max_speed / velocity.length()

	self.position += velocity * delta
	self.basis = Basis.looking_at(velocity)
	self.rotate_z(stun_time * PI * 5)

func process_stunned(delta: float):
	stun_time -= delta
	self.velocity = self.velocity + Vector3.DOWN * delta * 100
	self.position += velocity * delta
	if stun_time <= 0:
		kill()
		stun_time = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match state:
		State.Active: process_active(delta)
		State.Stunned: process_stunned(delta)
