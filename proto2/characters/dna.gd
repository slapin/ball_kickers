extends Reference
class_name DNA

#var min_point: Vector3 = Vector3()
#var max_point: Vector3 = Vector3()
#var min_normal: Vector3 = Vector3()
#var max_normal: Vector3 = Vector3()
var maps : = {}
#var vert_indices : = {}
var orig_body_mesh: ArrayMesh
var meshes : = {}
var clothes : = {}


func get_modifier_list() -> Array:
	var mod_list = []
	for e in maps.keys():
		if e.find(":") < 0:
			mod_list.push_back(e)
	return mod_list

func add_mesh(part_name: String, mesh: ArrayMesh, surface: int = 0, v_indices: Dictionary = {}):
	var arrays: Array = mesh.surface_get_arrays(surface)
	var mat: Material = mesh.surface_get_material(surface)
	meshes[part_name] = {
		"orig_mesh": mesh,
		"orig_arrays": arrays,
		"material": mat,
		"same_indices": v_indices
	}
func triangulate_uv(v0: Vector3, vs: PoolVector3Array, uvs: PoolVector2Array) -> Vector2:
	assert(vs.size() == 3)
	var d1: float = v0.distance_to(vs[0])
	var d2: float = v0.distance_to(vs[1])
	var d3: float = v0.distance_to(vs[2])
	var ln = max(d1, max(d2, d3))
	var v = Vector3(d1/ln, d2/ln, d3/ln)
	var midp : Vector2 = (uvs[0] + uvs[1] + uvs[2]) * 1.0 / 3.0
	var uv: Vector2 = midp.linear_interpolate(uvs[0], v.x) + midp.linear_interpolate(uvs[1], v.y) + midp.linear_interpolate(uvs[2], v.z)
	uv /= 3.0
	return uv

func _prepare_cloth(arrays_body: Array, arrays_cloth: Array) -> Array:
	if arrays_cloth[ArrayMesh.ARRAY_TEX_UV2] != null:
		return arrays_cloth
	else:
		var d: PoolVector2Array = PoolVector2Array()
		d.resize(arrays_cloth[ArrayMesh.ARRAY_VERTEX].size())
		assert(d.size() > 0)
		arrays_cloth[ArrayMesh.ARRAY_TEX_UV2] = d
	var tmp: Dictionary = {}
	for vcloth in range(arrays_cloth[ArrayMesh.ARRAY_VERTEX].size()):
		for vbody in range(arrays_body[ArrayMesh.ARRAY_VERTEX].size()):
			var vc: Vector3 = arrays_cloth[ArrayMesh.ARRAY_VERTEX][vcloth]
			var vb: Vector3 = arrays_body[ArrayMesh.ARRAY_VERTEX][vbody]
			if vc.distance_to(vb) < 0.8:
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
	return arrays_cloth

func add_cloth_mesh(cloth_name: String, cloth_helper: String, mesh: ArrayMesh) -> Array:
	add_mesh(cloth_name, mesh, 0, {})
	var cloth_array = _prepare_cloth(meshes.body.orig_arrays, meshes[cloth_name].orig_arrays)
	meshes[cloth_name].orig_arrays = cloth_array
	clothes[cloth_name] = {}
	meshes[cloth_name].helper = cloth_helper
	var modifiers = {}
	for k in get_modifier_list():
		var helper = meshes[cloth_name].helper
		if helper == "body":
			helper = ""
		var mod = k
		if helper.length() > 0:
			mod = helper + ":" + k
			if !maps.has(mod):
				mod = k
		print("adding modifier for ", cloth_name, " name: ", mod)
		modifiers[k] = get_mesh_modifier(mod, cloth_array)
		print(cloth_name, ": ", k, ": size: ", modifiers[k][0].size())
	meshes[cloth_name].modifiers = modifiers
	return cloth_array
func add_body_mesh(mesh: ArrayMesh, same_indices: Dictionary) -> Array:
	add_mesh("body", mesh, 0, same_indices)
	var modifiers = {}
	for k in get_modifier_list():
		modifiers[k] = get_mesh_modifier(k, meshes["body"].orig_arrays)
	meshes["body"].modifiers = modifiers
	meshes["body"].helper = ""
	return meshes["body"].orig_arrays

#func __modify_mesh(orig_mesh: ArrayMesh, v_indices: Dictionary) -> ArrayMesh:
#	for k in maps.keys():
#		maps[k].image.lock()
#		maps[k].image_normal.lock()
#	var surf : = 0
#	var mod_mesh = ArrayMesh.new()
#	var mrect: Rect2
#	for k in maps.keys():
#		if maps[k].value > 0.0001:
#			if mrect:
#				mrect = mrect.merge(maps[k].rect)
#			else:
#				mrect = maps[k].rect
#	for surface in range(orig_mesh.get_surface_count()):
#		var arrays: Array = orig_mesh.surface_get_arrays(surface)
#		var uv_index: int = ArrayMesh.ARRAY_TEX_UV
#		if arrays[ArrayMesh.ARRAY_TEX_UV2] && arrays[ArrayMesh.ARRAY_TEX_UV2].size() > 0:
#			uv_index = ArrayMesh.ARRAY_TEX_UV2
#		for index in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
#			var v: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][index]
#			var n: Vector3 = arrays[ArrayMesh.ARRAY_NORMAL][index]
#			var uv: Vector2 = arrays[uv_index][index]
#			if !mrect.has_point(uv):
#				continue
#			var diff : = Vector3()
#			var diffn : = Vector3()
#			for k in maps.keys():
#				if !maps[k].rect.has_point(uv) || abs(maps[k].value) < 0.0001:
#					continue
#				var pos: Vector2 = Vector2(uv.x * maps[k].width, uv.y * maps[k].height)
#				var offset: Color = maps[k].image.get_pixelv(pos)
#				var offsetn: Color = maps[k].image_normal.get_pixelv(pos)
#				var pdiff: Vector3 = Vector3(offset.r, offset.g, offset.b)
#				var ndiff: Vector3 = Vector3(offsetn.r, offsetn.g, offsetn.b)
#				for u in range(3):
#					diff[u] = range_lerp(pdiff[u], 0.0, 1.0, min_point[u], max_point[u]) * maps[k].value
#					diffn[u] = range_lerp(ndiff[u], 0.0, 1.0, min_normal[u], max_normal[u]) * maps[k].value
#					if abs(diff[u]) < 0.0001:
#						diff[u] = 0
#				v -= diff
#				n -= diffn
#			arrays[ArrayMesh.ARRAY_VERTEX][index] = v
#			arrays[ArrayMesh.ARRAY_NORMAL][index] = n.normalized()
#		for v in v_indices.keys():
#			if v_indices[v].size() <= 1:
#				continue
#			var vx: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][v_indices[v][0]]
#			for idx in range(1, v_indices[v].size()):
#				vx = vx.linear_interpolate(arrays[ArrayMesh.ARRAY_VERTEX][v_indices[v][idx]], 0.5)
#			for idx in v_indices[v]:
#				arrays[ArrayMesh.ARRAY_VERTEX][idx] = vx
#
#		mod_mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, arrays)
#		if orig_mesh.surface_get_material(surface):
#			mod_mesh.surface_set_material(surface, orig_mesh.surface_get_material(surface).duplicate(true))
#		surf += 1
#	for k in maps.keys():
#		maps[k].image.unlock()
#		maps[k].image_normal.unlock()
#	return mod_mesh
#func modify_part(part_name) -> ArrayMesh:
##	var mesh = meshes[part_name].orig_mesh
##	var indices = meshes[part_name].same_indices
##	return modify_mesh(mesh, indices)
#	return _mod_part(part_name)
#func set_modifier_value(modifier: String, value: float):
#	maps[modifier].value = value
#func get_mesh_modifier(m_name: String, arrays: Array) -> Array:
#	maps[m_name].image.lock()
#	maps[m_name].image_normal.lock()
#	var indices = PoolIntArray()
#	var mod_vertex = PoolVector3Array()
#	var mod_normal = PoolVector3Array()
#	var uv_index: int = ArrayMesh.ARRAY_TEX_UV
#	if arrays[ArrayMesh.ARRAY_TEX_UV2] && arrays[ArrayMesh.ARRAY_TEX_UV2].size() > 0:
#		uv_index = ArrayMesh.ARRAY_TEX_UV2
#	var mrect: Rect2 = maps[m_name].rect
#	var count = 0
#	var max_count = arrays[ArrayMesh.ARRAY_VERTEX].size()
#	var width: int = maps[m_name].width
#	var height: int = maps[m_name].height
#	indices.resize(max_count)
#	mod_vertex.resize(max_count)
#	mod_normal.resize(max_count)
#	if uv_index != ArrayMesh.ARRAY_TEX_UV2:
#		print("not on uv2")
#	for index in range(arrays[ArrayMesh.ARRAY_VERTEX].size()):
#		var uv: Vector2 = arrays[uv_index][index]
#		if !mrect.has_point(uv):
#			continue
#		var diff: = Vector3()
#		var diffn: = Vector3()
#		var pos: Vector2 = Vector2(uv.x * width, uv.y * height)
#		var offset: Color = maps[m_name].image.get_pixelv(pos)
#		var offsetn: Color = maps[m_name].image_normal.get_pixelv(pos)
#		var pdiff: Vector3 = Vector3(offset.r, offset.g, offset.b)
#		var ndiff: Vector3 = Vector3(offsetn.r, offsetn.g, offsetn.b)
#		for u in range(3):
#			diff[u] = range_lerp(pdiff[u], 0.0, 1.0, maps[m_name].min_point[u], maps[m_name].min_point[u] + maps[m_name].point_scaler[u])
#			diffn[u] = range_lerp(ndiff[u], 0.0, 1.0, maps[m_name].min_normal[u], maps[m_name].min_normal[u] + maps[m_name].normal_scaler[u])
#			if abs(diff[u]) < 0.0001:
#				diff[u] = 0
#		if diff.length() > 0.001:
#			indices[count] = index
#			mod_vertex[count] = diff
#			mod_normal[count] = diffn
#			count += 1
#	indices.resize(count)
#	mod_vertex.resize(count)
#	mod_normal.resize(count)
#	maps[m_name].image.unlock()
#	maps[m_name].image_normal.unlock()
#	return [indices, mod_vertex, mod_normal]
#func apply_modifier(mod: Array, arrays: Array, value: float, offset = 0.0):
#		var value_: float = clamp(value, 0.0, 1.0)
#		var indices: PoolIntArray = mod[0]
#		var mod_vertex: PoolVector3Array = mod[1]
#		var mod_normal: PoolVector3Array = mod[2]
#		for count in range(indices.size()):
#			var index: int = indices[count]
#			var diff: Vector3 = mod_vertex[count]
#			var diffn: Vector3 = mod_normal[count]
#			var n = (arrays[ArrayMesh.ARRAY_NORMAL][index] - diffn).normalized() * offset
#			arrays[ArrayMesh.ARRAY_VERTEX][index] -= diff * value_ - n
#			# do not normalize now
#			arrays[ArrayMesh.ARRAY_NORMAL][index] -= diffn * value_
#func _mod_part(part_name: String) -> ArrayMesh:
#	print("modifying ", part_name)
#	print("helper:", meshes[part_name].helper)
#	var start_time = OS.get_unix_time()
##	var mesh: ArrayMesh = meshes[part_name].orig_mesh
#	var mod_mesh: = ArrayMesh.new()
#	var indices: Dictionary = meshes[part_name].same_indices
#	var surface: int = 0
#	if meshes[part_name].has("surface"):
#		surface = meshes[part_name].surface
##	var arrays: Array = mesh.surface_get_arrays(surface)
#	var arrays: Array = meshes[part_name].orig_arrays.duplicate()
#	if part_name == "body":
#		for mod in meshes[part_name].modifiers.keys():
#			var mod_data = meshes[part_name].modifiers[mod]
#			apply_modifier(mod_data, arrays, maps[mod].value)
#	else:
#		for mod in meshes[part_name].modifiers.keys():
#			var mod_data = meshes[part_name].modifiers[mod]
#			apply_modifier(mod_data, arrays, maps[mod].value, 0.0002)
#	for v in indices.keys():
#		if indices[v].size() <= 1:
#			continue
#		var vx: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][indices[v][0]]
#		for idx in range(1, indices[v].size()):
#			vx = vx.linear_interpolate(arrays[ArrayMesh.ARRAY_VERTEX][indices[v][idx]], 0.5)
#		for idx in indices[v]:
#			arrays[ArrayMesh.ARRAY_VERTEX][idx] = vx
#	mod_mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, arrays)
#	if meshes[part_name].material:
#		mod_mesh.surface_set_material(surface, meshes[part_name].material.duplicate(true))
##	if mesh.surface_get_material(surface):
##		mod_mesh.surface_set_material(surface, mesh.surface_get_material(surface).duplicate(true))
#	var elapsed = OS.get_unix_time() - start_time
#	print("modified ", part_name, " ", elapsed)
#	return mod_mesh

#func load_maps(path: String):
#	maps = {}
#	var fd: File = File.new()
#	fd.open(path, File.READ)
#	if !fd.is_open():
#		print("Could not open " + path)
#	print(fd.get_len())
#	var count = fd.get_var()
#	print(count)
#	for c in range(count):
#		var map_name = fd.get_var()
#		map_name = map_name.replace("base:", "")
#		var rect = fd.get_var()
#		var map_min_point = fd.get_var()
#		var point_scaler = fd.get_var()
#		var map_min_normal = fd.get_var()
#		var normal_scaler = fd.get_var()
#		var map_width = fd.get_var()
#		var map_height = fd.get_var()
#		var data_size = fd.get_var()
#		var data = fd.get_var()
#		var map_normal_width = fd.get_var()
#		var map_normal_height = fd.get_var()
#		var normal_data_size = fd.get_var()
#		var normal_data = fd.get_var()
#		maps[map_name] = {}
#		maps[map_name].rect = rect
#		maps[map_name].min_point = map_min_point
#		maps[map_name].point_scaler = point_scaler
#		maps[map_name].min_normal = map_min_normal
#		maps[map_name].normal_scaler = normal_scaler
#		maps[map_name].width = map_width
#		maps[map_name].height = map_height
#		maps[map_name].normal_width = map_normal_width
#		maps[map_name].normal_height = map_normal_height
#		data = data.decompress(data_size, File.COMPRESSION_DEFLATE)
#		maps[map_name].image = Image.new()
#		maps[map_name].image.create_from_data(maps[map_name].width, maps[map_name].height, false, Image.FORMAT_RGB8, data)
#		normal_data = normal_data.decompress(normal_data_size, File.COMPRESSION_DEFLATE)
#		maps[map_name].image_normal = Image.new()
#		maps[map_name].image_normal.create_from_data(maps[map_name].normal_width, maps[map_name].normal_height, false, Image.FORMAT_RGB8, normal_data)
#		print(map_name, " ", map_width, " ", map_height, " ", data_size, " ", data.size(), " ", map_normal_width, " ", map_normal_height, " ", normal_data_size, " ", normal_data.size())
#		maps[map_name].value = 0.0
#	fd.close()

#func _init(path: String):
#	load_maps("res://characters/blendmaps.bin")
#	var fd = File.new()
#	fd.open(path, File.READ)
#	min_point = fd.get_var()
#	max_point = fd.get_var()
#	min_normal = fd.get_var()
#	max_normal = fd.get_var()
#	maps = fd.get_var()
##	print(maps.keys())
##	vert_indices = fd.get_var()
#	fd.close()
#	print("min: ", min_point, " max: ", max_point)
##	for k in maps.keys():
##		print(k, ": ", maps[k].rect)
#	for k in maps.keys():
#		maps[k].image_normal = Image.new()
#		var normal_data = maps[k].image_normal_data.decompress(maps[k].image_normal_size, File.COMPRESSION_FASTLZ)
#		var data = maps[k].image_data.decompress(maps[k].image_size, File.COMPRESSION_FASTLZ)
#		maps[k].image_normal.create_from_data(maps[k].width, maps[k].height, false, maps[k].format, normal_data)
#		maps[k].image = Image.new()
#		maps[k].image.create_from_data(maps[k].width, maps[k].height, false, maps[k].format, data)
#		maps[k].value = 0.0
