extends Node
signal room_event
signal next_day
signal next_period
signal level_up
signal start_training

var money: int = 2000
var master_node
var current_room
var team = {}
var cheer_team = {}
var room_events = {}
var line = {}
var training = false
var nav: Navigation
var quests : = []
var team_train_count : = 0
var arrow: Spatial

func room_event(ev: String):
	if current_room:
		if room_events.has(current_room.name):
			if room_events[current_room.name].has(ev):
				var evdata = room_events[current_room.name][ev]
				evdata.obj.call_deferred(evdata.fname, evdata.name)
func register_room_event(roomobj, evname, fname):
	if !room_events.has(roomobj.name):
		room_events[roomobj.name] = {}
	room_events[roomobj.name][evname] = {"obj": roomobj, "name": evname, "fname": fname}

func _ready():
	connect("room_event", self, "room_event")

var master_stats:Dictionary = {
	"type": 0,
	"gender": 0,
	"name": "John",
	"lastname": "Smith",
	"speed": 0.5,
	"strength": 0.5,
	"agression": 0.5,
	"charisma": 0.5,
	"obedience": 0.0,
	"cost": 0,
	"xp": 0,
	"mext_xp": 100,
	"points": 5,
	"level": 1
}

func new_candidate() -> Dictionary:
	var gender = randi() % 2
	var type = 0
	if gender == 0:
		type = 0
	else:
		type = randi() % 2
	var ret = {}
	if gender == 0:
		ret.name = "John"
		ret.lastname = "Doe"
	else:
		ret.name = "Jane"
		ret.lastname = "Doe"
	ret.gender = gender
	ret.type = type
	ret.speed = 0.3 + randf() * 0.7
	ret.strength = 0.1 + randf() * 0.9
	ret.agression = 0.1 + randf() * 0.9
	ret.charisma = 0.1 + randf() * 0.9
	ret.obedience = 0.1 + randf() * 0.9
	if type == 0:
		ret.cost = 2 + int(randf() * 20.0 * (ret.speed + ret.strength + ret.agression) / 3.0)
	else:
		ret.cost = 2 + int(randf() * 20.0 * (ret.speed + ret.strength + ret.charisma) / 3.0)
	ret.xp = 0
	ret.next_xp = 100
	ret.points = 5
	ret.level = 1
	return ret

func auto_points(ch):
	while ch.points > 0:
		ch.points -= 1
		var choice = randi() % 5
		match(choice):
			0:
				if ch.type == 0:
					ch.strength += 0.15
				else:
					ch.charisma += 0.15
			1:
				ch.speed += 0.2
			2:
				ch.agression += 0.2
			3:
				ch.obedience += 0.2
			4:
				if ch.type == 1:
					ch.strength += 0.05
				else:
					ch.charisma += 0.05

func level_up(ch):
	emit_signal("level_up", ch)
	ch.points += 1 + randi() % 5
	if ch.level < 20:
		ch.next_xp *= 2
	elif ch.level < 60:
		ch.next_xp += (10 + ch.level) * 1000
	else:
		ch.next_xp += (20 + ch.level) * 2000
	ch.level += 1
	print("level up!, new level: ", ch.level, " next xp: ", ch.next_xp)
	auto_points(ch)
	
func increase_xp(ch, num):
	ch.xp += num
	print("added ", num, " xp, xp = ", ch.xp)
	if ch.xp >= ch.next_xp:
		level_up(ch)
	else:
		print("next at ", ch.next_xp)

func init_data():
	for ci in range(24):
		var cd : = new_candidate()
		line[ci] = cd
	team = {}
	cheer_team = {}
	print(line)
	

func dialogue(npc):
	pass
var day_period = 0
var day = 1
func next_day():
	day += 1
	emit_signal("next_day")
func next_period():
	day_period += 1
	emit_signal("next_period")
	if day_period == 4:
		day_period = 0
		next_day()

func action1():
	print("action1")
	var obj = null
	var dstc = 0.0
	for k in get_tree().get_nodes_in_group("act") + get_tree().get_nodes_in_group("npc"):
		if obj == null:
			obj = k
			dstc = master_node.global_position.distance_squared_to(obj.global_position)
			continue
		var dst = master_node.global_position.distance_squared_to(k.global_position)
		if dstc > dst:
			obj = k
			dstc = master_node.global_position.distance_squared_to(obj.global_position)
			continue
	if obj && dstc < 400.0:
		print("action1 obj")
		if obj.is_in_group("npc"):
			dialogue(obj)
		else:
			obj.call_deferred("activate")
	else:
		print("action1 room")
		emit_signal("room_event", "action1")
