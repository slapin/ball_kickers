extends Reference
class_name DNATool

const TEX_SIZE: int = 512

var min_point = Vector3()
var max_point = Vector3()
var min_normal = Vector3()
var max_normal = Vector3()
var dna: DNA

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
	print("mesh: ", mesh.resource_name, "/", mesh, "min: ", min_point, "max: ", max_point)

func get_cd():
	return max_point - min_point

func get_ncd():
	return max_normal - min_normal

func save_viewport(v: Viewport, maps: Dictionary, shape_name: String, rect: Rect2, draw_normals: bool):
	var viewport: Viewport = v
#	viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
#	yield(viewport.get_tree(), "idle_frame")
#	yield(viewport.get_tree(), "idle_frame")
	var vtex : = viewport.get_texture()
	var tex_img : = vtex.get_data()
#	tex_img.flip_y()
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
				diffmap[bs_name].triangles_v = []
				diffmap[bs_name].triangles_n = []
			for vid in range(0, surf_arrays[ArrayMesh.ARRAY_INDEX].size(), 3):
				var p1_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 0]
				var p2_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 1]
				var p3_index = surf_arrays[ArrayMesh.ARRAY_INDEX][vid + 2]
				var p1 = surf_arrays[ArrayMesh.ARRAY_TEX_UV2][p1_index]
				var p2 = surf_arrays[ArrayMesh.ARRAY_TEX_UV2][p2_index]
				var p3 = surf_arrays[ArrayMesh.ARRAY_TEX_UV2][p3_index]
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
				var triangle_v = [d1, d2, d3]
				var triangle_n = [nd1, nd2, nd3]
				if check_triangle(triangle_uv, triangle_v, triangle_n):
					diffmap[bs_name].triangles += triangle
					diffmap[bs_name].base_v += [base_v1, base_v2, base_v3]
					diffmap[bs_name].shape_v += [shape_v1, shape_v2, shape_v3]
					diffmap[bs_name].triangles_uv += triangle_uv
					diffmap[bs_name].triangles_v += triangle_v
					diffmap[bs_name].triangles_n += triangle_n
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

func distance_to_tri(v: Vector3, v1: Vector3, v2: Vector3, v3: Vector3):
	var d1 = v.distance_squared_to(v1)
	var d2 = v.distance_squared_to(v2)
	var d3 = v.distance_squared_to(v3)
	return Vector3(d1, d2, d3).length_squared()

func convert_triangles(base: ArrayMesh, helper: ArrayMesh) -> ArrayMesh:
	var v2idxb = {}
	var v2idxh = {}
	var v2uv = {}
	var sc = 0
	var ret_mesh: = ArrayMesh.new()
	var base_surf_array = base.surface_get_arrays(sc)
	for idx in range(base_surf_array[ArrayMesh.ARRAY_VERTEX].size()):
		var v = base_surf_array[ArrayMesh.ARRAY_VERTEX][idx]
		v2idxb[v] = idx
	var helper_surf_array = helper.surface_get_arrays(sc)
	var bshapes = helper.surface_get_blend_shape_arrays(sc)
	for idx in range(helper_surf_array[ArrayMesh.ARRAY_VERTEX].size()):
		var v = helper_surf_array[ArrayMesh.ARRAY_VERTEX][idx]
		v2idxh[v] = idx
	# find 3 closest vertices on base mesh
	var best_idx = -1
	var best_dist = 1000.0
	for k in v2idxh.keys():
		for l in v2idxb.keys():
			var dst = k.distance_to(l)
			if dst < best_dist:
				best_idx = v2idxb[l]
				best_dist = dst
		var uvh = base_surf_array[ArrayMesh.ARRAY_TEX_UV2][best_idx]
		helper_surf_array[ArrayMesh.ARRAY_TEX_UV2][v2idxh[k]] = uvh
		for h in bshapes.size():
			bshapes[h][ArrayMesh.ARRAY_TEX_UV2][v2idxh[k]] = uvh
	for k in range(helper.get_blend_shape_count()):
		ret_mesh.add_blend_shape(helper.get_blend_shape_name(k))
		ret_mesh.blend_shape_mode
	ret_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, helper_surf_array, bshapes)
	return ret_mesh
func build_uv_to_uv2(mesh:ArrayMesh, sc: int) -> Dictionary:
	var uv2uv2 : = {}
	var surf_array : = mesh.surface_get_arrays(sc)
	for idx in range(surf_array[ArrayMesh.ARRAY_TEX_UV].size()):
		var uv = surf_array[ArrayMesh.ARRAY_TEX_UV][idx]
		var uv2 = surf_array[ArrayMesh.ARRAY_TEX_UV2][idx]
		uv2uv2[uv] = uv2
	return uv2uv2
