extends Spatial

var ch

var current_data = {}
var nn

func train(quality):
	var inputs = []
	var dk = current_data.keys()
	dk.sort()
	for k in dk:
		if k == "quality":
			continue
		inputs.push_back(current_data[k])
	nn.train(inputs, [quality])
func guess():
	var inputs = []
	var dk = current_data.keys()
	dk.sort()
	for k in dk:
		if k == "quality":
			continue
		inputs.push_back(current_data[k])
	var outputs = nn.feedforward(inputs)
	$VBoxContainer/Label.text = str(outputs[0])

func train_by_data():
	var data = []
	var fd = File.new()
	if fd.file_exists("res://tests/training_set.json"):
		fd.open("res://tests/training_set.json", File.READ)
		var json = JSON.parse(fd.get_as_text())
		data = json.result
		fd.close()
	for t in range(data.size() * 5):
		var inputs = []
		var dataset = data[randi() % data.size()]
		var dk = dataset.keys()
		dk.sort()
		for k in dk:
			if k == "quality":
				continue
			inputs.push_back(dataset[k])
		nn.train(inputs, [dataset["quality"]])

var cdirty = false
func change_scroll_value(value, mod_name):
	characters.set_modifier_value(ch, mod_name, float(value) / 100.0)
	cdirty = true

func update_controls():
	for c in $VBoxContainer/s/b.get_children():
		c.queue_free()
	var mod_list = Array(characters.get_modifier_list(ch))
	mod_list.sort()
	for m in mod_list:
		var item = HBoxContainer.new()
		$VBoxContainer/s/b.add_child(item)
		var t = Label.new()
		item.add_child(t)
		t.rect_min_size.x = 100.0
		t.text = m
		var scroll = HScrollBar.new()
		item.add_child(scroll)
		scroll.rect_min_size.x = 100.0
		scroll.rect_min_size.y = 4.0
		scroll.min_value = -100.0
		scroll.max_value = 100.0
		scroll.value = characters.get_modifier_value(ch, m) * 100.0
		scroll.connect("value_changed", self, "change_scroll_value", [m])

func save_data(quality):
	var data = []
	var fd = File.new()
	if fd.file_exists("res://tests/training_set.json"):
		fd.open("res://tests/training_set.json", File.READ)
		var json = JSON.parse(fd.get_as_text())
		data = json.result
		fd.close()
	current_data["quality"] = quality
	data.push_back(current_data)
	fd.open("res://tests/training_set.json", File.WRITE)
	fd.store_string(JSON.print(data, "\t", true))
	fd.close()
	print(current_data.keys().size())
func get_skeleton(base: Node):
	var queue = [base]
	var skel: Skeleton
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is Skeleton:
			skel = item
			break
		for c in item.get_children():
			queue.push_back(c)
	return skel

func get_head_pos():
	var skel = get_skeleton(ch)
	var head_id = skel.find_bone("head")
	var xform = skel.get_bone_global_pose(head_id)
	return skel.global_transform.xform(xform.origin)

var rotate = 0
	
func select_ok():
	train(0.5)
	save_data(0.5)
	remove()
	call_deferred("spawn")
func select_bad():
	train(0.0)
	save_data(0.0)
	remove()
	call_deferred("spawn")
func select_good():
	train(1.0)
	save_data(1.0)
	remove()
	call_deferred("spawn")
func trigger_cam():
	if $r/Camera.current:
		$r/face_cam.global_transform.origin = get_head_pos() + Vector3(0, 0, 0.4)
		
		$r/face_cam.make_current()
	elif $r/face_cam.current:
		$r/Camera.make_current()
func trigger_rotate():
	rotate += 1
	match(rotate):
		0:
			$r.rotation.y = 0.0
		1:
			$r.rotation.y = PI / 2.0
		2:
			$r.rotation.y = PI
		3:
			$r.rotation.y = PI * 3.0 / 4.0
		5:
			rotate = 0
			$r.rotation.y = 0.0
func _ready():
	$r/Camera.fov = 50.0
	$VBoxContainer/bad.connect("pressed", self, "select_bad")
	$VBoxContainer/ok.connect("pressed", self, "select_ok")
	$VBoxContainer/good.connect("pressed", self, "select_good")
	$VBoxContainer/face_trig.connect("pressed", self, "trigger_cam")
	$VBoxContainer/rotate.connect("pressed", self, "trigger_rotate")
#	characters.set_root_scene(self)
	call_deferred("init_tail")
func init_tail():
	remove()
	spawn()
	nn = NeuralNetwork.new(current_data.keys().size(), 160, 1)
	train_by_data()
	guess()
	print(characters.get_modifier_list(ch))
var gender = -1
func spawn():
	if randf() >= 0.5:
		gender = 1
	else:
		gender = 0
	ch = characters.spawn_character(gender, Transform().rotated(Vector3(0, 1, 0), PI))
	current_data["gender"] = gender
	var mod_name_list = characters.get_modifier_list(ch)
	for cset in range(mod_name_list.size()):
		var _mod_id = mod_name_list[cset]
		var _mod_val = randf() * 1.5 - 0.75
		characters.set_modifier_value(ch, _mod_id, _mod_val)
		current_data[_mod_id] = _mod_val
#	characters.modify(ch)
	characters.update()
	if nn:
		guess()
	update_controls()

func remove():
	if ch:
		characters.remove(ch)
func _process(delta):
	if rotate == 4:
		$r.rotation.y += delta
	if cdirty:
		characters.update()
		var mod_name_list = characters.get_modifier_list(ch)
		for cset in range(mod_name_list.size()):
			var _mod_id = mod_name_list[cset]
			current_data[_mod_id] = characters.get_modifier_value(ch, _mod_id)
