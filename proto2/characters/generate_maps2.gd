extends Control

var common = []
var common_path = "characters/common"

var min_point = Vector3()
var max_point = Vector3()
var min_normal = Vector3()
var max_normal = Vector3()

const TEX_SIZE: int = 512

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

func find_min_max(mesh: ArrayMesh):
	var shape_arrays = mesh.surface_get_blend_shape_arrays(0)
	var surf_arrays =  mesh.surface_get_arrays(0)
	if min_point.length() == 0.0:
		min_point = shape_arrays[0][ArrayMesh.ARRAY_VERTEX][0] - surf_arrays[ArrayMesh.ARRAY_VERTEX][0]
	if min_normal.length() == 0.0:
		min_normal = shape_arrays[0][ArrayMesh.ARRAY_NORMAL][0] - surf_arrays[ArrayMesh.ARRAY_NORMAL][0]
	if max_point.length() == 0.0:
		max_point = shape_arrays[0][ArrayMesh.ARRAY_VERTEX][0] - surf_arrays[ArrayMesh.ARRAY_VERTEX][0]
	if max_normal.length() == 0.0:
		max_point = shape_arrays[0][ArrayMesh.ARRAY_NORMAL][0] - surf_arrays[ArrayMesh.ARRAY_NORMAL][0]
	for sc in range(mesh.get_surface_count()):
		var bshapes: Array = mesh.surface_get_blend_shape_arrays(sc).duplicate(true)
		var arrays: Array = mesh.surface_get_arrays(sc).duplicate(true)
		for src in bshapes:
			for index in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
				var v: Vector3 = src[ArrayMesh.ARRAY_VERTEX][index] - arrays[ArrayMesh.ARRAY_VERTEX][index]
				var n: Vector3 = src[ArrayMesh.ARRAY_NORMAL][index] - arrays[ArrayMesh.ARRAY_NORMAL][index]
				for ipos in range(3):
					if min_point[ipos] > v[ipos]:
						min_point[ipos] = v[ipos] 
					if max_point[ipos] < v[ipos]:
						max_point[ipos] = v[ipos]
					if min_normal[ipos] > n[ipos]:
						min_normal[ipos] = n[ipos] 
					if max_normal[ipos] < n[ipos]:
						max_normal[ipos] = n[ipos]
	print("min: ", min_point, "max: ", max_point)

static func check_triangle(verts: Array, vs: Array, ns: Array) -> bool:
	var uv1 = verts[0]
	var uv2 = verts[1]
	var uv3 = verts[2]
	var v1 = uv1 - uv3
	var v2 = uv1 - uv3
	if v1.length() * TEX_SIZE < 1.2:
		return false
	if v2.length() * TEX_SIZE < 1.2:
		return false
	var sumdata = Vector3()
	for k in vs + ns:
		sumdata += k
	if sumdata.length() < 0.001:
		return false
	return true


func compress_points(v: PoolVector3Array, vmin: Vector3, vmax: Vector3) -> PoolVector3Array:
	var cd = vmax - vmin
	var ret: PoolVector3Array = v
	for e in range(v.size()):
		ret[e] = v[e] - vmin
		for h in range(3):
			ret[e][h] = ret[e][h] / cd[h]
	return ret
func build_triangles(mesh: ArrayMesh, diffmap: Dictionary):
	assert mesh
	assert max_point != min_point
	var cd = max_point - min_point
	var ncd = max_normal - min_normal
	for sc in range(mesh.get_surface_count()):
		var shape_arrays = mesh.surface_get_blend_shape_arrays(sc)
		var surf_arrays =  mesh.surface_get_arrays(sc)
		for bshape in range(shape_arrays.size()):
			var bs_name = mesh.get_blend_shape_name(bshape)
			if !diffmap.has(bs_name):
				diffmap[bs_name] = {}
				diffmap[bs_name].base_v = []
				diffmap[bs_name].shape_v = []
				diffmap[bs_name].triangles = []
				diffmap[bs_name].triangles_uv = []
				diffmap[bs_name].triangles_v = PoolVector3Array()
				diffmap[bs_name].triangles_n = PoolVector3Array()
			for vid in range(0, surf_arrays[ArrayMesh.ARRAY_INDEX].size(), 3):
				var p1_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 0]
				var p2_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 1]
				var p3_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 2]
				var p1 = surf_arrays[ArrayMesh.ARRAY_TEX_UV][p1_index]
				var p2 = surf_arrays[ArrayMesh.ARRAY_TEX_UV][p2_index]
				var p3 = surf_arrays[ArrayMesh.ARRAY_TEX_UV][p3_index]
				var base_v1 = surf_arrays[ArrayMesh.ARRAY_VERTEX][p1_index]
				var base_v2 = surf_arrays[ArrayMesh.ARRAY_VERTEX][p2_index]
				var base_v3 = surf_arrays[ArrayMesh.ARRAY_VERTEX][p3_index]
				var shape_v1 = shape_arrays[bshape][ArrayMesh.ARRAY_VERTEX][p1_index]
				var shape_v2 = shape_arrays[bshape][ArrayMesh.ARRAY_VERTEX][p2_index]
				var shape_v3 = shape_arrays[bshape][ArrayMesh.ARRAY_VERTEX][p3_index]
				var d1 = shape_v1 - base_v1
				var d2 = shape_v2 - base_v2
				var d3 = shape_v3 - base_v3
				var base_n1 = surf_arrays[ArrayMesh.ARRAY_NORMAL][p1_index]
				var base_n2 = surf_arrays[ArrayMesh.ARRAY_NORMAL][p2_index]
				var base_n3 = surf_arrays[ArrayMesh.ARRAY_NORMAL][p3_index]
				var shape_n1 = shape_arrays[bshape][ArrayMesh.ARRAY_NORMAL][p1_index]
				var shape_n2 = shape_arrays[bshape][ArrayMesh.ARRAY_NORMAL][p2_index]
				var shape_n3 = shape_arrays[bshape][ArrayMesh.ARRAY_NORMAL][p3_index]
				var nd1 = shape_n1 - base_n1
				var nd2 = shape_n2 - base_n2
				var nd3 = shape_n3 - base_n3
				var triangle = [p1_index, p2_index, p3_index]
				var triangle_uv = [p1, p2, p3]
#				var triangle_v = compress_points([d1, d2, d3], min_point, max_point)
#				var triangle_n = compress_points([nd1, nd2, nd3], min_normal, max_normal)
				var triangle_v = PoolVector3Array([d1, d2, d3])
				var triangle_n = PoolVector3Array([nd1, nd2, nd3])
				if check_triangle(triangle_uv, triangle_v, triangle_n):
					diffmap[bs_name].triangles += triangle
					diffmap[bs_name].base_v += [base_v1, base_v2, base_v3]
					diffmap[bs_name].shape_v += [shape_v1, shape_v2, shape_v3]
					diffmap[bs_name].triangles_uv += triangle_uv
					diffmap[bs_name].triangles_v += triangle_v
					diffmap[bs_name].triangles_n += triangle_n
#			print_debug("surface: ", sc, " shape: ", bs_name, "/", bshape,
#					" triangle: ", diffmap[bs_name].triangles_uv.size() / 3)

func convert_triangles(base: Dictionary, helper: Dictionary):
	pass

enum {STATE_DRAW, STATE_CHECK, STATE_FINISH}

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
			data = {}
			data.map = map_key
			data.normals = true
			data.triangles_uv = diffmap[k][map_name].triangles_uv
			data.triangles_v = diffmap[k][map_name].triangles_n
			data.rect = diffmap[k][map_name].rect
			draw_queue.push_back(data)

func _ready():
	load_data()
	var base_mesh = "base"
	var helper_meshes = ["robe_helper", "tights_helper", "skirt_helper"]
	var diffmap = {}
	for c in common:
		for mesh_name in [base_mesh] + helper_meshes:
			var obj = c.instance()
			var mesh = get_mesh(obj, mesh_name)
			find_min_max(mesh)
	for c in common:
		var obj = c.instance()
		if !diffmap.has(base_mesh):
			diffmap[base_mesh] = {}
		var mesh = get_mesh(obj, base_mesh)
		build_triangles(mesh, diffmap[base_mesh])
		print("scene: ", c, "mesh: ", base_mesh, " done")
		for mesh_name in helper_meshes:
			var helper_mesh = get_mesh(obj, mesh_name)
			if !diffmap.has(mesh_name):
				diffmap[mesh_name] = {}
			build_triangles(helper_mesh, diffmap[mesh_name])
			convert_triangles(diffmap[base_mesh], diffmap[mesh_name])
			print("scene: ", c, "mesh: ", mesh_name, " done")
		print("scene: ", c, " done")
	for e in diffmap.keys():
		for k in diffmap[e].keys():
			diffmap[e][k].triangles_v = compress_points(diffmap[e][k].triangles_v, min_point, max_point)
			diffmap[e][k].triangles_n = compress_points(diffmap[e][k].triangles_n, min_point, max_point)
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

var total_count : = 0

func save_viewport(shape_name: String, rect: Rect2, draw_normals: bool):
	var viewport: Viewport = $gen
	viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var vtex : = viewport.get_texture()
	var tex_img : = vtex.get_data()
	var fn = ""
	if !maps.has(shape_name):
		maps[shape_name] = {}
		maps[shape_name].width = tex_img.get_width()
		maps[shape_name].height = tex_img.get_height()
		maps[shape_name].format = tex_img.get_format()
	var byte_data = tex_img.duplicate(true).get_data()
	var image_size = byte_data.size()
	if draw_normals:
		maps[shape_name].image_normal_data = byte_data.compress(File.COMPRESSION_FASTLZ)
		maps[shape_name].image_normal_size = image_size
	else:
		maps[shape_name].image_data = byte_data.compress(File.COMPRESSION_FASTLZ)
		maps[shape_name].rect = rect.grow(0.003)
		maps[shape_name].image_size = image_size

func draw_viewport():
	var draw_obj = $gen/drawable
	if draw_queue.size() == 0:
		return

	var item = draw_queue[0]
	var default_color = Color(0.5, 0.5, 0.5, 1.0)
	var _min_point: Vector3
	var _max_point: Vector3
	if item.normals:
		_min_point = min_normal
		_max_point = max_normal
	else:
		_min_point = min_point
		_max_point = max_point
	default_color.r = range_lerp(0, _min_point.x, _max_point.x, 0.0, 1.0)
	default_color.g = range_lerp(0, _min_point.y, _max_point.y, 0.0, 1.0)
	default_color.b = range_lerp(0, _min_point.z, _max_point.z, 0.0, 1.0)
	draw_obj.draw_rect(Rect2(0, 0, TEX_SIZE, TEX_SIZE), default_color, true)
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
#			print(k.shape)
#			print(k.uv)
			var v = item.triangles_v[t + k]
			colors.push_back(Color(v.x, v.y, v.z, 1))
			var uv = item.triangles_uv[t + k]
			var pt = (uv - midp).normalized() * 3.5
			uvs.push_back(uv * TEX_SIZE + pt)
		draw_obj.draw_polygon(PoolVector2Array(uvs), PoolColorArray(colors))


var _state = STATE_DRAW
var draw_delay: float = 0.1
var save_pngs : = false
func save_images():
	for k in maps.keys():
		for e in ["diffuse", "normal"]:
			var fn = "res://characters/common/" + k + "_" + e + ".png"
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
func _process(delta):
	match(_state):
		STATE_CHECK:
			if draw_delay > 0.0:
				draw_delay -= delta
			elif draw_queue.size() > 0:
				save_viewport(draw_queue[0].map, draw_queue[0].rect, draw_queue[0].normals)
				print("drawing complete: ", draw_queue.size())
				draw_queue.pop_front()
				_state = STATE_DRAW
			else:
				_state = STATE_FINISH
		STATE_DRAW:
			$gen/drawable.update()
			draw_delay = 0.05
			_state = STATE_CHECK
		STATE_FINISH:
			print("generating same vert indices...")
			find_same_verts()
			var fd = File.new()
			fd.open("res://characters/common/config.bin", File.WRITE)
			fd.store_var(min_point)
			fd.store_var(max_point)
			fd.store_var(min_normal)
			fd.store_var(max_normal)
			fd.store_var(maps)
			fd.store_var(vert_indices)
			fd.close()
			if save_pngs:
				save_images()
			get_tree().quit()
