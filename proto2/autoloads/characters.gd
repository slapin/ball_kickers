extends Node

#var accessory_data = {}

#var slots = ["body", "top", "panties", "shirt", "pants"]
#var slots_female = ["body", "top", "panties"]
#var slots_male = ["body"]
#var helpers = {
#	"body": "base",
#	"top": "base",
#	"panties": "base",
#	"shirt": "tights",
#	"pants": "tights"
#	}

#var data_male = {}
#var data_female = {}

#var characters = [load("res://characters/male_2018.tscn"), load("res://characters/female_2018.tscn")]
#var character_data = []

#func load_accessory_data():
#	var fd = File.new()
#	fd.open("res://characters/accessory.json", File.READ)
#	var confs = fd.get_as_text()
#	var json = JSON.parse(confs)
#	accessory_data = json.result

func _ready():
#	var cha_male: CharacterModifierSet
#	var cha_female: CharacterModifierSet
#	var base_male = characters[0].instance()
#	var base_female = characters[1].instance()
#	var fd = File.new()
##	fd.open("characters/blendmaps.bin", File.READ);
#	cha_male = CharacterModifierSet.new()
#	character_data.push_back(cha_male)
#	cha_female = CharacterModifierSet.new()
#	character_data.push_back(cha_female)
#	cha_female.set_base_name("body")
#	cha_male.set_base_name("body")
#	for e in slots:
#		print(e)
#		cha_female.add_slot(e, helpers[e], 1)
#		cha_male.add_slot(e, helpers[e], 1)
#	cha_female.add_mesh_scene(characters[1])
#	cha_male.add_mesh_scene(characters[0])
#	cha_female.process()
#	cha_male.process()

### 	cha_male.add_bone_modifier("head_scale", base_male, "head", Transform().scaled(Vector3(1.3, 1.3, 1.3)))
### 	cha_female.add_bone_modifier("head_scale", base_female, "head", Transform().scaled(Vector3(1.3, 1.3, 1.3)))
### 	cha_male.add_bone_modifier("head_up", base_male, "head", Transform().translated(Vector3(0.0, 0.1, 0.0)))
### 	cha_female.add_bone_modifier("head_up", base_female, "head", Transform().translated(Vector3(0.0, 0.1, 0.0)))
### #	cha_male.add_bone_modifier("shoulder_l_rot", base_male, "shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0))
### #	cha_female.add_bone_modifier("shoulder_l_rot", base_female, "shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0))
### 	cha_male.add_bone_modifier("height", base_male, "pelvis", Transform().scaled(Vector3(1.2, 1.2, 1.2)))
### 	cha_female.add_bone_modifier("height", base_female, "pelvis", Transform().scaled(Vector3(1.2, 1.2, 1.2)))
### #	cha_male.add_bone_modifier_pair("shoulder", base_male,
### #		["shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0)],
### #		["shoulder01_R", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0)])
### #	cha_female.add_bone_modifier_pair("shoulder", base_female,
### #		["shoulder01_L", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0)],
### #		["shoulder01_R", Transform().rotated(Vector3(1, 0, 0), 95 * PI / 360.0)])
### 	cha_male.add_bone_modifier_group("mouth_up", base_male,
### 		PoolStringArray(["special01", "special04", "levator04_L", "levator04_R"]),
### 		[Transform().translated(Vector3(0.0, -0.004, 0.0)),
### 		Transform().translated(Vector3(0.0, 0.008, 0.0)),
### 		Transform().translated(Vector3(0.016, -0.019, 0.0)),
### 		Transform().translated(Vector3(-0.016, -0.019, 0.0))
### 		])
### 	cha_female.add_bone_modifier_group("mouth_up", base_female,
### 		PoolStringArray(["special01", "special04", "levator04_L", "levator04_R"]),
### 		[Transform().translated(Vector3(0.0, -0.004, 0.0)),
### 		Transform().translated(Vector3(0.0, 0.008, 0.0)),
### 		Transform().translated(Vector3(0.016, -0.019, 0.0)),
### 		Transform().translated(Vector3(-0.016, -0.019, 0.0))
### 		])
### 	cha_male.add_bone_modifier_group("eyes_up", base_male,
### 		PoolStringArray(["orbicularis03_L", "orbicularis04_L", "eye_L", "eye_tracker.L",
### 						"orbicularis03_R", "orbicularis04_R", "eye_R", "eye_tracker.R"]),
### 		[Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004))])
### 	cha_female.add_bone_modifier_group("eyes_up", base_female,
### 		PoolStringArray(["orbicularis03_L", "orbicularis04_L", "eye_L",
### 						"orbicularis03_R", "orbicularis04_R", "eye_R"]),
### 		[Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004)),
### 		Transform().translated(Vector3(0.0, 0.002, 0.004))])
### 	cha_male.add_bone_modifier_group("eyebrows_up", base_male,
### 		PoolStringArray(["temporalis01_L", "temporalis01_R"]),
### 		[Transform().translated(Vector3(0.0, 0.015, 0.0)),
### 		Transform().translated(Vector3(0.0, 0.015, 0.0))])
### 	cha_female.add_bone_modifier_group("eyebrows_up", base_female,
### 		PoolStringArray(["temporalis01_L", "temporalis01_R"]),
### 		[Transform().translated(Vector3(0.0, 0.015, 0.0)),
### 		Transform().translated(Vector3(0.0, 0.015, 0.0))])
### 	cha_male.add_bone_modifier_group("eyebrows_rotate1", base_male,
### 		PoolStringArray(["oculi02_L", "oculi02_R"]),
### 		[Transform().rotated(Vector3(0, 1, 0), -PI/14.0),
### 		Transform().rotated(Vector3(0, 1, 0), PI/14.0)])
### 	cha_female.add_bone_modifier_group("eyebrows_rotate1", base_female,
### 		PoolStringArray(["oculi02_L", "oculi02_R"]),
### 		[Transform().rotated(Vector3(0, 1, 0), -PI/14.0),
### 		Transform().rotated(Vector3(0, 1, 0), PI/14.0)])
### 	cha_male.add_bone_modifier_group("eyebrows_rotate2", base_male,
### 		PoolStringArray(["oculi01_L", "oculi01_R"]),
### 		[Transform().rotated(Vector3(0, 1, 0), -PI/4.0),
### 		Transform().rotated(Vector3(0, 1, 0), PI/4.0)])
### 	cha_female.add_bone_modifier_group("eyebrows_rotate2", base_female,
### 		PoolStringArray(["oculi01_L", "oculi01_R"]),
### 		[Transform().rotated(Vector3(0, 1, 0), -PI/4.0),
### 		Transform().rotated(Vector3(0, 1, 0), PI/4.0)])
#	base_male.queue_free()
#	base_female.queue_free()
#	load_accessory_data()
	CharacterGenderList.config()
#var root_scene: Node

#func set_root_scene(sc: Node):
#	root_scene = sc

var genders = ["male", "female"]

#func select_front_hair(ch: Node, value: float):
#	var cha = ch.get_meta("mod")
#	var id = ch.get_meta("data_id")
#	var front_list = cha.get_accessory_list(genders[id], "hair", "front_hair")
#	var num = int(front_list.size() * value)
#	num = clamp(num, 0, front_list.size() - 1)
#	character_data[id].set_accessory(ch, "front_hair", genders[id], "hair", front_list[num])
#	ch.set_meta("front_hair", front_list[num])
#
#func select_back_hair(ch: Node, value: float):
#	var cha = ch.get_meta("mod")
#	var id = ch.get_meta("data_id")
#	var back_list = cha.get_accessory_list(genders[id], "hair", "back_hair")
#	var num = int(front_list.size() * value)
#	num = clamp(num, 0, front_list.size() - 1)
#	character_data[id].set_accessory(ch, "front_hair", genders[id], "hair", front_list[num])
#	ch.set_meta("back_hair", "back_hair1")

func spawn_character(id, xform):
#	var ch = character_data[id].spawn()
	var ch = CharacterInstanceList.create(genders[id], xform, {})
#	root_scene.add_child(ch)
#	ch.transform = xform
	ch.set_meta("data_id", id)
#	character_data[id].hide_slot(ch, "hair")
#	character_data[id].set_accessory(ch, "front_hair", genders[id], "hair", "front_hair1")
#	character_data[id].set_accessory(ch, "back_hair", genders[id], "hair", "back_hair1")
#	ch.set_meta("front_hair", "front_hair1")
#	ch.set_meta("back_hair", "back_hair1")
	return ch

func get_modifier_list(ch: Node):
#	var cha = ch.get_meta("mod")
#	return cha.get_modifier_list()
	return CharacterInstanceList.get_base_modifier_list()

func get_modifier_value(ch: Node, mod_id):
#	var cha = ch.get_meta("mod")
#	var mesh_id = ch.get_meta("mesh_id")
#	return cha.get_modifier_value(mesh_id, mod_id)
	return CharacterInstanceList.get_mod_value(ch, mod_id)

func set_modifier_value(ch: Node, mod_id, value):
#	var cha = ch.get_meta("mod")
#	var mesh_id = ch.get_meta("mesh_id")
#	cha.set_modifier_value(mesh_id, mod_id, value)
	CharacterInstanceList.set_mod_value(ch, mod_id, value)

#func modify(ch: Node):
#	var cha = ch.get_meta("mod")
#	cha.modify(ch)
func update():
	print("update")
	CharacterInstanceList.update()

func remove(ch):
#	var cha = ch.get_meta("mod")
#	cha.remove(ch)
	CharacterInstanceList.remove(ch)

#func spawn_accessory(slot: MeshInstance, gender: String, atype: String, aname: String):
#	var mesh: ArrayMesh = load(accessory_data[gender][atype][aname].path)
#	for c in range(mesh.get_surface_count()):
#		var mat: SpatialMaterial = load(accessory_data[gender][atype][aname].materials[c].path)
#		mesh.surface_set_material(c, mat)
#	slot.mesh = mesh
