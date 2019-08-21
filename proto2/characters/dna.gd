extends Reference
class_name DNA

var min_point: Vector3 = Vector3()
var max_point: Vector3 = Vector3()
var min_normal: Vector3 = Vector3()
var max_normal: Vector3 = Vector3()
var maps : = {}
var vert_indices : = {}
var orig_body_mesh: ArrayMesh
var meshes : = {}
var clothes : = {}


func get_modifier_list() -> Array:
	return maps.keys()

func add_mesh(part_name: String, mesh: ArrayMesh, v_indices: Dictionary):
	meshes[part_name] = {
		"orig_mesh": mesh,
		"same_indices": v_indices
	}
func triangulate_uv(v0: Vector3, vs: PoolVector3Array, uvs: PoolVector2Array) -> Vector2:
	assert vs.size() == 3
	var d1: float = v0.distance_to(vs[0])
	var d2: float = v0.distance_to(vs[1])
	var d3: float = v0.distance_to(vs[2])
	var ln = max(d1, max(d2, d3))
	var v = Vector3(d1/ln, d2/ln, d3/ln)
	var midp : Vector2 = (uvs[0] + uvs[1] + uvs[2]) * 1.0 / 3.0
	var uv: Vector2 = midp.linear_interpolate(uvs[0], v.x) + midp.linear_interpolate(uvs[1], v.y) + midp.linear_interpolate(uvs[2], v.z)
	uv /= 3.0
	return uv

func _prepare_cloth(body_mesh: ArrayMesh, cloth_mesh: ArrayMesh) -> ArrayMesh:
	var arrays_cloth: Array = cloth_mesh.surface_get_arrays(0)
	if arrays_cloth[ArrayMesh.ARRAY_TEX_UV2] == null:
		var d: PoolVector2Array = PoolVector2Array()
		d.resize(arrays_cloth[ArrayMesh.ARRAY_VERTEX].size())
		assert d.size() > 0
		arrays_cloth[ArrayMesh.ARRAY_TEX_UV2] = d
	var arrays_body: Array = body_mesh.surface_get_arrays(0)
	var tmp: Dictionary = {}
	for vcloth in range(arrays_cloth[ArrayMesh.ARRAY_VERTEX].size()):
		for vbody in range(arrays_body[ArrayMesh.ARRAY_VERTEX].size()):
			var vc: Vector3 = arrays_cloth[ArrayMesh.ARRAY_VERTEX][vcloth]
			var vb: Vector3 = arrays_body[ArrayMesh.ARRAY_VERTEX][vbody]
			if vc.distance_to(vb) < 0.02:
				if tmp.has(vcloth):
					tmp[vcloth].push_back(vbody)
				else:
					tmp[vcloth] = [vbody]
	for k in tmp.keys():
		var vc: Vector3 = arrays_cloth[ArrayMesh.ARRAY_VERTEX][k]
		var res: Array = []
		for v in tmp[k]:
			var vb: Vector3 = arrays_body[ArrayMesh.ARRAY_VERTEX][v]
			var d1 = vc.distance_squared_to(vb)
			if res.size() >= 3:
				for mv in range(res.size()):
					var vb1: Vector3 = arrays_body[ArrayMesh.ARRAY_VERTEX][res[mv]]
					var d2 = vc.distance_squared_to(vb1)
					if d1 < d2 && !v in res:
						res[mv] = v
			else:
				if ! v in res:
					res.push_back(v)
		tmp[k] = res
		if res.size() == 3:
			var vtx: Vector3 = arrays_cloth[ArrayMesh.ARRAY_VERTEX][k]
			var bverts = PoolVector3Array()
			var buvs = PoolVector2Array()
			for e in res:
				var vb: Vector3 = arrays_body[ArrayMesh.ARRAY_VERTEX][e]
				var ub: Vector2 = arrays_body[ArrayMesh.ARRAY_TEX_UV][e]
				bverts.push_back(vb)
				buvs.push_back(ub)
			arrays_cloth[ArrayMesh.ARRAY_TEX_UV2][k] = triangulate_uv(vtx, bverts, buvs)
	var new_mesh : = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_cloth)
	return new_mesh

func add_cloth_mesh(cloth_name: String, cloth_helper: String, mesh: ArrayMesh):
	var new_mesh = _prepare_cloth(meshes.body.orig_mesh, mesh)
	add_mesh(cloth_name, new_mesh, {})
	clothes[cloth_name] = {}
	clothes[cloth_name].helper = cloth_helper
	return new_mesh
func add_body_mesh(mesh: ArrayMesh, same_indices: Dictionary):
	add_mesh("body", mesh, same_indices)

func modify_mesh(orig_mesh: ArrayMesh, v_indices: Dictionary) -> ArrayMesh:
	for k in maps.keys():
		maps[k].image.lock()
		maps[k].image_normal.lock()
	var surf : = 0
	var mod_mesh = ArrayMesh.new()
	var mrect: Rect2
	for k in maps.keys():
		if maps[k].value > 0.0001:
			if mrect:
				mrect = mrect.merge(maps[k].rect)
			else:
				mrect = maps[k].rect
	for surface in range(orig_mesh.get_surface_count()):
		var arrays: Array = orig_mesh.surface_get_arrays(surface)
		var uv_index: int = ArrayMesh.ARRAY_TEX_UV
		if arrays[ArrayMesh.ARRAY_TEX_UV2] && arrays[ArrayMesh.ARRAY_TEX_UV2].size() > 0:
			uv_index = ArrayMesh.ARRAY_TEX_UV2
		for index in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
			var v: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][index]
			var n: Vector3 = arrays[ArrayMesh.ARRAY_NORMAL][index]
			var uv: Vector2 = arrays[uv_index][index]
			if !mrect.has_point(uv):
				continue
			var diff : = Vector3()
			var diffn : = Vector3()
			for k in maps.keys():
				if !maps[k].rect.has_point(uv) || abs(maps[k].value) < 0.0001:
					continue
				var pos: Vector2 = Vector2(uv.x * maps[k].width, uv.y * maps[k].height)
				var offset: Color = maps[k].image.get_pixelv(pos)
				var offsetn: Color = maps[k].image_normal.get_pixelv(pos)
				var pdiff: Vector3 = Vector3(offset.r, offset.g, offset.b)
				var ndiff: Vector3 = Vector3(offsetn.r, offsetn.g, offsetn.b)
				for u in range(2):
					diff[u] = range_lerp(pdiff[u], 0.0, 1.0, min_point[u], max_point[u]) * maps[k].value
					diffn[u] = range_lerp(ndiff[u], 0.0, 1.0, min_normal[u], max_normal[u]) * maps[k].value
					if abs(diff[u]) < 0.0001:
						diff[u] = 0
				v -= diff
				n -= diffn
			arrays[ArrayMesh.ARRAY_VERTEX][index] = v
			arrays[ArrayMesh.ARRAY_NORMAL][index] = n.normalized()
		for v in v_indices.keys():
			if v_indices[v].size() <= 1:
				continue
			var vx: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][v_indices[v][0]]
			for idx in range(1, v_indices[v].size()):
				vx = vx.linear_interpolate(arrays[ArrayMesh.ARRAY_VERTEX][v_indices[v][idx]], 0.5)
			for idx in v_indices[v]:
				arrays[ArrayMesh.ARRAY_VERTEX][idx] = vx
			
		mod_mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, arrays)
		if orig_mesh.surface_get_material(surface):
			mod_mesh.surface_set_material(surface, orig_mesh.surface_get_material(surface).duplicate(true))
		surf += 1
	for k in maps.keys():
		maps[k].image.unlock()
		maps[k].image_normal.unlock()
	return mod_mesh
func modify_part(part_name) -> ArrayMesh:
	var mesh = meshes[part_name].orig_mesh
	var indices = meshes[part_name].same_indices
	return modify_mesh(mesh, indices)
func set_modifier_value(modifier: String, value: float):
	maps[modifier].value = value
func _init(path: String):
	var fd = File.new()
	fd.open(path, File.READ)
	min_point = fd.get_var()
	max_point = fd.get_var()
	min_normal = fd.get_var()
	max_normal = fd.get_var()
	maps = fd.get_var()
	print(maps.keys())
	vert_indices = fd.get_var()
	fd.close()
	print("min: ", min_point, " max: ", max_point)
	for k in maps.keys():
		print(k, ": ", maps[k].rect)
	for k in maps.keys():
		maps[k].image_normal = Image.new()
		var normal_data = maps[k].image_normal_data.decompress(maps[k].image_normal_size, File.COMPRESSION_FASTLZ)
		var data = maps[k].image_data.decompress(maps[k].image_size, File.COMPRESSION_FASTLZ)
		maps[k].image_normal.create_from_data(maps[k].width, maps[k].height, false, maps[k].format, normal_data)
		maps[k].image = Image.new()
		maps[k].image.create_from_data(maps[k].width, maps[k].height, false, maps[k].format, data)
		maps[k].value = 0.0
