extends Node3D

@export var detector: Area3D = null
@export var speed: float = 0.0

@export var target: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if target:
		var direction := self.position.direction_to(target.global_position);
		var lookat_transform := Basis.looking_at(direction);
		self.basis = lookat_transform
		self.position += direction * _delta * speed;

	var bees_around := (
		detector
			.get_overlapping_areas()
			.map(func(t: Area3D): t.get_parent_node_3d())
	)
	if Input.is_action_just_pressed("debug"):
		print(bees_around)
