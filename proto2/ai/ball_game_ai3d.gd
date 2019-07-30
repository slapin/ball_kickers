extends Node
class_name BallGameAI3D

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

enum {STATE_INIT, STATE_START, STATE_RUNNING, STATE_FINISH}
func _ready():
	_game_area = AABB()

func set_ball(ball: Node):
	_ball_instance = ball

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
func add_cheer_game_location(team: int, loc: Vector3):
	if !_cheer_locations.has(team):
		_cheer_locations[team] = [loc]
	else:
		_cheer_locations[team].push_back(loc)
	_game_area = _game_area.expand(loc)
func set_team_start(team: int, v: Vector3):
	_team_start[team] = v
	_game_area = _game_area.expand(v)
func set_team_gate(team: int, gate: Area):
	_gates[team] = gate
	gate2team[gate] = team
	gate.connect("body_entered", self, "check_goal", [gate])
	var o : = gate.global_transform.origin
	_game_area = _game_area.expand(o)
func set_main(n):
	_main = n
func start_game():
	var ball = _ball_instance
	ball.add_to_group("ball")
	_state = STATE_START
	for t in _teams.keys():
		for ch in _teams[t]:
			assert ch != null
			print(ch)
			assert ch.scene != null
			print("start: ", _team_start[t])
			ch.scene.walkto(_team_start[t])
	var loc = 0
	for t in _cheers.keys():
		for ch in _cheers[t]:
			assert ch != null
			print(ch)
			assert ch.scene != null
			ch.scene.walkto(_cheer_locations[t][loc % _cheer_locations[t].size()])
			loc += 1
	for t in _teams.keys():
		_scores[t] = 0
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
