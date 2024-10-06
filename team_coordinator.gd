extends Node3D

class_name Coordinator

@export var cam: Camera3D = null
@export var spawn_list: Array[PackedScene] = []

@onready var cursor: Node3D = $Cursor
@onready var plane: Node3D = $PlacementPlane

enum Phase {
	Placement,
	Fight,
	FightEnded,
}

var phase := Phase.Placement
var teams := {
	0: [] as Array[Bee],
	1: [] as Array[Bee],
}

var selected_bee = -1
var placement_bee: Bee = null

func unregister(bee: Bee):
	var team: Array[Bee] = teams[bee.team]
	team.erase(bee)
	
func register(bee: Bee):
	if bee.team not in teams:
		teams[bee.team] = [] as Array[Bee]
	var team: Array[Bee] = teams[bee.team]
	team.push_back(bee)

func select_random_target(bee: Bee):
	for team_id in teams:
		if team_id == bee.team: continue
		var team: Array[Bee] = teams[team_id]
		var weights: Array[float] = []
		var total = 0.0
		for team_bee in team:
			var threat = team_bee.threat
			if team_bee.state != Bee.State.Active:
				threat = 0
			weights.push_back(total + threat)
			total += threat

		var select = randf_range(0., total)
		var j = 0;
		for w in weights:
			if w > select:
				bee.target = team[j]
				return
			j += 1

func to_fight_phase():
	phase = Phase.Fight
	plane.visible = false
	plane.process_mode = Node.PROCESS_MODE_DISABLED
	cursor.visible = false
	cursor.process_mode = Node.PROCESS_MODE_DISABLED
	
	for team_id in teams:
		var team: Array[Bee] = teams[team_id]
		for team_bee in team:
			team_bee.start()

func to_place_phase():
	for team_id in teams:
		var team: Array[Bee] = teams[team_id]
		for team_bee in team:
			team_bee.queue_free()
		team.clear()

	phase = Phase.Placement
	plane.visible = true
	plane.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.visible = true
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

func to_fight_end_phase():
	phase = Phase.FightEnded

func place_bee():
	if placement_bee == null:
		return
	var gtransform = placement_bee.global_transform
	cursor.remove_child(placement_bee)
	add_sibling(placement_bee)
	placement_bee.global_transform = gtransform

	register(placement_bee)
	placement_bee = null
	swap_bee(0)

func swap_bee(offset: int):
	if placement_bee:
		placement_bee.queue_free()
		placement_bee = null
	selected_bee = selected_bee + offset
	if selected_bee < -1:
		selected_bee = spawn_list.size() - 1
	if selected_bee >= spawn_list.size():
		selected_bee = -1

	if selected_bee >= 0:
		placement_bee = spawn_list[selected_bee].instantiate()
		placement_bee.coord = self
		cursor.add_child(placement_bee)


const RAY_LENGTH = 1000.0
func handle_cursor():
	var pos := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(pos)
	var to := from + cam.project_ray_normal(pos) * RAY_LENGTH
	var space_state := get_world_3d().direct_space_state;
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var intersect := space_state.intersect_ray(query)
	
	if !intersect:
		cursor.hide()
		cursor.process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	cursor.show()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.position = intersect["position"]
	if Input.is_action_just_pressed("place"):
		place_bee()

func process_placement():
	handle_cursor()
	if Input.is_action_just_pressed("start"):
		to_fight_phase()
	if Input.is_action_just_pressed("next_bee"):
		swap_bee(1)
	if Input.is_action_just_pressed("previous_bee"):
		swap_bee(-1)

func process_fight():
	for team_id in teams:
		var team: Array[Bee] = teams[team_id]
		if team.is_empty():
			to_fight_end_phase()
			return

func process_fight_ended():
	if Input.is_action_just_pressed("start"):
		to_place_phase()


# Called when the node enters the scene tree for the first time.
func _process(_delta: float):
	match phase:
		Phase.Placement: process_placement()
		Phase.Fight: process_fight()
		Phase.FightEnded: process_fight_ended()
