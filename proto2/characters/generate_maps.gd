extends Control

const TEX_SIZE: int = 512
var maps = {}
var vert_indices = {}
var draw_data_list : = []
var dnatool: DNATool

onready var characters = [load("res://characters/female_2018.escn"), load("res://characters/male_2018.escn")]

func find_mesh_name(base: Node, mesh_name: String) -> MeshInstance:
	var queue = [base]
	var mi: MeshInstance
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is MeshInstance && item.name == mesh_name:
			mi = item
			break
		for c in item.get_children():
			queue.push_back(c)
	return mi

func find_same_verts():
	for chdata in range(characters.size()):
		var ch_scene = characters[chdata].instance()
		var bmesh = find_mesh_name(ch_scene, "body")
		if !vert_indices.has(chdata):
			vert_indices[chdata] = {}
		for surface in range(bmesh.mesh.get_surface_count()):
			var arrays: Array = bmesh.mesh.surface_get_arrays(surface).duplicate(true)
			for index1 in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
				var v1: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][index1]
				var ok = false
				for rk in vert_indices[chdata].keys():
					if (v1 - rk).length() < 0.001:
						ok = true
						vert_indices[chdata][rk].push_back(index1)
				if !ok:
					vert_indices[chdata][v1] = [index1]

static func check_triangle(verts: Array) -> bool:
	var uv1 = verts[0].uv
	var uv2 = verts[1].uv
	var uv3 = verts[2].uv
	var v1 = uv1 - uv3
	var v2 = uv1 - uv3
	if v1.length() * TEX_SIZE < 1.2:
		return false
	if v2.length() * TEX_SIZE < 1.2:
		return false
	var sumdata = Vector3()
	for k in range(2):
		for ks in range(verts[k].shape.size()):
			sumdata += verts[k].shape[ks]
	if sumdata.length() < 0.001:
		return false
	return true
static func pad_morphs(morphs: Dictionary, nshapes: Dictionary, min_point: Vector3, max_point: Vector3, min_normal: Vector3, max_normal: Vector3):
	for mesh in morphs.keys():
		for m in morphs[mesh].keys():
			var ns = nshapes[mesh][m]
			for t in range(morphs[mesh][m].size()):
				for v in range(morphs[mesh][m][t].size()):
	#				print(morphs[m][t][v])
					for s in range(morphs[mesh][m][t][v].shape.size()):
						for u in range(3):
							var cd : float = max_point[u] - min_point[u]
							var ncd : float = max_normal[u] - min_normal[u]
							var d = morphs[mesh][m][t][v].shape[s][u]
							morphs[mesh][m][t][v].shape[s][u] = (d - min_point[u]) / cd
							var ew = morphs[mesh][m][t][v].shape[s][u] * cd + min_point[u]
							assert(abs(ew - d) < 0.001)
							morphs[mesh][m][t][v].normal[s][u] = (morphs[mesh][m][t][v].normal[s][u] - min_normal[u]) / ncd
static func fill_draw_data(morphs: Dictionary, draw_data: Dictionary, morph_names: Dictionary, nshapes: Dictionary, rects: Dictionary):
	var offset : = 0
	for mesh in morphs.keys():
		for m in morphs[mesh].keys():
			if !draw_data.has(m):
				draw_data[m] = {}
			var ns = nshapes[mesh][m]
			for sh in range(ns):
				print(morph_names[mesh][m][sh], ": ", m, " ", sh + offset)
				draw_data[m][sh + offset] = {"name": morph_names[mesh][m][sh], "triangles": [], "rects": []}
				for t in range(morphs[mesh][m].size()):
					var tri : = []
					var midp = Vector2()
					var sp = Vector3()
					
					for v in range(morphs[mesh][m][t].size()):
						midp += morphs[mesh][m][t][v].uv
					midp /= 3.0
					for v in range(morphs[mesh][m][t].size()):
						var pt = morphs[mesh][m][t][v].uv - midp
						var dpt = pt.normalized() * (3.5 / TEX_SIZE)
						tri.push_back({"uv": morphs[mesh][m][t][v].uv + dpt, "shape": morphs[mesh][m][t][v].shape[sh], "normal": morphs[mesh][m][t][v].normal[sh]})
					draw_data[m][sh + offset].triangles.push_back(tri)
				draw_data[m][sh + offset].rect = rects[mesh][m][sh]
			offset = draw_data[m].keys().size()

var common = []
var common_path = "characters/common"
func load_data():
	var fd = File.new()
	fd.open("characters/common/data.json", File.READ)
	var json = fd.get_as_text()
	var json_result = JSON.parse(json)
	var json_data = json_result.result
	fd.close()
	for e in json_data.files:
		var load_path = "res://" + e
		var item = load(load_path)
		assert(item)
		common.push_back(item)

static func update_rects(arrays: Array, bshapes: Array) -> Dictionary:
	var rects = {}
	for idx in range(0, arrays[ArrayMesh.ARRAY_INDEX].size(), 3):
		for t in range(3):
			var index_base = arrays[ArrayMesh.ARRAY_INDEX][idx + t]
			var vertex_base = arrays[ArrayMesh.ARRAY_VERTEX][index_base]
			var normal_base = arrays[ArrayMesh.ARRAY_NORMAL][index_base]
			var uv_base = arrays[ArrayMesh.ARRAY_TEX_UV][index_base]
			for bsc in range(bshapes.size()):
				if !rects.has(bsc):
					rects[bsc] = Rect2(uv_base, Vector2())
				var vertex_mod = bshapes[bsc][ArrayMesh.ARRAY_VERTEX][index_base] - vertex_base
				if vertex_mod.length() > 0.0001:
					rects[bsc] = rects[bsc].expand(uv_base)
	return rects
static func update_triangles(arrays: Array, bshapes: Array) -> Array:
	var triangles: Array = []
	var ntriangles : = 0
	var skipped : = 0
	for idx in range(0, arrays[ArrayMesh.ARRAY_INDEX].size(), 3):
		var verts = []
		for t in range(3):
			var index_base = arrays[ArrayMesh.ARRAY_INDEX][idx + t]
			var vertex_base = arrays[ArrayMesh.ARRAY_VERTEX][index_base]
			var normal_base = arrays[ArrayMesh.ARRAY_NORMAL][index_base]
			var uv_base = arrays[ArrayMesh.ARRAY_TEX_UV][index_base]
			var index_shape = []
			var vertex_shape = []
			var normal_shape = []
			var uv_shape = []
			for bsc in range(bshapes.size()):
				index_shape.push_back(bshapes[bsc][ArrayMesh.ARRAY_INDEX][idx + t])
				var index = index_shape[index_shape.size() - 1]
				if index != index_base:
					print("index mismatch", bsc, " ", index_base, " ", index)
				var vertex_mod = bshapes[bsc][ArrayMesh.ARRAY_VERTEX][index] - vertex_base
				var normal_mod = bshapes[bsc][ArrayMesh.ARRAY_NORMAL][index] - normal_base
				vertex_shape.push_back(vertex_mod)
				normal_shape.push_back(normal_mod)
				uv_shape.push_back(bshapes[bsc][ArrayMesh.ARRAY_TEX_UV][index])
				if (uv_shape[uv_shape.size() - 1] - uv_base).length() != 0:
					print("uv mismatch", bsc, " ", idx)
			var vdata = {}
			vdata.shape = vertex_shape
			vdata.normal = normal_shape
			vdata.uv = uv_base
			verts.push_back(vdata)
		if check_triangle(verts):
			triangles.push_back(verts)
			ntriangles += 1
		else:
			skipped += 1
	if skipped > 0:
		print("ntriangles: ", ntriangles, " skipped: ", skipped)
	return triangles
static func get_shape_names(mesh: ArrayMesh) -> PoolStringArray:
	var shape_names: Array = []
	for r in range(mesh.get_blend_shape_count()):
		shape_names.push_back(mesh.get_blend_shape_name(r))
	return PoolStringArray(shape_names)
static func process_morph_meshes(mesh: ArrayMesh, morphs: Dictionary, rects: Dictionary, mesh_data: Dictionary, nshapes: Dictionary):
	for sc in range(mesh.get_surface_count()):
		if !morphs.has(sc):
			morphs[sc] = []
			mesh_data[sc] = PoolStringArray()
			rects[sc] = {}
		var bshapes: Array = mesh.surface_get_blend_shape_arrays(sc)
		var arrays: Array = mesh.surface_get_arrays(sc)
		print("vertices: ", arrays[ArrayMesh.ARRAY_VERTEX].size())
		print("indices: ", arrays[ArrayMesh.ARRAY_INDEX].size())
		print("surf: ", sc, " shapes: ", bshapes.size())
		var shape_names : = get_shape_names(mesh)
		rects[sc] = update_rects(arrays, bshapes)
		var triangles : = update_triangles(arrays, bshapes)
		morphs[sc] += triangles
		mesh_data[sc] += shape_names
		nshapes[sc] = bshapes.size()

var mesh_queue = []
static func _process_morph_meshes(mesh: ArrayMesh) -> Dictionary:
	var ret = {}
	for sc in range(mesh.get_surface_count()):
		var bshapes: Array = mesh.surface_get_blend_shape_arrays(sc)
		var arrays: Array = mesh.surface_get_arrays(sc)
		var shape_names : = get_shape_names(mesh)
		ret[sc] = {}
		ret[sc].rects = update_rects(arrays, bshapes)
		var triangles : = update_triangles(arrays, bshapes)
		ret[sc].morphs = triangles
		ret[sc].mesh_data = shape_names
		ret[sc].nshapes = bshapes.size()
	return ret
static func _pad_morphs(morphs: Dictionary, nshapes: Dictionary, min_point: Vector3, max_point: Vector3, min_normal: Vector3, max_normal: Vector3):
	# mesh - scene id from common array
	for mesh in morphs.keys():
		for m in morphs[mesh].keys():
			var ns = nshapes[mesh][m]
			for t in range(morphs[mesh][m].size()):
				for v in range(morphs[mesh][m][t].size()):
	#				print(morphs[m][t][v])
					for s in range(morphs[mesh][m][t][v].shape.size()):
						for u in range(3):
							var cd : float = max_point[u] - min_point[u]
							var ncd : float = max_normal[u] - min_normal[u]
							var d = morphs[mesh][m][t][v].shape[s][u]
							morphs[mesh][m][t][v].shape[s][u] = (d - min_point[u]) / cd
							var ew = morphs[mesh][m][t][v].shape[s][u] * cd + min_point[u]
							assert(abs(ew - d) < 0.001)
							morphs[mesh][m][t][v].normal[s][u] = (morphs[mesh][m][t][v].normal[s][u] - min_normal[u]) / ncd
#func build_queue():
#	var scene_data : = {}
#	for scene_no in range(common.size()):
#		var ch: Node = common[scene_no].instance()
#		var helper_data : = {}
#		for mesh_name in ["base", "robe_helper", "tights_helper", "skirt_helper"]:
#			helper_data[mesh_name] = {}
#			var mi: MeshInstance = find_mesh_name(ch, mesh_name)
#			var mesh: ArrayMesh = mi.mesh
#			var morph_list = get_shape_names(mesh)
#			var helper_shapes : = PoolStringArray()
#			for e in morph_list:
#				if !e in helper_shapes:
#					helper_shapes.push_back(e)
#			dnatool.find_min_max(mesh)
#			helper_data[mesh_name].shape_list = helper_shapes
#			helper_data[mesh_name].morph_data = _process_morph_meshes(mesh)
#		scene_data[scene_no] = helper_data
	
func _ready():
	dnatool = DNATool.new()
	$gen/drawable.connect("drawing_finished", self, "handle_drawing_finished", [$gen])
	var morphs = {}
	var morphs_helper = {}
	var mesh_data = {}
	var mesh_data_helper = {}
	var nshapes = {}
	var rects = {}
	var rects_helper = {}
	var nshapes_helper = {}
	load_data()
#	build_queue()
	var base_shapes : = PoolStringArray()
	var file_shapes = {}
	for mesh_no in range(common.size()):
		var ch: Node = common[mesh_no].instance()
		var mi: MeshInstance = find_mesh_name(ch, "base")
		var mesh: ArrayMesh = mi.mesh
		var morph_list = get_shape_names(mesh)
		base_shapes += morph_list
		file_shapes[common[mesh_no].resource_path] = morph_list
	for helper in ["robe_helper", "tights_helper", "skirt_helper"]:
		var helper_shapes : = PoolStringArray()
		for mesh_no in range(common.size()):
			var ch: Node = common[mesh_no].instance()
			var mi: MeshInstance = find_mesh_name(ch, helper)
			var mesh: ArrayMesh = mi.mesh
			var morph_list = get_shape_names(mesh)
			helper_shapes += morph_list
		for e in base_shapes:
			assert(e in helper_shapes)

	for mesh_no in range(common.size()):
#		var skipped : = 0
#		var ntriangles : = 0
		var ch: Node = common[mesh_no].instance()
#		add_child(ch)
		var mi: MeshInstance = find_mesh_name(ch, "base")
		if !mi:
			return
		var mesh: ArrayMesh = mi.mesh
		if !mesh:
			return
		dnatool.find_min_max(mesh)
		if !morphs.has(mesh_no):
			morphs[mesh_no] = {}
			mesh_data[mesh_no] = {}
			nshapes[mesh_no] = {}
			rects[mesh_no] = {}
		process_morph_meshes(mesh, morphs[mesh_no], rects[mesh_no], mesh_data[mesh_no], nshapes[mesh_no])
	pad_morphs(morphs, nshapes, dnatool.min_point, dnatool.max_point, dnatool.min_normal, dnatool.max_normal)
	var draw_data: Dictionary = {}
	fill_draw_data(morphs, draw_data, mesh_data, nshapes, rects)
	draw_data_list.push_back(draw_data)
	for helper_name in ["robe_helper", "tights_helper", "skirt_helper"]:
		for mesh_no  in range(common.size()):
			var ch: Node = common[mesh_no].instance()
#			var mi: MeshInstance = find_mesh_name(ch, "base")
			var mi_helper: MeshInstance = find_mesh_name(ch, helper_name)
			assert(mi_helper != null)
			var mesh: ArrayMesh = mi_helper.mesh
#			var mesh_skirt: ArrayMesh = mi_skirt.mesh
			morphs_helper[mesh_no] = {}
			rects_helper[mesh_no] = {}
			mesh_data_helper[mesh_no] = {}
			nshapes_helper[mesh_no] = {}
			process_morph_meshes(mesh, morphs_helper[mesh_no], rects_helper[mesh_no], mesh_data_helper[mesh_no], nshapes_helper[mesh_no])
		pad_morphs(morphs_helper, nshapes_helper, dnatool.min_point, dnatool.max_point, dnatool.min_normal, dnatool.max_normal)
		var helper_draw_data: Dictionary = {}
		fill_draw_data(morphs_helper, helper_draw_data, mesh_data_helper, nshapes, rects_helper)
		draw_data_list.push_back(helper_draw_data)
	# TODO: combine helpers here
#	var draw_data: Dictionary = {}
#	fill_draw_data(morphs, draw_data, mesh_data, nshapes, rects)
#	draw_data_list.push_back(draw_data)
#	var draw_data_helper: Dictionary = {}
#	fill_draw_data(morphs_helper, draw_data_helper, mesh_data_helper, nshapes_helper, rects_helper)
#	draw_data_list.push_back(draw_data_helper)
	print("data count: ", draw_data.keys(), " ", draw_data[0].keys())
	$gen/drawable.triangles = draw_data[0][0].triangles
	$gen/drawable.min_point = dnatool.min_point
	$gen/drawable.max_point = dnatool.max_point
	$gen/drawable.normals = false
#	print("done ", mesh.get_surface_count(), " ", mesh.get_blend_shape_count(), " ", min_point, " ", max_point, " added: ", ntriangles, " skipped: ", skipped)
var helper : = 0
var surface : = 0
var shape : = 0
var exit_delay : = 3.0
var draw_delay : = 2.0
#func save_viewport(v: Viewport, maplist: Dictionary, shape_name: String, rect: Rect2, normals: bool):
##	v.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
##	yield(get_tree(), "idle_frame")
##	yield(get_tree(), "idle_frame")
#	var viewport: Viewport = v
#	var vtex : = viewport.get_texture()
#	var tex_img : = vtex.get_data()
#	var fn = ""
#	if !maplist.has(shape_name):
#		maplist[shape_name] = {}
#		maplist[shape_name].width = tex_img.get_width()
#		maplist[shape_name].height = tex_img.get_height()
#		maplist[shape_name].format = tex_img.get_format()
#	var byte_data = tex_img.duplicate(true).get_data()
#	var image_size = byte_data.size()
#	if normals:
#		maplist[shape_name].image_normal_data = byte_data.compress(File.COMPRESSION_FASTLZ)
#		maplist[shape_name].image_normal_size = image_size
#	else:
#		maplist[shape_name].image_data = byte_data.compress(File.COMPRESSION_FASTLZ)
#		maplist[shape_name].rect = rect.grow(0.003)
#		maplist[shape_name].image_size = image_size

var helpers_prefix = ["", "robe_", "tights_", "skirt_"]
func finish_map_gen():
	print("generating same vert indices...")
	find_same_verts()
	var fd = File.new()
	fd.open("res://characters/common/config.bin", File.WRITE)
	fd.store_var(dnatool.min_point)
	fd.store_var(dnatool.max_point)
	fd.store_var(dnatool.min_normal)
	fd.store_var(dnatool.max_normal)
	fd.store_var(maps)
	fd.store_var(vert_indices)
	fd.close()
	save_images()
	get_tree().quit()
#	get_tree().change_scene("res://map_test.tscn")
func next_surface():
	shape = 0
	surface += 1
	draw_delay = 1.0
	$gen_maps/ProgressBar.value = 100.0
	$gen/drawable.normals = false
func next_helper():
	shape = 0
	surface = 0
	draw_delay = 1.0
	helper += 1
	$gen/drawable.normals = false
	if helper >= helpers_prefix.size():
		finish_map_gen()
func setup_draw():
	$gen/drawable.normals = !$gen/drawable.normals
	if $gen/drawable.normals:
		$gen/drawable.min_point = dnatool.min_normal
		$gen/drawable.max_point = dnatool.max_normal
	else:
		$gen/drawable.min_point = dnatool.min_point
		$gen/drawable.max_point = dnatool.max_point
	$gen/drawable.triangles = draw_data_list[helper][surface][shape].triangles
	$gen/drawable.update()

func save_images():
	for k in maps.keys():
		for e in ["diffuse", "normal"]:
			var fn = "res://characters/common/" + k + "_" + e + "_orig.png"
			var data: PoolByteArray
			var size: int
			if e == "diffuse":
				data = maps[k].image_data
				size = maps[k].image_size
			elif e == "normal":
				data = maps[k].image_normal_data
				size = maps[k].image_normal_size
			var image_data = data.decompress(size, File.COMPRESSION_FASTLZ)
			var img = Image.new()
			img.create_from_data(maps[k].width, maps[k].height, false, maps[k].format, image_data)
			print("saving ", fn)
			img.save_png(fn)
	var fd = File.new()
	var outj = {}
	outj.min_point = dnatool.min_point
	outj.max_point = dnatool.max_point
	outj.min_normal = dnatool.min_normal
	outj.max_normal = dnatool.max_normal
	outj.maps = maps
	outj.vert_indices = vert_indices
	fd.open("res://characters/common/debug-data-orig.json", File.WRITE)
	fd.store_string(JSON.print(outj, "\t", true))
	fd.close()

func handle_drawing_finished(viewport):
	print_debug("drawing finished")

func _process(delta):
	if surface == draw_data_list[helper].size():
		if exit_delay > 0:
			exit_delay -= delta
			print(exit_delay)
		else:
			next_helper()
	elif shape == draw_data_list[helper][surface].size():
		next_surface()
	else:
		$gen_maps/ProgressBar.value = 100.0 * shape / draw_data_list[helper][surface].size()
		print("value ", $gen_maps/ProgressBar.value)
		if draw_delay > 0:
			draw_delay -= delta
		else:
			dnatool.save_viewport($gen, maps, helpers_prefix[helper] + draw_data_list[helper][surface][shape].name, draw_data_list[helper][surface][shape].rect, $gen/drawable.normals)
#			save_viewport($gen, maps, helpers_prefix[helper] + draw_data_list[helper][surface][shape].name, draw_data_list[helper][surface][shape].rect, $gen/drawable.normals)
			if $gen/drawable.normals:
				shape += 1
			draw_delay = 1.0
			print("shape ", shape)
			if shape < draw_data_list[helper][surface].size():
				setup_draw()
