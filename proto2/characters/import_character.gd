tool
extends EditorScenePostImport

const base_path: String = "res://characters/accessory"
const conf_path: String = "res://characters/config.json"
const accessory_path: String = "res://characters/accessory.json"
var confdata = {}
var accessory = {}

func find_ap(scene) -> AnimationPlayer:
	var queue = [scene]
	var ret: AnimationPlayer
	while queue.size() > 0:
		var item = queue.pop_front()
		if item is AnimationPlayer:
			ret = item
			break
		for k in item.get_children():
			queue.push_back(k)
	return ret
func fix_animations(scene):
	var ap: AnimationPlayer = find_ap(scene)
	for l in ap.get_animation_list():
		if l.ends_with("loop"):
			var an: Animation = ap.get_animation(l)
			an.loop = true
			ap.remove_animation(l)
			ap.add_animation(l, an)
func find_skeleton(scene):
	var queue = [scene]
	while queue.size() > 0:
		var item = queue.pop_front()
		if item is Skeleton:
			return item
		for c in item.get_children():
			queue.push_back(c)
	return null
func add_slot(slot):
	if !confdata.has("slots"):
		confdata.slots = []
	if !slot in confdata.slots:
		confdata.slots.push_back(slot)
func build_slot_list(scene):
	var skel = find_skeleton(scene)
	var fd = File.new()
	var d = Directory.new()
	for c in skel.get_children():
		if c is MeshInstance:
			var mesh: ArrayMesh = c.mesh
			assert(mesh)
			print(c.name)
			var mesh_path = base_path + "/" + gender + "/" + c.name + "/" + c.name + "_default.mesh"
			if !accessory.has(gender):
				accessory[gender] = {}
			if !accessory[gender].has(c.name):
				accessory[gender][c.name] = {}
			accessory[gender][c.name][c.name + "_default"] = {"path": mesh_path, "materials": []}
			for m in range(mesh.get_surface_count()):
				if !d.dir_exists(base_path + "/" + gender + "/" + c.name):
					d.make_dir_recursive(base_path + "/" + gender + "/" + c.name)
				var material: Material = c.get_surface_material(m)
				if !material:
					material = mesh.surface_get_material(m)
				assert(material)
				var mat_name = material.resource_name
				if mat_name.length() == 0:
					mat_name = "Material"
				var mat_path = base_path + "/" + gender + "/" + c.name + "/" + mat_name + ".tres"
				if !fd.file_exists(mat_path):
					ResourceSaver.save(mat_path, material)
				accessory[gender][c.name][c.name + "_default"].materials.push_back({"path": mat_path, "name": mat_name})
			if !fd.file_exists(mesh_path):
				ResourceSaver.save(mesh_path, mesh)

			if c.name == "hair":
				add_slot("front_hair")
				add_slot("back_hair")
				c.queue_free()
			else:
				add_slot(c.name)
				c.queue_free()

#func find_same_verts(scene):
#		var bmesh = dnatool.get_mesh(scene, "body")
#		var mi = dnatool.get_mi(scene, "body")
#		var vert_indices = {}
#		for surface in range(bmesh.get_surface_count()):
#			var arrays: Array = bmesh.surface_get_arrays(surface).duplicate(true)
#			for index1 in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
#				var v1: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][index1]
#				var ok = false
#				for rk in vert_indices.keys():
#					if (v1 - rk).length() < 0.001:
#						ok = true
#						vert_indices[rk].push_back(index1)
#				if !ok:
#					vert_indices[v1] = [index1]
#		mi.set_meta("same_verts", vert_indices)

var gender = "unknown"
func post_import(scene):
	var scname = scene.filename.get_basename().get_file()
	print("scname = ", scname)
	if scname.find("female") >= 0:
		gender = "female"
	elif scname.find("male") >= 0:
		gender = "male"
	assert(gender != "unknown")

	var fd = File.new()
	if fd.file_exists(conf_path):
		fd.open(conf_path, File.READ)
		var confs = fd.get_as_text()
		var json = JSON.parse(confs)
		confdata = json.result
		fd.close()
	if fd.file_exists(accessory_path):
		fd.open(accessory_path, File.READ)
		var confs = fd.get_as_text()
		var json = JSON.parse(confs)
		accessory = json.result
		fd.close()
	build_slot_list(scene)
	fix_animations(scene)
	fd.open(conf_path, File.WRITE)
	fd.store_string(JSON.print(confdata, "\t", true))
	fd.close()
	fd.open(accessory_path, File.WRITE)
	fd.store_string(JSON.print(accessory, "\t", true))
	fd.close()
	return scene
