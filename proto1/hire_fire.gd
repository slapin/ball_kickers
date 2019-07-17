extends WindowDialog

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func build_lists():
	$VBoxContainer/player_list.clear()
	for k in world.line.keys():
		var item_text: String = world.line[k].name
		item_text += " " + world.line[k].lastname
		item_text += " STR: " + str(int(world.line[k].strength * 100.0))
		item_text += " Cost/day: " + str(world.line[k].cost)
		if world.line[k].type == 0:
			item_text += " team"
		else:
			item_text += " cheerleader"
		var idx = $VBoxContainer/player_list.get_item_count()
		$VBoxContainer/player_list.add_item(item_text)
		$VBoxContainer/player_list.set_item_metadata(idx, {"id": k})
	$VBoxContainer/team_list.clear()
	for k in world.team.keys():
		var item_text: String = world.team[k].name
		item_text += " " + world.team[k].lastname
		item_text += " STR: " + str(int(world.team[k].strength * 100.0))
		item_text += " Cost/day: " + str(world.team[k].cost)
		item_text += " team"
		var idx = $VBoxContainer/team_list.get_item_count()
		$VBoxContainer/team_list.add_item(item_text)
		$VBoxContainer/team_list.set_item_metadata(idx, {"id": k, "type": world.team[k].type})
	for k in world.cheer_team.keys():
		var item_text: String = world.cheer_team[k].name
		item_text += " " + world.cheer_team[k].lastname
		item_text += " STR: " + str(int(world.cheer_team[k].strength * 100.0))
		item_text += " Cost/day: " + str(world.cheer_team[k].cost)
		item_text += " cheerleader"
		var idx = $VBoxContainer/team_list.get_item_count()
		$VBoxContainer/team_list.add_item(item_text)
		$VBoxContainer/team_list.set_item_metadata(idx, {"id": k, "type": world.cheer_team[k].type})
func hire_candidate():
	var sel: PoolIntArray = $VBoxContainer/player_list.get_selected_items()
	if sel.size() == 0:
		return
	var idx = sel[0]
	var meta: Dictionary = $VBoxContainer/player_list.get_item_metadata(idx)
	var cd = world.line[meta.id]
	if cd.type == 0:
		var teamkeys = world.team.keys()
		var newkey = 0
		if teamkeys.size() > 0:
			var maxkey = teamkeys.max()
			newkey = maxkey + 1
		var char_sc = load("res://npc_player.tscn").instance()
		cd.scene = char_sc
		get_tree().get_root().add_child(char_sc)
		var nav: Navigation2D = get_node("/root/main/nav")
		var p = nav.get_closest_point(get_node("/root/main/dormitory_players").global_position + Vector2(randf() * 100.0 - 50.0, randf() * 100 - 50.0))
		char_sc.position = p
		world.team[newkey] = cd
		world.line.erase(meta.id)
		build_lists()
		update()
	else:
		var teamkeys = world.cheer_team.keys()
		var newkey = 0
		if teamkeys.size() > 0:
			var maxkey = teamkeys.max()
			newkey = maxkey + 1
		var char_sc = load("res://npc_cheer.tscn").instance()
		cd.scene = char_sc
		get_tree().get_root().add_child(char_sc)
		var nav: Navigation2D = get_node("/root/main/nav")
		var p = nav.get_closest_point(get_node("/root/main/dormitory_cheer").global_position + Vector2(randf() * 100.0 - 50.0, randf() * 100 - 50.0))
		char_sc.position = p
		world.cheer_team[newkey] = cd
		world.line.erase(meta.id)
		build_lists()
		update()
func hire_all():
	for k in world.line.keys():
		var cd = world.line[k]
		if cd.type == 0:
			var teamkeys = world.team.keys()
			var newkey = 0
			if teamkeys.size() > 0:
				var maxkey = teamkeys.max()
				newkey = maxkey + 1
			var char_sc = load("res://npc_player.tscn").instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("/root/main/nav")
			var p = nav.get_closest_point(get_node("/root/main/dormitory_players").global_position + Vector2(randf() * 100.0 - 50.0, randf() * 100 - 50.0))
			char_sc.position = p
			world.team[newkey] = cd
			world.line.erase(k)
		else:
			var teamkeys = world.cheer_team.keys()
			var newkey = 0
			if teamkeys.size() > 0:
				var maxkey = teamkeys.max()
				newkey = maxkey + 1
			var char_sc = load("res://npc_cheer.tscn").instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("/root/main/nav")
			var p = nav.get_closest_point(get_node("/root/main/dormitory_cheer").global_position + Vector2(randf() * 100.0 - 50.0, randf() * 100 - 50.0))
			char_sc.position = p
			world.cheer_team[newkey] = cd
			world.line.erase(k)
		cd.scene.set_meta("data", cd)
	build_lists()
	update()
		
func _ready():
	$VBoxContainer/close.connect("pressed", self, "hide")
	connect("about_to_show", self, "build_lists")
	$VBoxContainer/buttons/hire.connect("pressed", self, "hire_candidate")
	$VBoxContainer/buttons/hire_all.connect("pressed", self, "hire_all")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
