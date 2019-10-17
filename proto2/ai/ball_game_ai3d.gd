extends Node
class_name BallGameAI3D
signal started_game
signal stopped_game
signal update_score

var _cheers = {}
var _game_area: AABB
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
var _speeds = {}
var training_time = 0.0
const max_training_time: float = 180.0
const max_score: int = 6

enum {STATE_INIT, STATE_START, STATE_RUNNING, STATE_GOAL, STATE_FINISH}
func _ready():
	_game_area = AABB()

func set_ball(ball: Node):
	_ball_instance = ball

func add_player(team: int, pl: Dictionary):
	if !_teams.has(team):
		_teams[team] = [pl]
	else:
		_teams[team].push_back(pl)
	assert(pl != null)
	ch2team[pl.scene] = team
func add_cheer(team: int, ch: Dictionary):
	if !_cheers.has(team):
		_cheers[team] = [ch]
	else:
		_cheers[team].push_back(ch)
	assert(ch != null)
	ch2team[ch.scene] = team
func add_cheer_game_location(team: int, loc: Vector3):
	if !_cheer_locations.has(team):
		_cheer_locations[team] = [loc]
	else:
		_cheer_locations[team].push_back(loc)
	_game_area = _game_area.expand(loc)
func set_team_start(team: int, v: Vector3):
	_team_start[team] = v
	_game_area = _game_area.expand(v)
func check_goal(body, gate):
	if _state in [STATE_RUNNING, STATE_GOAL]:
		var team = gate2team[gate]
		if body is RigidBody:
			if body == _ball_instance:
				_scores[team ^ 1] += 1
				emit_signal("update_score", _scores)
		elif body is KinematicBody && _ball_carrier != null:
			if body == _ball_carrier.scene:
				world.increase_xp(_ball_carrier, 150)
				_scores[team] += 1
				emit_signal("update_score", _scores)
				catch_ball_delay += 3.0
				_ball_carrier.scene.drop_object(_ball_instance)
				_ball_instance.apply_impulse(Vector3(), Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 10000.0)
				_ball_carrier = null
				_ball_team = -1
				if _state == STATE_GOAL:
					_state = STATE_RUNNING
		print("score: ", _scores)
		var max_team_score = -1
		for k in _scores.keys():
			if _scores[k] > max_team_score:
				max_team_score = _scores[k]
		if max_team_score >= max_score:
			_state = STATE_FINISH

func set_team_gate(team: int, gate: Area):
	_gates[team] = gate
	gate2team[gate] = team
	gate.connect("body_entered", self, "check_goal", [gate])
	var o : = gate.global_transform.origin
	_game_area = _game_area.expand(o)
func set_main(n):
	_main = n
var start_timeout = 10.0
func start_game():
	var ball = _ball_instance
	ball.add_to_group("ball")
	_state = STATE_START
	for t in _teams.keys():
		for ch in _teams[t]:
			assert(ch != null)
			print(ch)
			assert(ch.scene != null)
			print("start: ", _team_start[t])
			ch.scene.walkto(_team_start[t] + Vector3(randf() * 2.0 - 1.0, 0.0, randf() * 2.0 - 1.0),  1.0 + ch.speed + randf() * ch.speed * 0.5)
			start_timeout = 10.0
	var loc = 0
	for t in _cheers.keys():
		for ch in _cheers[t]:
			assert(ch != null)
			print(ch)
			assert(ch.scene != null)
			ch.scene.walkto(_cheer_locations[t][loc % _cheer_locations[t].size()], 1.0 + ch.speed + randf() * ch.speed * 0.5)
			loc += 1
	for t in _teams.keys():
		_scores[t] = 0
	emit_signal("started_game", _scores)
func stop_game():
#	for k in get_tree().get_nodes_in_group("ball"):
#		k.queue_free()
	_state = STATE_INIT
	var max_score = -1
	var winner_team = -1
	for k in _scores.keys():
		if _scores[k] > max_score:
			max_score = _scores[k]
			winner_team = k
	if winner_team >= 0:
		for e in _teams[winner_team]:
			world.increase_xp(e, min(e.xp * 2, min(100 * e.level, 1000)))
		for e in _cheers[winner_team]:
			world.increase_xp(e, min(e.xp * 2, min(200 * e.level, 2000)))
	emit_signal("stopped_game", _scores)

var ball_delay = 0.0
var catch_ball_delay = 0.0
func _physics_process(delta):
	match(_state):
		STATE_START:
			start_timeout -= delta
#			print("timeout")
			if start_timeout <= 0.0:
				for t in _teams.keys():
					for ch in _teams[t]:
#						print("teleport")
						if ch.scene._path.size() > 0:
							ch.scene.global_transform.origin = ch.scene._path[ch.scene._path.size() - 1]
						else:
							ch.scene.global_transform.origin = _team_start[t] + Vector3(randf() * 2.0 - 1.0, 0.0, randf() * 2.0 - 1.0)
				_state = STATE_RUNNING
		STATE_RUNNING:
#			print("running")
			var tgt = _ball_instance.global_transform.origin
			for t in _teams.keys():
				for ch in _teams[t]:
					if ch.scene._path && ch.scene._path.size() > 0:
						var moveto = ch.scene._path[ch.scene._path.size() - 1]
						if tgt.distance_squared_to(moveto) > 0.5:
#							print("walking")
							ch.scene.walkto(tgt,  1.0 + ch.speed + randf() * ch.speed * 0.5)
					else:
							ch.scene.walkto(tgt,  1.0 + ch.speed + randf() * ch.speed * 0.5)
					if ch.scene.global_transform.origin.distance_to(tgt) < 0.6 && _ball_carrier == null && catch_ball_delay <= 0:
						ch.scene.take_object(_ball_instance)
						_state = STATE_GOAL
						_ball_carrier = ch
						_ball_team = t
						ball_delay = 20.0
						for tg in _teams.keys():
							for ch in _teams[tg]:
								if ch != _ball_carrier:
									ch.scene.walkto(_gates[tg].global_transform.origin,  1.0 + ch.speed + randf() * ch.speed * 0.5)
								else:
									ch.scene.walkto(_gates[tg ^ 1].global_transform.origin,  1.0 + ch.speed + randf() * ch.speed * 0.5)
						world.increase_xp(_ball_carrier, 50)
			if catch_ball_delay > 0:
				catch_ball_delay -= delta
		STATE_GOAL:
			ball_delay -= delta
			if ball_delay <= 0 || randf() > 0.995:
				if _ball_carrier:
					_ball_carrier.scene.drop_object(_ball_instance)
					_ball_carrier = null
					_ball_team = -1
					catch_ball_delay = 5.0
				_state = STATE_RUNNING
		STATE_FINISH:
			stop_game()
			_state = STATE_INIT
	training_time += delta
	if training_time >= max_training_time:
		stop_game()
