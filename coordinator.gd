extends Node3D

class_name Coordinator

@export var cam: Camera3D = null
@export var spawn_list: Array[PackedScene] = []
@export var enemy_group_list: Array[PackedScene] = []

@onready var cursor: Node3D = $Cursor
@onready var plane: Node3D = $PlacementPlane
@onready var enemy_origin: Node3D = $EnemyGroupOrigin

enum Phase {
	Init,
	Placement,
	Fight,
	FightEnded,
}

var phase := Phase.Init
var teams := {
	0: [] as Array[Bug],
	1: [] as Array[Bug],
}

var selected_bug = 0
var placement_bug: Bug = null


func unregister(bug: Bug):
	var team: Array[Bug] = teams[bug.team]
	team.erase(bug)
	
func register(bug: Bug):
	if bug.team not in teams:
		teams[bug.team] = [] as Array[Bug]
	var team: Array[Bug] = teams[bug.team]
	team.push_back(bug)

func select_random_target(bug: Bug, priority: Callable = func(_t): return true):
	for team_id in teams:
		if team_id == bug.team: continue

		var team: Array[Bug] = teams[team_id]
		var prio = team.filter(priority)
		if prio:
			team = prio
		if team.is_empty():
			continue
		bug.target = team.pick_random()
		return
		
		

func to_fight_phase():
	phase = Phase.Fight
	plane.visible = false
	plane.process_mode = Node.PROCESS_MODE_DISABLED
	cursor.visible = false
	cursor.process_mode = Node.PROCESS_MODE_DISABLED
	
	for team_id in teams:
		var team: Array[Bug] = teams[team_id]
		for team_bug in team:
			team_bug.start()

func to_place_phase():
	for team_id in teams:
		var team: Array[Bug] = teams[team_id]
		for team_bug in team:
			team_bug.queue_free()
		team.clear()

	spawn_next_group()

	phase = Phase.Placement
	plane.visible = true
	plane.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.visible = true
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

func to_fight_end_phase():
	phase = Phase.FightEnded


func spawn_next_group():
	var next_group: PackedScene = enemy_group_list.pop_front()
	var instance: Node3D = next_group.instantiate()
	add_sibling(instance)
	for bug in instance.get_children():
		var bug_node: Bug = bug
		instance.remove_child(bug)
		add_sibling(bug)
		bug_node.global_transform *= enemy_origin.transform
		bug_node.coord = self
		register(bug)
	instance.queue_free()

func place_bug():
	if placement_bug == null:
		return
	var gtransform = placement_bug.global_transform
	cursor.remove_child(placement_bug)
	add_sibling(placement_bug)
	placement_bug.global_transform = gtransform

	register(placement_bug)
	placement_bug = null
	swap_bug(0)

func swap_bug(offset: int):
	if placement_bug:
		placement_bug.queue_free()
	selected_bug = (selected_bug + offset) % spawn_list.size()
	placement_bug = spawn_list[selected_bug].instantiate()
	placement_bug.coord = self
	cursor.add_child(placement_bug)


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
		place_bug()

func process_placement():
	handle_cursor()
	if Input.is_action_just_pressed("start"):
		to_fight_phase()
	if Input.is_action_just_pressed("next_bug"):
		swap_bug(1)
	if Input.is_action_just_pressed("previous_bug"):
		swap_bug(-1)

func process_fight():
	for team_id in teams:
		var team: Array[Bug] = teams[team_id]
		if team.is_empty():
			to_fight_end_phase()
			return

func process_fight_ended():
	if Input.is_action_just_pressed("start"):
		to_place_phase()


# Called when the node enters the scene tree for the first time.
func _process(_delta: float):
	match phase:
		Phase.Init: 
			swap_bug(0)
			to_place_phase()
		Phase.Placement: process_placement()
		Phase.Fight: process_fight()
		Phase.FightEnded: process_fight_ended()
