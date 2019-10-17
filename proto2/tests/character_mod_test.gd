extends Spatial

func get_mesh(base: Node, mesh_name: String) -> ArrayMesh:
	var queue = [base]
	var mesh: ArrayMesh
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is MeshInstance && item.name == mesh_name && item.mesh:
			mesh = item.mesh
			break
		for c in item.get_children():
			queue.push_back(c)
	return mesh
func get_mi(base: Node, mesh_name: String) -> MeshInstance:
	var queue = [base]
	var mi: MeshInstance
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is MeshInstance && item.name == mesh_name && item.mesh:
			mi = item
			break
		for c in item.get_children():
			queue.push_back(c)
	return mi
#var modset_body = ModifierSet.new()
#var modset_top = ModifierSet.new()
#var modset_panties = ModifierSet.new()

var body_mi
var mesh_id
var _characters = []
var slots_female = ["body", "top", "panties"]
var slots_male = ["body"]
var helpers = {
	"body": "base",
	"top": "tights",
	"panties": "tights"
	}
var data_male = {}
var data_female = {}
var cha_male
var cha_female
func _ready():
	seed(OS.get_unix_time())
#	var base_male = characters.characters[0].instance()
#	var base_female = characters.characters[1].instance()
#	var fd = File.new()
#	fd.open("characters/blendmaps.bin", File.READ);
#	cha_male = CharacterModifierSet.new()
#	cha_female = CharacterModifierSet.new()
#	cha_female.set_base_name("body")
#	cha_male.set_base_name("body")
#	for e in slots_female:
#		data_female[e] = {
#			"mod": cha_female.create(e)
#		}
#		data_female[e].mod.set_uv_index(1)
#		cha_female.set_helper(e, helpers[e])
#	for e in slots_male:
#		data_male[e] = {
#			"mod": cha_male.create(e)
#		}
#		data_male[e].mod.set_uv_index(1)
#		cha_male.set_helper(e, helpers[e])
#	cha_female.add_mesh_scene(base_female)
#	cha_male.add_mesh_scene(base_male)
#	var bcount = fd.get_32()
#	for f in range(bcount):
#		var pos = fd.get_position()
#		cha_female.load(fd)
#		fd.seek(pos)
#		cha_male.load(fd)
#	print("done")
#	# print(data["body"].mod.get_modifier_list())
#	fd.close()
#	cha_male.add_bone_modifier("head_scale", base_male, "head", Transform().scaled(Vector3(1.3, 1.3, 1.3)))
#	cha_female.add_bone_modifier("head_scale", base_female, "head", Transform().scaled(Vector3(1.3, 1.3, 1.3)))
#	cha_male.add_bone_modifier("head_up", base_male, "head", Transform().translated(Vector3(0.0, 0.3, 0.0)))
#	cha_female.add_bone_modifier("head_up", base_female, "head", Transform().translated(Vector3(0.0, 0.3, 0.0)))
#	cha_male.add_bone_modifier("shoulder_l_rot", base_male, "shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0))
#	cha_female.add_bone_modifier("shoulder_l_rot", base_female, "shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0))
#	cha_male.add_bone_modifier("height", base_male, "pelvis", Transform().scaled(Vector3(1.2, 1.2, 1.2)))
#	cha_female.add_bone_modifier("height", base_female, "pelvis", Transform().scaled(Vector3(1.2, 1.2, 1.2)))
#	cha_male.add_bone_modifier_symmetry("shoulder", base_male, "shoulder01_L", "shoulder01_R")
#	cha_female.add_bone_modifier_symmetry("shoulder", base_female, "shoulder01_L", "shoulder01_R")
#	var num = 4
#	for k in range(num):
#		if randf() > 0.5:
#			var c = characters.characters[1].instance()
#			add_child(c)
#			c.translation.x = float(k)* 0.9 + randf() * 0.2 - float(num) * 0.9 * 0.5
#			c.translation.z = 5.0
#			c.rotation.y = PI
#			var cdata = {}
#			var mesh_id = cha_female.add_work_mesh_scene(c)
#			cdata.scene = c
#			cdata.mesh_id = mesh_id
#			cdata.cha = cha_female
#			_characters.push_back(cdata)
#		else:
#			var c = characters.characters[0].instance()
#			add_child(c)
#			c.translation.x = float(k) * 0.9 + randf() * 0.2 - float(num) * 0.9 * 0.5
#			c.translation.z = 5.0
#			c.rotation.y = PI
#			var cdata = {}
#			var mesh_id = cha_male.add_work_mesh_scene(c)
#			cdata.scene = c
#			cdata.mesh_id = mesh_id
#			cdata.cha = cha_male
#			_characters.push_back(cdata)
	$Camera.translation.x = -8.0
	$Camera.fov = 50.0
var change_delay = 0.1
var mod_id = "neck_width"
var mod_val = 0.0

var char_id = 0
var char_dist = 1.0
var timeout = 30.0

func _process(delta):
	var mdist = 10.0
	var farthest = -1
	for ie in range(_characters.size()):
		var e = _characters[ie]
		var cpos = e.scene.global_transform.origin
		var campos = $Camera.global_transform.origin
		if mdist > abs(cpos.x - campos.x):
			mdist = abs(cpos.x - campos.x)
			farthest = ie
#	if mdist > 3.0 && farthest >= 0:
#		var cf = _characters[farthest]
#		cf.cha.remove_work_mesh_scene(cf.mesh_id)
#		cf.scene.queue_free()
#		_characters.remove(farthest)
	var c
	var cdata = {}
	if char_dist >= 1.0:
		var can_spawn = true
		for mc in _characters:
			if abs(mc.scene.translation.x - $Camera.translation.x - 3.0) < 1.0:
				can_spawn = false
				break
		if can_spawn:
			var xform : = Transform()
			xform.origin.x = $Camera.translation.x + 3.0
			xform.origin.z = 5.0
			xform.basis = xform.basis.rotated(Vector3(0, 1, 0), PI)
			if randf() > 0.5:
				c = characters.spawn_character(1, xform)
#				c = characters.characters[1].instance()
#				add_child(c)
#				c.translation.x = $Camera.translation.x + 3.0
#				c.translation.z = 5.0
#				c.rotation.y = PI
#				var mesh_id = cha_female.add_work_mesh_scene(c)
				cdata.scene = c
#				cdata.mesh_id = mesh_id
#				cdata.cha = cha_female
				_characters.push_back(cdata)
			else:
				c = characters.spawn_character(1, xform)
#				c = characters.characters[0].instance()
#				add_child(c)
#				c.translation.x = $Camera.translation.x + 3.0
#				c.translation.z = 5.0
#				c.rotation.y = PI
#				var mesh_id = cha_male.add_work_mesh_scene(c)
				cdata.scene = c
#				cdata.mesh_id = mesh_id
#				cdata.cha = cha_male
				_characters.push_back(cdata)
#			var mod_name_list = cha_female.get_modifier_list()
			var mod_name_list = characters.get_modifier_list(c)
			for cset in range(160):
				var _mod_id = mod_name_list[randi() % mod_name_list.size()]
				var _mod_val = randf() - 0.5
				characters.set_modifier_value(cdata.scene, _mod_id, _mod_val)
#				cdata.cha.set_modifier_value(cdata.mesh_id, _mod_id, _mod_val)
#			cdata.cha.modify(cdata.scene)
			characters.update()
			char_dist = 0.0
	$Camera.translation.x += 0.25 * delta
#	if change_delay <= 0:
#		var mod_name_list = cha_female.get_modifier_list()
#		char_id = randi() % _characters.size()
#		mod_id = mod_name_list[randi() % mod_name_list.size()]
#		mod_val = randf() - 0.5
#		change_delay = 0.1
#	else:
#		change_delay -= delta
#	var cmod = _characters[char_id]
#	cmod.cha.set_modifier_value(cmod.mesh_id, mod_id, lerp(cmod.cha.get_modifier_value(cmod.mesh_id, mod_id), mod_val, 0.5))
#	cmod.cha.modify()

	var remove_ids = []
	for ie in range(_characters.size()):
		var e = _characters[ie]
		if abs($Camera.translation.x + 3.0 - e.scene.translation.x) > 6.0:
			characters.remove(e.scene)
#			e.cha.remove_work_meshes(e.mesh_id)
#			e.scene.queue_free()
			remove_ids.push_back(ie)

#	remove_ids.sort()
#	remove_ids.invert()
	for e in remove_ids:
		_characters.remove(e)
	char_dist += delta
	timeout -= delta
	if timeout <= 0.0:
		get_tree().quit()
func _physics_process(delta):
	if $Camera.translation.x >= 8.0:
		$Camera.translation.x -= 16.0
		for cm in _characters:
			cm.scene.translation.x -=16.0
		char_dist = 1.0

