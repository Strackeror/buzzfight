extends Node3D

class_name Coordinator

var teams: Dictionary

func unregister(bee: Bee):
	var team: Array[Bee] = teams[bee.team]
	team.erase(bee)
	
func register(bee: Bee):
	print(bee)
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

func start():
	for team_id in teams:
		var team: Array[Bee] = teams[team_id]
		for team_bee in team:
			team_bee.start()

var i = 0
# Called when the node enters the scene tree for the first time.
func _process(_delta: float) -> void:
	if i == 0:
		for team_id in teams:
			print(team_id, "-", teams[team_id].size())
	i = (i + 1) % 100
	if Input.is_action_just_pressed("start"):
		start()
	
