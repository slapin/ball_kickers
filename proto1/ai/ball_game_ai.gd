extends Node
class_name BallGameAI

var _ball: PackedScene
var _cheers = {}
var _game_area: Rect2
var _teams = {}
var _main
var _state = STATE_INIT
var _ball_instance
var _cheer_locations = {}
var _team_start = {}
var _ball_carrier = null
var _ball_team = -1
var ch2team: Dictionary = {}
var gate2team = {}
var _gates = {}
var _scores = {}

enum {STATE_INIT, STATE_START, STATE_RUNNING, STATE_FINISH}
func _ready():
	_game_area = Rect2()
func set_ball(ball: PackedScene):
	_ball = ball
func add_player(team: int, pl: Dictionary):
	if !_teams.has(team):
		_teams[team] = [pl]
	else:
		_teams[team].push_back(pl)
	assert pl != null
	ch2team[pl.scene] = team
func add_cheer(team: int, ch: Dictionary):
	if !_cheers.has(team):
		_cheers[team] = [ch]
	else:
		_cheers[team].push_back(ch)
	assert ch != null
	ch2team[ch.scene] = team
func add_cheer_game_location(team: int, loc: Vector2):
	if !_cheer_locations.has(team):
		_cheer_locations[team] = [loc]
	else:
		_cheer_locations[team].push_back(loc)
	_game_area = _game_area.expand(loc)
func set_team_start(team: int, v: Vector2):
	_team_start[team] = v
	_game_area = _game_area.expand(v)
func set_team_gate(team: int, gate: Area2D):
	_gates[team] = gate
	gate2team[gate] = team
	gate.connect("body_entered", self, "check_goal", [gate])
	_game_area = _game_area.expand(gate.global_position)
func set_main(n):
	_main = n
func start_game():
	var ball = _ball.instance()
	_main.add_child(ball)
	ball.global_position = world.master_node.global_position + Vector2(randf() - 0.5, randf() - 0.5) * 20.0
	ball.add_to_group("ball")
	_state = STATE_START
	for t in _teams.keys():
		for ch in _teams[t]:
			ch.scene.walkto(_team_start[t])
	var loc = 0
	for t in _cheers.keys():
		for ch in _cheers[t]:
			ch.scene.walkto(_cheer_locations[t][loc % _cheer_locations[t].size()])
			loc += 1
	_ball_instance = ball
	for t in _teams.keys():
		_scores[t] = 0
func stop_game():
	for k in get_tree().get_nodes_in_group("ball"):
		k.queue_free()
	_state = STATE_INIT
	var max_score = -1
	var winner_team = -1
	for k in _scores.keys():
		if _scores[k] > max_score:
			max_score = _scores[k]
			winner_team = k
	for e in _teams[winner_team]:
		world.increase_xp(e, min(e.xp * 2, min(100 * e.level, 1000)))
	for e in _cheers[winner_team]:
		world.increase_xp(e, min(e.xp * 2, min(200 * e.level, 2000)))

var base_speed = 300.0
func striker(ch: Dictionary, delta: float) -> Vector2:
	var velocity: Vector2 = Vector2()
	var dir = Vector2()
	if _ball_carrier == null:
		dir = _ball_instance.global_position - ch.scene.global_position
	else:
		dir = _ball_carrier.scene.global_position - ch.scene.global_position
	velocity = dir.normalized() * base_speed * ch.speed
	return velocity
func avoid(ch: Dictionary, delta: float) -> Vector2:
	var velocity: Vector2 = Vector2()
	var vel_plus = Vector2()
	var team = ch2team[ch.scene]
	var ch_pos = ch.scene.global_position
	for t in _teams.keys():
		if t == team:
			continue
		for other in _teams[t]:
			var opos = other.scene.global_position
			var lvec = ch_pos - opos
			vel_plus += lvec
	velocity = vel_plus.normalized() * base_speed * ch.speed * (1.0 + ch.agression)
	return velocity
func attack_gate(ch: Dictionary, delta: float) -> Vector2:
	var velocity: Vector2 = Vector2()
	var team = ch2team[ch.scene]
	var dir = _gates[team ^ 1].global_position - ch.scene.global_position
	if dir.length() > 80:
		velocity = dir.normalized() * base_speed * ch.speed * (1.0 + ch.agression)
	elif dir.length() > 40:
		velocity = dir.normalized() * base_speed * ch.speed * 0.6 * (1.0 + ch.agression)
	elif dir.length() > 25:
		velocity = dir.normalized() * base_speed * ch.speed * 0.25 * (1.0 + ch.agression)
	return velocity
	
var catch_delay = 0.0
func catch_ball(pl):
	_ball_instance.kinematic = true
	_ball_instance.new_parent = pl.scene
	_ball_instance.update = true
	_ball_instance.impulse = Vector2()
	_ball_carrier = pl
var max_imp = 500.0
func drop_ball(pl):
	assert _main != null
	_ball_instance.kinematic = false
	_ball_instance.new_parent = _main
	_ball_instance.update = true
	_ball_instance.impulse = _ball_carrier.scene.velocity * _ball_instance.mass * (1.5 + randf() * 10.0)
	if _ball_instance.impulse.length() > max_imp:
		_ball_instance.impulse = _ball_instance.impulse.normalized() * max_imp
	_ball_carrier = null
func check_goal(body, gate):
	print("check")
	if _state == STATE_RUNNING:
		var team = gate2team[gate]
		if body is RigidBody2D:
			if body == _ball_instance:
				_scores[team] += 1
		elif body is KinematicBody2D && _ball_carrier != null:
			print("check2")
			if body == _ball_carrier.scene:
				world.increase_xp(_ball_carrier, 150)
				_scores[team] += 1
				catch_delay += 3.0
				drop_ball(_ball_carrier)
		print(_scores)
func colliding(delta):
	var close_distance2 = 450.0
	var chars = {}
	for t in _teams.keys():
		for e in _teams[t]:
			chars[e.scene] = e
	for t in _cheers.keys():
		for e in _cheers[t]:
			chars[e.scene] = e
	for p in chars.keys():
		var pos1 = chars[p].scene.global_position
		var v1 = chars[p].scene.velocity
		var strength = chars[p].strength
		if chars[p] == _ball_carrier:
			strength *= 5.0
		for m in chars.keys():
			if p == m:
				continue
			var pos2 = chars[m].scene.global_position
			var dist = pos1.distance_squared_to(pos2)
			var v2 = chars[m].scene.velocity
			if dist < close_distance2:
				if v1.dot(v2) < 0:
					if strength > chars[m].strength:
						chars[p].scene.velocity = chars[p].scene.velocity.linear_interpolate((v1 + v2) * 0.5, delta)
						chars[m].scene.velocity = chars[p].scene.velocity.linear_interpolate((v1 + v2) * 0.5, delta)
					else:
						chars[p].scene.velocity = Vector2()
				elif v1.dot(v2) >= 0:
					if v1.length() > v2.length():
						if strength > chars[m].strength:
							chars[p].scene.velocity = chars[p].scene.velocity.linear_interpolate((v1 + v2) * 0.5, delta)
							chars[m].scene.velocity = chars[p].scene.velocity.linear_interpolate((v1 + v2) * 0.5, delta)

var start_delay = 15.0
func _process(delta):
	match(_state):
		STATE_INIT:
			pass
		STATE_START:
			var ok_to_run = true
			for c in _teams.keys():
				for pl in _teams[c]:
					var ppos = pl.scene.global_position
					var bpos = _team_start[c]
					if ppos.distance_to(bpos) < 40:
						pl.scene.state = pl.scene.STATE_CONTROL
					elif ppos.distance_to(bpos) > 60 && pl.scene.state != pl.scene.STATE_CONTROL:
						ok_to_run = false
			if ok_to_run:
				_state = STATE_RUNNING
				for c in _teams.keys():
					for pl in _teams[c]:
						pl.scene.state = pl.scene.STATE_CONTROL
			else:
				if start_delay < 0.0:
					for c in _teams.keys():
						for pl in _teams[c]:
							var ppos = pl.scene.global_position
							var bpos = _team_start[c]
							if ppos.distance_to(bpos) > 60 && pl.scene.state != pl.scene.STATE_CONTROL:
								pl.scene.global_position = _team_start[c]
					for c in _cheers.keys():
						for pl in _cheers[c]:
							var ppos = pl.scene.global_position
							var bpos = pl.scene.destination
							if ppos.distance_to(bpos) > 60 && pl.scene.state != pl.scene.STATE_CONTROL:
								pl.scene.global_position = _team_start[c]
				else:
					start_delay -= delta
		STATE_RUNNING:
			for c in _teams.keys():
				for pl in _teams[c]:
					assert pl.scene != null
					if !_ball_carrier || (pl != _ball_carrier && _ball_team != c):
						var velocity = striker(pl, delta)
						velocity = pl.scene.velocity.linear_interpolate(velocity, 0.3 * delta)
#						velocity = pl.scene.move_and_slide(velocity)
						pl.scene.velocity = velocity
					elif _ball_carrier && _ball_carrier == pl:
						var velocity = avoid(pl, delta) * 0.3 + attack_gate(pl, delta) * 0.7
						velocity = pl.scene.velocity.linear_interpolate(velocity, 0.6 * delta)
#						velocity = pl.scene.move_and_slide(velocity)
						pl.scene.velocity = velocity
					if _ball_carrier == null && pl.scene.global_position.distance_squared_to(_ball_instance.global_position) < 350 * (1.0 + pl.agression):
						if catch_delay <= 0.0:
							catch_ball(pl)
							_ball_team = c
							world.increase_xp(pl, 50)
					elif _ball_carrier && pl != _ball_carrier && pl.scene.global_position.distance_squared_to(_ball_carrier.scene.global_position) < 350 * (1.0 + pl.agression):
						if pl.strength * (1.0 + pl.agression) > _ball_carrier.strength * 1.2 * (1.0 + _ball_carrier.agression):
							world.increase_xp(pl, 50)
							drop_ball(_ball_carrier)
							catch_delay += 5.0
			colliding(delta)
			for c in _teams.keys():
				for pl in _teams[c]:
					pl.scene.velocity = pl.scene.move_and_slide(pl.scene.velocity + Vector2(randf() - 0.5, randf() - 0.5) * 3.0)
			if !_game_area.has_point(_ball_instance.global_position):
				if !_ball_carrier:
					_ball_instance.queue_free()
					_ball_instance = _ball.instance()
					_main.add_child(_ball_instance)
					_ball_instance.global_position = world.master_node.global_position + Vector2(randf() - 0.5, randf() - 0.5) * 20.0
					_ball_instance.add_to_group("ball")
					catch_delay += 5.0
				else:
					drop_ball(_ball_carrier)
					catch_delay += 5.0
			if catch_delay > 0.0:
				catch_delay -= delta
