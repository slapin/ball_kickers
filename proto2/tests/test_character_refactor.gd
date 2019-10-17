extends Spatial

var instances = []
var genders = ["male", "female"]

var count = 10
var x = -float(count - 1) / 2.0 * 0.6

func create_ch():
	for k in range(count):
		var instance = CharacterInstanceList.create(genders[randi() % genders.size()], Transform().translated(Vector3(x, 0, 0)).rotated(Vector3(0, 1, 0), PI), {})
		var ml = CharacterInstanceList.get_base_modifier_list()
		print(ml)
		for k in ml:
			CharacterInstanceList.set_mod_value(instance, k, randf() * 0.5)
		instances.push_back(instance)
		x += 0.6
	CharacterInstanceList.update()
	print("OK")


func _ready():
	seed(OS.get_unix_time())
	CharacterGenderList.config()
	call_deferred("create_ch")

var quit_delay = 1.4
func _process(delta):
	quit_delay -= delta
	if quit_delay <= 0.0:
		get_tree().quit()
	elif instances.size() < 200:
		var instance = CharacterInstanceList.create(genders[randi() % genders.size()], Transform().translated(Vector3(x, 0, 0)).rotated(Vector3(0, 1, 0), PI), {})
		var ml = CharacterInstanceList.get_base_modifier_list()
		for k in ml:
			CharacterInstanceList.set_mod_value(instance, k, randf() * 0.5)
		instances.push_back(instance)
		print(instances.size())
		x += 0.6
		CharacterInstanceList.update()

