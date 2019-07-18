extends Node2D
var nav: Navigation2D
var ball_game
func hire_fire(rname, evt):
	$CanvasLayer/uis/hire_fire.popup()
func start_training(rname, evt):
	if world.training:
		print("stop training")
		ball_game.stop_game()
		ball_game.queue_free()
#		for k in get_tree().get_nodes_in_group("ball"):
#			k.queue_free()
		for k in world.team.keys():
			var ch = world.team[k]
			var dst = $shower_players.global_position + Vector2(randf() * 20.0, randf() * 20.0)
			ch.scene.walkto(dst)
		for k in world.cheer_team.keys():
			var ch = world.cheer_team[k]
			var dst = $shower_cheer.global_position + Vector2(randf() * 20.0, randf() * 20.0)
			ch.scene.walkto(dst)
		world.training = false
		world.next_period()
	else:
		ball_game = BallGameAI.new()
		add_child(ball_game)
		ball_game.set_main(self)
		ball_game.set_ball(load("res://ball.tscn"))
		print("start training")
		for k in world.team.keys():
			var ch = world.team[k]
			ball_game.add_player(randi() % 2, ch)
#			var dst = ball.global_position + Vector2(randf() - 0.5, randf() - 0.5) * 10.0
#			ch.scene.follow(ball)
		var cheer_dst = $gym.global_position + Vector2((randf() - 0.5) * 30.0, (randf() - 0.5) * 30.0)
		var team_point_nodes = [$gym/game_points/team0, $gym/game_points/team1]
		for en in range(team_point_nodes.size()):
			var e = team_point_nodes[en]
			for c in e.get_children():
				if c.name.begins_with("cheer"):
					ball_game.add_cheer_game_location(en, c.global_position)
				elif c.name == "start":
					ball_game.set_team_start(en, c.global_position)
				elif c.name == "gate":
					ball_game.set_team_gate(en, c)
		for k in world.cheer_team.keys():
			var ch = world.cheer_team[k]
			ball_game.add_cheer(randi() % 2, ch)
#			var dst = $gym.global_position + Vector2((randf() - 0.5) * 30.0, (randf() - 0.5) * 30.0)
#			ch.scene.walkto(dst)
		ball_game.start_game()
		world.training = true
func visit_players_dressing(rname, evt):
	pass
func visit_cheer_dressing(rname, evt):
	pass
func visit_players_shower(rname, evt):
	pass
func visit_cheer_shower(rname, evt):
	pass
func visit_players_dormitory(rname, evt):
	pass
func visit_cheer_dormitory(rname, evt):
	pass
func visit_closet(rname, evt):
	pass
func update_day():
	$CanvasLayer/uis/HBoxContainer/day.text = "day: " + str(world.day)
func _ready():
	$office.connect("room_event", self, "hire_fire")
	$gym.connect("room_event", self, "start_training")
	world.connect("next_day", self, "update_day")
	nav = $nav

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if world.training:
		for k in ball_game._scores.keys():
			if ball_game._scores[k] > 10.0:
				start_training("gym", "action1")
			
