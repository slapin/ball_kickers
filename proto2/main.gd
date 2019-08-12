extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var frame_tf: Transform = Transform()
var ball_game : BallGameAI3D

func master_control(pos):
	print("walkto: ", pos)
	var n = lerp(world.master_node.get_walk_speed(), 3.8, 0.1)
	world.master_node.set_walk_speed(n)
	$master.walkto(pos)

func update_quests():
	$info/task/task.text = "No active tasks"
	for q in world.quests:
		if q.is_active():
			$info/task/task.text = q.get_cur_task_text()
			break
	for q in world.quests:
		if q.is_active():
			q.update()
func start_quest(quest: Quest):
	notifications.quest_notfication(quest.get_title(), quest.get_description())
	
func start_interaction(obj):
	print("started interaction")
	if obj.is_in_group("characters"):
		$interaction.start_interaction(obj)
	else:
		obj.activate()

func start_training(ball):
	print("start training")
	ball_game = BallGameAI3D.new()
	var t0 = $team0
	var t1 = $team1
	for k in t0.get_children():
		if k.name.begins_with("cheer"):
			ball_game.add_cheer_game_location(0, k.global_transform.origin)
		elif k.name == "start":
			ball_game.set_team_start(0, k.global_transform.origin)
		elif k.name == "gate":
			ball_game.set_team_gate(0, k)
	for k in t1.get_children():
		if k.name.begins_with("cheer"):
			ball_game.add_cheer_game_location(1, k.global_transform.origin)
		elif k.name == "start":
			ball_game.set_team_start(1, k.global_transform.origin)
		elif k.name == "gate":
			ball_game.set_team_gate(1, k)
	var t_start = randi() % 2
	for ch in world.cheer_team.keys():
		assert world.cheer_team[ch] != null
		ball_game.add_cheer(t_start, world.cheer_team[ch])
		t_start ^= 1
	for ch in world.team.keys():
		assert world.team[ch] != null
		ball_game.add_player(t_start, world.team[ch])
		t_start ^= 1
	ball_game.set_ball(ball)
	ball_game.set_main(self)
	add_child(ball_game)
	ball_game.connect("stopped_game", self, "stop_training")
	ball_game.connect("started_game", self, "init_training")
	ball_game.connect("update_score", self, "update_training")
	ball_game.start_game()
func stop_training(score):
	print("score:", score)
	ball_game.queue_free()
	world.team_train_count += 1
	$score.hide()
func init_training(score):
	$score.show()
	$score.release_focus()
	update_training(score)
func update_training(score):
	var v:String = ""
	var sdata = []
	for k in score.keys():
		sdata.push_back("%02d" % (score[k]))
	print("score update = ", score)
	v = PoolStringArray(sdata).join(":")
	$score/v/l.text = v
	$score/v/footer.text = "%.1f seconds left" % (ball_game.max_training_time - ball_game.training_time)
	

func _ready():
	var tstart = $nav/navmesh/level_level
	world.arrow = $Camera/arrow
	var queue = [tstart]
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is StaticBody:
			item.collision_layer = 512
			item.collision_mask = 1 | 512
		for c in item.get_children():
			queue.push_back(c)
	$master.add_to_group("master")
	controls.master_node = $master
	world.master_node = $master
	world.init_data()
	world.nav = $nav
	controls.camera = $Camera
	controls.connect("user_click", self, "master_control")
	for k in world.line.keys():
		var cd = world.line[k]
		if cd.gender == 0:
			var char_sc = characters.characters[0].instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("nav")
			var p = nav.get_closest_point(get_node("line_spawn").global_transform.origin + Vector3(randf() * 20.0 - 10.0, 0.0, randf() * 20 - 10.0))
			char_sc.translation = p
			cd.id = k
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
			cd.id = k
			char_sc.set_meta("data", cd)
#			world.team[newkey] = cd
#		cd.scene.set_meta("data", cd)
	var tut_quest = Quest.new("Tutorial", "This quest shortly introduces to a game")
	tut_quest.connect("started", self, "start_quest")
	world.quests.push_back(tut_quest)
	var tut1_quest = WalkQuest.new("Walk to closet room", "Walk to closet room designated location", get_node("quest_dst_closet"))
	tut1_quest.connect("started", self, "start_quest")
	var tut2_quest = StatsQuest.new("Hire 6 team members", "Hire six team members to start with your team", {"player_count": 6})
	tut2_quest.connect("started", self, "start_quest")
	var tut3_quest = WalkQuest.new("Walk to gym", "Walk to gym designated location", get_node("quest_dst_gym"))
	tut3_quest.connect("started", self, "start_quest")
	var tut4_quest = StatsQuest.new("Train your team once", "Complete your team training once", {"team_train_count": 1})
	tut4_quest.connect("started", self, "start_quest")
	tut1_quest.set_next_quest(tut2_quest)
	tut2_quest.set_next_quest(tut3_quest)
	tut3_quest.set_next_quest(tut4_quest)
	tut_quest.add_child(tut1_quest)
	tut_quest.start()
	update_quests()
	var quest_timer : = Timer.new()
	quest_timer.wait_time = 2.0
	add_child(quest_timer)
	quest_timer.connect("timeout", self, "update_quests")
	quest_timer.start()
	controls.connect("action1", self, "start_interaction")
	world.connect("start_training", self, "start_training")
	$info/task/show_journal.connect("pressed", $quest_journal, "show")
	$score.hide()

func _process(delta):
	var pos = $master.global_transform.origin
	pos.y = $Camera.global_transform.origin.y
	$Camera.global_transform.origin = $Camera.global_transform.origin.linear_interpolate(pos, 0.8 * delta)
	if $score.visible && ball_game != null:
		update_training(ball_game._scores)
