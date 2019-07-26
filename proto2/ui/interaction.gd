extends Control

var active_npc

func hire_as_team():
	var npc_data: Dictionary = active_npc.get_meta("data")
	var newkey = 0
	var teamkeys = world.team.keys()
	if teamkeys.size() > 0:
		var maxkey = teamkeys.max()
		newkey = maxkey + 1
	if npc_data.gender == 0:
		var dst_node = get_node("/root/main/quest_dst_male_dorm")
		var dst = dst_node.global_transform.origin
		active_npc.walkto(dst)
		world.team[newkey] = npc_data
		print("line: ", world.line.size())
		world.line.erase(npc_data.id)
		npc_data.erase("id")
		print("line2: ", world.line.size())
		npc_data.type = 0
	else:
		var dst_node = get_node("/root/main/quest_dst_female_dorm")
		var dst = dst_node.global_transform.origin
		active_npc.walkto(dst)
		world.team[newkey] = npc_data
		print("line: ", world.line.size())
		world.line.erase(npc_data.id)
		npc_data.erase("id")
		print("line2: ", world.line.size())
		npc_data.type = 0
	hide()
func hire_as_cheer_team():
	hide()
func _ready():
	hide()
	$h/hire_team.connect("pressed", self, "hire_as_team")
	$h/hire_cheer_team.connect("pressed", self, "hire_as_cheer_team")
func start_interaction(npc):
	active_npc = npc
	show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
