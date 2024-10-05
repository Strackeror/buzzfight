extends MeshInstance3D

@export var cam: Camera3D = null
@export var spawn: PackedScene = null

var active: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spawn_instance() -> void:
	var spawned: Node3D = spawn.instantiate()
	add_sibling(spawned)
	spawned.transform = self.transform



const RAY_LENGTH = 1000.0;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var pos := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(pos)
	var to := from + cam.project_ray_normal(pos) * RAY_LENGTH
	var space_state := get_world_3d().direct_space_state;
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var intersect := space_state.intersect_ray(query)
	active = intersect != null
	if intersect:
		self.position = intersect["position"]
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		spawn_instance()

