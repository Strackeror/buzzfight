extends Node3D

@export var cam: Camera3D = null
@export var coord: Coordinator = null
@export var spawn: PackedScene = null


var active: bool = true
var spawned_list: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spawn_instance() -> void:
	var spawned: Bee = spawn.instantiate()
	spawned.transform = self.transform
	spawned.velocity = Vector3.FORWARD
	spawned.coord = coord
	print(spawned)
	add_sibling(spawned)


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
		self.position = intersect["position"] + Vector3.UP * 2
	
	
func _input(event: InputEvent) -> void:
	var mouse_event:= event as InputEventMouseButton
	if !mouse_event:
		return
	if mouse_event.button_index == 1 && mouse_event.pressed:
		spawn_instance()
