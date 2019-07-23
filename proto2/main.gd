extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var frame_tf: Transform = Transform()

func master_control(pos):
	$master.walkto(pos)

func update_quests():
	for q in world.quests:
		if q.is_active():
			$info/task/task.text = q.get_cur_task_text()
			break
	for q in world.quests:
		if q.is_active():
			q.update()
func start_quest(quest: Quest):
	$start_quest_notification.start_notification(quest.get_title(), quest.get_description())

func _ready():
	$master.add_to_group("master")
	controls.master_node = $master
	world.master_node = $master
	world.init_data()
	world.nav = $nav
	controls.camera = $Camera
	controls.connect("user_click", self, "master_control")
	for k in world.line.keys():
		var cd = world.line[k]
		if cd.type == 0:
			var char_sc = characters.characters[0].instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("nav")
			var p = nav.get_closest_point(get_node("line_spawn").global_transform.origin + Vector3(randf() * 20.0 - 10.0, 0.0, randf() * 20 - 10.0))
			char_sc.translation = p
			char_sc.set_meta("data", cd)
#			world.team[newkey] = cd
#			world.line.erase(k)
		else:
			var char_sc = characters.characters[1].instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("nav")
			var p = nav.get_closest_point(get_node("line_spawn").global_transform.origin + Vector3(randf() * 20.0 - 10.0, 0.0, randf() * 20 - 10.0))
			char_sc.translation = p
			char_sc.set_meta("data", cd)
#			world.team[newkey] = cd
#		cd.scene.set_meta("data", cd)
	var tut_quest = Quest.new("Tutorial", "This quest shortly introduces to a game")
	tut_quest.connect("started", self, "start_quest")
	world.quests.push_back(tut_quest)
	tut_quest.start()
	update_quests()
	var quest_timer : = Timer.new()
	quest_timer.wait_time = 2.0
	add_child(quest_timer)
	quest_timer.connect("timeout", self, "update_quests")
	quest_timer.start()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos = $master.global_transform.origin
	pos.y = $Camera.global_transform.origin.y
	$Camera.global_transform.origin = $Camera.global_transform.origin.linear_interpolate(pos, 0.8 * delta)
