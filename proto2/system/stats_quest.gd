extends Quest
class_name StatsQuest

var stat_check: Dictionary

class StatsCheckObjective extends QuestObjective:
	var stat_check: Dictionary
	func _init(title, stats: Dictionary).(title):
		stat_check = stats
	func update():
		_complete = true
		for k in stat_check.keys():
			match(k):
				"player_count":
					if world.team.keys().size() < stat_check[k]:
						_complete = false
						print("player count: ", world.team.keys().size(), " < ", stat_check[k])
				"cheerleader_count":
					if world.cheer_team.keys().size() < stat_check[k]:
						_complete = false
				_:
					_complete = false

func _init(title, desc, stats: Dictionary).(title, desc):
	stat_check = stats
	add_objective(StatsCheckObjective.new("Comply to team stats", stat_check))
