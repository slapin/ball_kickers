extends Control
signal draw_finished

var common = []
var common_path = "characters/common"

var dnatool: DNATool

#const TEX_SIZE: int = 512

var maps = {}
var vert_indices = {}

onready var _characters = [load("res://characters/female_2018.escn"), load("res://characters/male_2018.escn")]

func find_same_verts():
	for chdata in range(_characters.size()):
		var ch_scene = _characters[chdata].instance()
		var bmesh = get_mesh(ch_scene, "body")
		if !vert_indices.has(chdata):
			vert_indices[chdata] = {}
		for surface in range(bmesh.get_surface_count()):
			var arrays: Array = bmesh.surface_get_arrays(surface).duplicate(true)
			for index1 in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
				var v1: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][index1]
				var ok = false
				for rk in vert_indices[chdata].keys():
					if (v1 - rk).length() < 0.001:
						ok = true
						vert_indices[chdata][rk].push_back(index1)
				if !ok:
					vert_indices[chdata][v1] = [index1]

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
		assert item
		common.push_back(item)

func get_mesh(base: Node, mesh_name: String) -> ArrayMesh:
	var queue = [base]
	var mesh: ArrayMesh
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is MeshInstance && item.name == mesh_name:
			mesh = item.mesh
			break
		for c in item.get_children():
			queue.push_back(c)
	return mesh

func compress_points(v: PoolVector3Array, vmin: Vector3, vmax: Vector3) -> PoolVector3Array:
	var cd = vmax - vmin
	var ret: PoolVector3Array = PoolVector3Array(v)
	for e in range(v.size()):
		for h in range(3):
			assert cd[h] > 0.0
			ret[e][h] = (v[e][h] - vmin[h]) / cd[h]
			assert ret[e][h] <= 1.0 && ret[e][h] >= 0.0
	return ret

enum {STATE_DRAW, STATE_CHECK, STATE_FINISH, STATE_IDLE}

var draw_queue = []

func create_queue(diffmap: Dictionary):
	for k in diffmap.keys():
		var mesh_name:String = k
		var prefix = ""
		if mesh_name.ends_with("_helper"):
			prefix = mesh_name.replace("_helper", "_")
		for map_name in diffmap[k]:
			var map_key = prefix + map_name
			var data = {}
			data.map = map_key
			data.normals = false
			data.triangles_uv = diffmap[k][map_name].triangles_uv
			data.triangles_v = diffmap[k][map_name].triangles_v
			data.rect = diffmap[k][map_name].rect
			draw_queue.push_back(data)
			if data.map == "ankle_depth_minus":
				print("ankle:t: ", diffmap[k][map_name].triangles_v)
				print("ankle:tuc: ", diffmap[k][map_name].triangles_v_uc)
			data = {}
			data.map = map_key
			data.normals = true
			data.triangles_uv = diffmap[k][map_name].triangles_uv
			data.triangles_v = diffmap[k][map_name].triangles_n
			data.rect = diffmap[k][map_name].rect
			draw_queue.push_back(data)

var uv_to_uv2: Dictionary
func _ready():
	dnatool = DNATool.new()
	load_data()
	var base_mesh = "base"
	var helper_meshes = ["robe_helper", "tights_helper", "skirt_helper"]
	var diffmap = {}
	for c in common:
		for mesh_name in [base_mesh] + helper_meshes:
			var obj = c.instance()
			var mesh = get_mesh(obj, mesh_name)
			dnatool.find_min_max(mesh)
	var cd = dnatool.max_point - dnatool.min_point
	var ncd = dnatool.max_normal - dnatool.min_normal
	assert cd.x > 0.0 && cd.y > 0.0 && cd.z > 0.0
	for c in common:
		var obj = c.instance()
		if !diffmap.has(base_mesh):
			diffmap[base_mesh] = {}
		var mesh = get_mesh(obj, base_mesh)
		uv_to_uv2 = dnatool.build_uv_to_uv2(mesh, 0)
		dnatool.build_triangles(mesh, diffmap[base_mesh])
		print("scene: ", c, "mesh: ", base_mesh, " done")
		for mesh_name in helper_meshes:
			var helper_mesh = get_mesh(obj, mesh_name)
			if !diffmap.has(mesh_name):
				diffmap[mesh_name] = {}
#			helper_mesh = dnatool.convert_triangles(mesh, helper_mesh)
			dnatool.build_triangles(helper_mesh, diffmap[mesh_name])
			print("scene: ", c, "mesh: ", mesh_name, " done")
		print("scene: ", c, " done")
	print("min: point: ", dnatool.min_point, " normal: ", dnatool.min_normal)
	print("max: point: ", dnatool.max_point, " normal: ", dnatool.max_normal)
	print("cd: ", cd, " ncd: ", ncd)
	for e in diffmap.keys():
		for k in diffmap[e].keys():
			diffmap[e][k].triangles_v_uc = diffmap[e][k].triangles_v
			diffmap[e][k].triangles_n_uc = diffmap[e][k].triangles_n
			diffmap[e][k].triangles_v = compress_points(PoolVector3Array(diffmap[e][k].triangles_v), dnatool.min_point, dnatool.max_point)
			diffmap[e][k].triangles_n = compress_points(PoolVector3Array(diffmap[e][k].triangles_n), dnatool.min_normal, dnatool.max_normal)
			print_debug("mesh:", e, "shape: ", k, " triangle: ",
				diffmap[e][k].triangles_uv.size() / 3)
			if diffmap[e][k].triangles_uv.size() > 0:
				diffmap[e][k].rect = Rect2(diffmap[e][k].triangles_uv[0], Vector2())
			else:
				diffmap[e][k].rect = Rect2()
			for m in diffmap[e][k].triangles_uv:
				diffmap[e][k].rect = diffmap[e][k].rect.expand(m)
	for e in diffmap.keys():
		for h in diffmap[e].keys():
			print(e, ": ", h)
	create_queue(diffmap)
	print("prep done, ", draw_queue.size())
	$gen/drawable.connect("draw", self, "draw_viewport")
	total_count = draw_queue.size()
	$gen_maps/ProgressBar.value = 0.0
	connect("draw_finished", self, "draw_finished")

var total_count : = 0

func draw_viewport():
	var draw_obj = $gen/drawable
	if draw_queue.size() == 0:
		return

	var item = draw_queue[0]
	var default_color = Color(0.5, 0.5, 0.5, 1.0)
	var _min_point: Vector3
	var _max_point: Vector3
	if item.normals:
		_min_point = dnatool.min_normal
		_max_point = dnatool.max_normal
	else:
		_min_point = dnatool.min_point
		_max_point = dnatool.max_point
	default_color.r = range_lerp(0, _min_point.x, _max_point.x, 0.0, 1.0)
	default_color.g = range_lerp(0, _min_point.y, _max_point.y, 0.0, 1.0)
	default_color.b = range_lerp(0, _min_point.z, _max_point.z, 0.0, 1.0)
	draw_obj.draw_rect(Rect2(0, 0, dnatool.TEX_SIZE, dnatool.TEX_SIZE), default_color, true)
	print("draw: ", item.triangles_uv.size())
	for t in range(0, item.triangles_uv.size(), 3):
		var colors = []
		var uvs = []
		var p1 = item.triangles_uv[t + 0]
		var p2 = item.triangles_uv[t + 1]
		var p3 = item.triangles_uv[t + 2]
		var sum = p1 + p2 + p3
		var midp = sum / 3.0
		for k in range(3):
			var v = item.triangles_v[t + k]
			colors.push_back(Color(v.x, v.y, v.z, 1))
			var uv = item.triangles_uv[t + k]
			var pt = (uv - midp).normalized() * 3.5
			uvs.push_back(uv * dnatool.TEX_SIZE + pt)
		draw_obj.draw_polygon(PoolVector2Array(uvs), PoolColorArray(colors))
	yield(draw_obj.get_tree(), "idle_frame")
	yield(draw_obj.get_tree(), "idle_frame")
	yield(draw_obj.get_tree(), "idle_frame")
	yield(draw_obj.get_tree(), "idle_frame")
	emit_signal("draw_finished")


var _state = STATE_DRAW
var draw_delay: float = 0.01
var save_pngs : = true
func save_images():
	for k in maps.keys():
		for e in ["diffuse", "normal"]:
			var fn = "res://characters/common/" + k + "_" + e + "_new.png"
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

func draw_finished():
	print("draw_finished")
	draw_delay += 0.01
	_state = STATE_CHECK

func _process(delta):
	match(_state):
		STATE_IDLE:
			pass
		STATE_CHECK:
			if draw_delay > 0.0:
				draw_delay -= delta
			else:
				print("drawing complete: ", draw_queue.size())
				if draw_queue.size() > 0:
					dnatool.save_viewport($gen, maps, draw_queue[0].map, draw_queue[0].rect, draw_queue[0].normals)
					draw_queue.pop_front()
					$gen_maps/ProgressBar.value = 50.0 +  50.0 * (1.0 - float(draw_queue.size()) / float(total_count))
				if draw_queue.size() > 0:
					_state = STATE_DRAW
				else:
					_state = STATE_FINISH
		STATE_DRAW:
			print("triggering draw ", draw_queue.size())
			$gen.render_target_update_mode = Viewport.UPDATE_ONCE
			$gen/drawable.update()
			draw_delay += 0.01
			_state = STATE_IDLE
		STATE_FINISH:
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
			fd.store_var(uv_to_uv2)
			fd.close()
			if save_pngs:
				save_images()
			get_tree().quit()
