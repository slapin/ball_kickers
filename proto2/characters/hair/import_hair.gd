tool
extends EditorScenePostImport

const base_path: String = "res://characters/accessory"
const conf_path: String = "res://characters/accessory.json"

func post_import(scene):
	var confdata = {}
	var gender = ""
	var scname = scene.filename.get_basename().get_file()
	print(scname)
	if scname.find("female") >= 0:
		gender = "female"
	elif scname.find("male") >= 0:
		gender = "male"
	var fd = File.new()
	var d = Directory.new()
	if !d.dir_exists(base_path + "/" + gender + "/hair"):
		d.make_dir_recursive(base_path + "/" + gender + "/hair")
	if fd.file_exists(conf_path):
		fd.open(conf_path, File.READ)
		var confs = fd.get_as_text()
		var json = JSON.parse(confs)
		confdata = json.result
		fd.close()
	var queue = [scene]
	if !confdata.has(gender):
		confdata[gender] = {}
		confdata[gender].hair = {}
	var rm_objs = []
	while queue.size() > 0:
		var item = queue.pop_front()
		if item is MeshInstance && item.name.find("hair") >= 0:
			var mesh: ArrayMesh = item.mesh
			var mesh_path = base_path + "/" + gender + "/hair/" + item.name + ".mesh"
			confdata[gender].hair[item.name] = {"path": mesh_path, "materials": []}
			for m in range(mesh.get_surface_count()):
				var material: Material = mesh.surface_get_material(m)
				material.albedo_texture = load("res://characters/hair/haircard2.png")
				material.params_use_alpha_scissor = true
				material.params_alpha_scissor_threshold = 0.5
				var mat_name = material.resource_name
				if mat_name.length() == 0:
					mat_name = "Material"
				var mat_path = base_path + "/" + gender + "/hair/" + mat_name + ".tres"
				if !fd.file_exists(mat_path):
					ResourceSaver.save(mat_path, material)
				confdata[gender].hair[item.name].materials.push_back({"path": mat_path, "name": mat_name})
			if !fd.file_exists(mesh_path):
				ResourceSaver.save(mesh_path, mesh)
			rm_objs.push_back(item)
		for c in item.get_children():
			queue.push_back(c)
	for item in rm_objs:
		item.queue_free()
	fd.open(conf_path, File.WRITE)
	fd.store_string(JSON.print(confdata, "\t", true))
	fd.close()
	return scene
