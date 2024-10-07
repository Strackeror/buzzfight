extends Node3D

class_name Bug

@export var max_speed := 12.0

@export var target_factor := 1.0

@export var center := Vector3.ZERO
@export var center_distance := 15.0
@export var centering_factor := 0.1

@export var threat := 1.0
@export var knockback_factor = 1.5
@export var knockback_time = 0.5
@export var health = 2.0
@export var defense = 0.0
@export var attack = 1.0
@export var attack_knockback = 10

@export var team = 0


@onready var animation_player: AnimationPlayer = $Scene/AnimationPlayer
@onready var detector: Area3D = $Detector
@onready var body: Area3D = $Body


var target: Bug = null
var coord: Coordinator = null

var velocity := Vector3.ZERO
var stun_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func kill():
	state = State.Dead
	queue_free()
	coord.unregister(self)

func die():
	if animation_player:
		animation_player.stop()
	state = State.Dying
	stun_time = 1.0

func knockback(by: Bug):
	var direction = (position - by.position).normalized()
	velocity = direction * by.attack_knockback * knockback_factor
	knockback_timer = knockback_time
	state = State.Knockback
	look_at(by.position)

func start():
	if animation_player:
		animation_player.get_animation("Scene").loop_mode = Animation.LOOP_LINEAR
		animation_player.play("Scene")
	state = State.Active

func hit(by: Bug):
	var dmg = max(0, by.attack - defense)
	health -= dmg
	knockback(by)
	if health <= 0:
		die()
		return

enum State {
	Placed,
	Active,
	Knockback,
	Dying,
	Dead,
}
var state := State.Placed


func process_targeting():
	if !is_instance_valid(target) || target.state != State.Active:
		target = null
	if target == null:
		coord.select_random_target(self)

func process_movement(delta: float):

	# Stay around center
	var center_diff = (center - position)
	if center_diff.length() > center_distance:
		var outside_dist = center_diff.length() - center_distance
		var centering_velocity = (center_diff.normalized() * centering_factor * outside_dist)
		DebugDraw.draw_line_3d(global_position, global_position + centering_velocity, Color(1, 0, 1))
		velocity += centering_velocity

	# Try to follow the target
	if target:
		var target_velocity := (target.position - position).normalized() * target_factor
		DebugDraw.draw_line_3d(global_position, global_position + target_velocity, Color(1, 1, 0))
		velocity += target_velocity

	if velocity.length() > max_speed:
		velocity *= max_speed / velocity.length()

	position += velocity * delta
	if !velocity.is_zero_approx():
		basis = Basis.looking_at(velocity)

func process_collisions():
	var collision_nodes = body.get_overlapping_areas().map(func(t): return t.get_parent())
	var bees_hit: Array[Bug]
	bees_hit.assign(
		collision_nodes
			.filter(func(t: Bug): return (
					t is Bug &&
					t.team != team &&
					t.state == State.Active
				)
			)
	)
	for bee in bees_hit:
		hit(bee)
		bee.hit(self)


func process_active(delta: float):
	process_targeting()
	process_movement(delta)
	process_collisions()

func process_stunned(delta: float):
	stun_time -= delta
	velocity = velocity + Vector3.DOWN * delta * 100
	position += velocity * delta
	look_at(self.position + velocity)
	rotation.z = stun_time * PI * 5
	if stun_time <= 0:
		kill()

var knockback_timer = 0.0
func process_knockback(delta: float):
	knockback_timer -= delta
	if knockback_timer <= 0:
		state = State.Active
	DebugDraw.draw_line_3d(global_position, global_position + velocity, Color(1, 0, 0))
	position += velocity * delta
	rotation.x = (knockback_timer / knockback_time) * -PI * 3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match state:
		State.Active: process_active(delta)
		State.Dying: process_stunned(delta)
		State.Knockback: process_knockback(delta)
