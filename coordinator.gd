extends Node3D

class_name Coordinator

@export var cam: Camera3D = null
@export var spawn_list: Array[SpawnBug] = []
@export var enemy_group_list: Array[EnemyGroup] = []

@export var label_cost: Label
@export var label_remaining: Label

@export var placement_ui: Control
@export var win_ui: Control
@export var lose_ui: Control

@onready var cursor: Node3D = $Cursor
@onready var plane: Node3D = $PlacementPlane
@onready var enemy_origin: Node3D = $EnemyGroupOrigin
@onready var placement_sound: AudioStreamPlayer = $Sounds/PlacementSound


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

var selected_bug := 0
var placement_bug: Bug = null

var remaining_cost := 0
var current_group: EnemyGroup = null


func unregister(bug: Bug) -> void:
	var team: Array[Bug] = teams[bug.team]
	team.erase(bug)
	
func register(bug: Bug) -> void:
	if bug.team not in teams:
		teams[bug.team] = [] as Array[Bug]
	var team: Array[Bug] = teams[bug.team]
	team.push_back(bug)

func select_random_target(bug: Bug, priority: Callable = func(_t: Variant) -> bool: return true) -> void:
	for team_id: int in teams:
		if team_id == bug.team: continue

		var team: Array[Bug] = teams[team_id]
		var prio: Array[Bug] = team.filter(priority)
		if prio:
			team = prio
		if team.is_empty():
			continue
		bug.target = team.pick_random()
		return
		

func to_fight_phase() -> void:
	phase = Phase.Fight
	plane.visible = false
	plane.process_mode = Node.PROCESS_MODE_DISABLED
	cursor.visible = false
	cursor.process_mode = Node.PROCESS_MODE_DISABLED
	placement_ui.visible = false
	for team_id: int in teams:
		var team: Array[Bug] = teams[team_id]
		for team_bug in team:
			team_bug.start()

func to_place_phase() -> void:
	for team_id: int in teams:
		var team: Array[Bug] = teams[team_id]
		for team_bug in team:
			team_bug.queue_free()
		team.clear()

	spawn_next_group()

	placement_ui.visible = true
	win_ui.visible = false
	lose_ui.visible = false
	phase = Phase.Placement
	plane.visible = true
	plane.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.visible = true
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

func to_fight_end_phase(team: int) -> void:
	phase = Phase.FightEnded
	if team == 1:
		win_ui.visible = true
	else:
		enemy_group_list.push_front(current_group)
		lose_ui.visible = true


func spawn_next_group() -> void:
	var next_group: EnemyGroup = enemy_group_list.pop_front()
	current_group = next_group
	if enemy_group_list.is_empty():
		enemy_group_list.push_back(next_group)
	var instance: Node3D = next_group.enemies.instantiate()
	remaining_cost = next_group.allowed_cost
	label_remaining.text = "%d" % remaining_cost
	add_sibling(instance)
	for bug: Bug in instance.get_children():
		instance.remove_child(bug)
		add_sibling(bug)
		bug.global_transform *= enemy_origin.transform
		bug.coord = self
		register(bug)
	instance.queue_free()

func affordable() -> bool:
	return spawn_list[selected_bug].cost <= remaining_cost

func place_bug() -> void:
	if placement_bug == null:
		return
	if spawn_list[selected_bug].cost > remaining_cost:
		return
	placement_sound.play()
	remaining_cost -= spawn_list[selected_bug].cost
	label_remaining.text = "%d" % remaining_cost
	var gtransform := placement_bug.global_transform
	cursor.remove_child(placement_bug)
	add_sibling(placement_bug)
	placement_bug.global_transform = gtransform

	register(placement_bug)
	placement_bug = null
	swap_bug(0)

func swap_bug(offset: int) -> void:
	if placement_bug:
		placement_bug.queue_free()
	var button: Sprite2D = get_node(spawn_list[selected_bug].button)
	button.modulate.a = 0.5

	selected_bug = (selected_bug + offset) % spawn_list.size()
	placement_bug = spawn_list[selected_bug].bug.instantiate()
	label_cost.text = "%d" % spawn_list[selected_bug].cost
	var nbutton: Sprite2D = get_node(spawn_list[selected_bug].button)
	nbutton.modulate.a = 1
	placement_bug.coord = self
	cursor.add_child(placement_bug)

	if !affordable():
		label_cost.label_settings.font_color = Color(1, 0.2, 0.2)
	else:
		label_cost.label_settings.font_color = Color(1, 1, 1)


const RAY_LENGTH = 1000.0
func handle_cursor() -> void:
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

func process_placement() -> void:
	handle_cursor()
	if Input.is_action_just_pressed("start"):
		to_fight_phase()
	if Input.is_action_just_pressed("next_bug"):
		swap_bug(1)
	if Input.is_action_just_pressed("previous_bug"):
		swap_bug(-1)

func process_fight() -> void:
	for team_id: int in teams:
		var team: Array[Bug] = teams[team_id]
		if team.is_empty():
			to_fight_end_phase(team_id)
			return

func process_fight_ended() -> void:
	if Input.is_action_just_pressed("start"):
		to_place_phase()


# Called when the node enters the scene tree for the first time.
func _process(_delta: float) -> void:
	match phase:
		Phase.Init:
			to_place_phase()
			swap_bug(0)
		Phase.Placement: process_placement()
		Phase.Fight: process_fight()
		Phase.FightEnded: process_fight_ended()
