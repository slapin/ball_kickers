extends Reference
class_name DNATool

const TEX_SIZE: int = 512

var min_point = Vector3()
var max_point = Vector3()
var min_normal = Vector3()
var max_normal = Vector3()
var dna: DNA

var vert_indices = {}

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
	var ret: MeshInstance
	while queue.size() > 0:
		var item = queue.pop_front()
		if item is MeshInstance && item.name == mesh_name && item.mesh:
			ret = item
			break
		for c in item.get_children():
			queue.push_back(c)
	return ret

func find_same_verts(characters: Array):
	for chdata in range(characters.size()):
		var ch_scene = characters[chdata].instance()
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
func find_min_max_dict(d: Dictionary):
	if d.triangles_v.size() == 0:
		return
	if d.triangles_n.size() == 0:
		return
	if min_point.length() == 0.0:
		min_point = d.triangles_v[0]
	if max_point.length() == 0.0:
		max_point = d.triangles_v[0]
	if min_normal.length() == 0.0:
		min_normal = d.triangles_n[0]
	if max_normal.length() == 0.0:
		max_normal = d.triangles_n[0]
	for v in d.triangles_v:
		for ipos in range(3):
			if min_point[ipos] > v[ipos]:
				min_point[ipos] = v[ipos] 
			if max_point[ipos] < v[ipos]:
				max_point[ipos] = v[ipos]
	for n in d.triangles_n:
		for ipos in range(3):
			if min_normal[ipos] > n[ipos]:
				min_normal[ipos] = n[ipos] 
			if max_normal[ipos] < n[ipos]:
				max_normal[ipos] = n[ipos]

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
	assert(mesh)
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

func distance_to_tri(v: Vector3, v1: Vector3, v2: Vector3, v3: Vector3):
	var d1 = v.distance_squared_to(v1)
	var d2 = v.distance_squared_to(v2)
	var d3 = v.distance_squared_to(v3)
	return Vector3(d1, d2, d3).length_squared()

#class SparsePointGrid extends Reference:
#	var items = {}
#	var grid_size = 0.1
#	var grid_max: int = 1000
#	func add_point(point: Vector3, id: int):

func find_closest_triangle(v3: Vector3, arrays: Array):
	var tri : = -1
	var distance : = -1.0
	for vid in range(0, arrays[ArrayMesh.ARRAY_INDEX].size(), 3):
		var index = arrays[ArrayMesh.ARRAY_INDEX][vid]
		var p1 = arrays[ArrayMesh.ARRAY_VERTEX][index + 0]
		var p2 = arrays[ArrayMesh.ARRAY_VERTEX][index + 1]
		var p3 = arrays[ArrayMesh.ARRAY_VERTEX][index + 2]
		var d1 = v3.distance_squared_to(p1)
		var d2 = v3.distance_squared_to(p2)
		var d3 = v3.distance_squared_to(p3)
		var mind = min(d1, min(d2, d3))
		if distance < 0 || distance > mind:
			distance = mind
			tri = vid
	return tri

func get_triangle_area(v1, v2, v3) -> float:
	var a: Vector3 = v2 - v1
	var b: Vector3 = v3 - v1
	return a.cross(b).length() / 2.0

func get_baricentric(pt, v1, v2, v3) -> Vector3:
	var n = (v2 - v1).cross(v3 - v1)
	var d = n.dot(v1)
	var denom = n.dot(n)
#	print_debug("triangle: ", v1, " ", v2, " ", v3, " pt: ", pt, " normal: ", n, " d: ", d, " denom: ", denom)
	var t = (-n.dot(pt) + d) / denom
	var p = pt + t * n
#	print_debug("t: ", t, " p: ", p)
	var area = get_triangle_area(v1, v2, v3)
	var c = get_triangle_area(v1, v2, p)
	c = get_triangle_area(v2, v3, p)
	var u = c / area
	c = get_triangle_area(v3, v1, p)
	var v = c / area
	return Vector3(u, v, 1 - u - v)

class TriGrid extends Reference:
	var grid_size = 0.1
	var d = 100
	var grid = {}
	func point_id(p: Vector3) -> int:
		var point_x: int = int(p.x / grid_size)
		var point_y: int = int(p.y / grid_size)
		var point_z: int = int(p.z / grid_size)
		var ret: int = point_x + d * point_y + d * d * point_z
		return ret
	func get_tri_aabb(triangle: Array):
		var ret: AABB = AABB(triangle[0], Vector3())
		for h in triangle:
			ret = ret.expand(h)
		return ret
	func get_center(id: int) -> Vector3:
		assert(grid.has(id))
		var aabb: AABB = grid[id].aabb
		return aabb.position + aabb.size / 2.0
	func get_radius(id: int) -> float:
		assert(grid.has(id))
		var aabb: AABB = grid[id].aabb
		return aabb.get_longest_axis_size() * 1.4
	func min_distance(p: Vector3, id: int) -> float:
		var center : = get_center(id)
		var radius : = get_radius(id)
		var dist = p.distance_squared_to(center)
		var ret: float = dist - radius * radius
		if ret < 0.0:
			ret = 0.0
		return ret
	func radius_search(p: Vector3, radius: float) -> Array:
		var ret = []
		var r_sq = radius * radius
		for k in grid.keys():
			var item = grid[k]
			if min_distance(p, k) < r_sq:
				for tid in range(item.triangles.size()):
					var cur_tri = item.triangles[tid]
					var ok: bool = false
					for pt in cur_tri:
						if p.distance_squared_to(pt) < r_sq:
							ok = true
							break
					if ok:
						var cur_tri_id = PoolIntArray(item.triangle_ids[tid])
						if not cur_tri_id in ret:
							ret.push_back(cur_tri_id)
		return ret

	func add_triangle(triangle: Array, triangle_id: Array):
		for p in range(3):
			var pt = triangle[p]
			var id = triangle_id[p]
			var grid_id = point_id(pt)
			if grid.has(grid_id):
				var item = grid[grid_id]
				var item_aabb: AABB = item.aabb
				var xaabb = get_tri_aabb(triangle)
				item_aabb = item_aabb.merge(xaabb)
				item.aabb = item_aabb
				item.triangles.push_back(triangle)
				item.triangle_ids.push_back(triangle_id)
				grid[grid_id] = item
			else:
				var item = {}
				item.aabb = get_tri_aabb(triangle)
				item.triangles = [triangle]
				item.triangle_ids = [triangle_id]
				grid[grid_id] = item

func partition_mesh(mesh: ArrayMesh, surface: int = 0) -> TriGrid:
	var array = mesh.surface_get_arrays(surface)
	var items = []
	var item = {}
	var trigrid : = TriGrid.new()
	for id in range(0, array[ArrayMesh.ARRAY_INDEX].size(), 3):
		var index1 = array[ArrayMesh.ARRAY_INDEX][id]
		var index2 = array[ArrayMesh.ARRAY_INDEX][id + 1]
		var index3 = array[ArrayMesh.ARRAY_INDEX][id + 2]
		var p1 : Vector3 = array[ArrayMesh.ARRAY_VERTEX][index1]
		var p2 : Vector3 = array[ArrayMesh.ARRAY_VERTEX][index2]
		var p3 : Vector3 = array[ArrayMesh.ARRAY_VERTEX][index3]
		var triangle = [p1, p2, p3]
		var triangle_id = [index1, index2, index3]
		trigrid.add_triangle(triangle, triangle_id)
	return trigrid
func check_normal(n: Vector3, normals: PoolVector3Array) -> bool:
	for nt in normals:
		if n.dot(nt) < 0:
			return false
	return true

	
func create_common2gender(base_mesh: ArrayMesh, gender_mesh: ArrayMesh):
	var start_time = OS.get_unix_time()
	var surface : = 0
	var base_array = base_mesh.surface_get_arrays(surface)
	var gender_array = gender_mesh.surface_get_arrays(surface)
	var diffmap : = {}
#	var base_trigrid = partition_mesh(base_mesh)
#	var gender_trigrid = partition_mesh(gender_mesh)
	diffmap.base_v = []
	diffmap.shape_v = []
	diffmap.triangles = []
	diffmap.triangles_uv = []
	diffmap.triangles_v = []
	diffmap.triangles_n = []
	var shape_vertices: = PoolVector3Array()
	var shape_normals: = PoolVector3Array()
#	var shape_uvs: = PoolVector2Array()
	print("looking for exact points...")
	var exact_points : = PoolIntArray()
	exact_points.resize(base_array[ArrayMesh.ARRAY_TEX_UV2].size())
	for k in range(exact_points.size()):
		exact_points[k] = -1
	var dst_check = 0.0001
	var dst_sq_check = dst_check * dst_check
	var pd1: PoolVector2Array = base_array[ArrayMesh.ARRAY_TEX_UV2]
	var pd2: PoolVector2Array = gender_array[ArrayMesh.ARRAY_TEX_UV]
	var pa1 = Array(pd1)
	var pa2 = Array(pd2)
	
	var pdata1 = PoolVector2Array(pa1)
	var pdata2 = PoolVector2Array(pa2)
	for vid in range(pdata1.size()):
		for gid in range(pdata2.size()):
			var vb: Vector2 = pdata1[vid]
			var vg: Vector2 = pdata2[gid]
			if vb.distance_squared_to(vg) < dst_sq_check:
				exact_points[vid] = gid
		if vid % 100 == 0:
			print("vertex: ", vid)
#			print("vertex: ", vid, " ", exact_points.keys().size())
	print("looking for best vertices:")
	var bad_verts : = 0
	var triangles = {}
	var buckets = [
		{
			"dir": [Vector3(-1, 0, 0), Vector3(0, 0, 1)],
			"triangles": PoolIntArray()
		},
		{
			"dir": [Vector3(-1, 0, 0), Vector3(0, 0, -1)],
			"triangles": PoolIntArray()
		},
		{
			"dir": [Vector3(1, 0, 0), Vector3(0, 0, 1)],
			"triangles": PoolIntArray()
		},
		{
			"dir": [Vector3(1, 0, 0), Vector3(0, 0, -1)],
			"triangles": PoolIntArray()
		}
	]
	print("partitioning...")
	var p_start_time = OS.get_unix_time()
	var tcount = 0
	for idx in range(0, gender_array[ArrayMesh.ARRAY_INDEX].size(), 3):
		if tcount % 400 == 0:
			print("index: ", tcount)
		var index1 = gender_array[ArrayMesh.ARRAY_INDEX][idx]
		var index2 = gender_array[ArrayMesh.ARRAY_INDEX][idx + 1]
		var index3 = gender_array[ArrayMesh.ARRAY_INDEX][idx + 2]
		if index1 in exact_points && index2 in exact_points && index3 in exact_points:
			continue
		var ng1: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][index1]
		var ng2: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][index2]
		var ng3: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][index3]
		var normals = [ng1, ng2, ng3]
		var indices = PoolIntArray([index1, index2, index3])
		var tn = (ng1 + ng2 + ng3).normalized()
		for mb in range(buckets.size()):
			if check_normal(tn, buckets[mb].dir):
				var nt = Array(buckets[mb].triangles) + Array(indices)
				buckets[mb].triangles = PoolIntArray(nt)
#				print("k ", " ", indices.size(), " ", buckets[mb].triangles.size())
#				break
#				for r in range(indices.size()):
#					buckets[mb].triangles.push_back(indices[r])
		tcount += 1

	var p_end_time = OS.get_unix_time()
	print(p_end_time - p_start_time)
	for mb in range(buckets.size()):
		print(buckets[mb].dir, buckets[mb].triangles.size())
#	var p_start_time = OS.get_unix_time()
#	for vid in range(0, base_array[ArrayMesh.ARRAY_VERTEX].size()):
#		var pt = base_array[ArrayMesh.ARRAY_VERTEX][vid]
#		var nb: Vector3 = base_array[ArrayMesh.ARRAY_NORMAL][vid]
#		for idx in range(0, gender_array[ArrayMesh.ARRAY_INDEX].size(), 3):
#			var index1 = gender_array[ArrayMesh.ARRAY_INDEX][idx]
#			var index2 = gender_array[ArrayMesh.ARRAY_INDEX][idx + 1]
#			var index3 = gender_array[ArrayMesh.ARRAY_INDEX][idx + 2]
#			var ng1: Vector3 = gender_array[ArrayMesh.ARRAY_VERTEX][index1]
#			var ng2: Vector3 = gender_array[ArrayMesh.ARRAY_VERTEX][index2]
#			var ng3: Vector3 = gender_array[ArrayMesh.ARRAY_VERTEX][index3]
#			var normals = [ng1, ng2, ng3]
#			var indices = PoolIntArray([index1, index2, index3])
#			for mb in range(buckets.size()):
#				for t in range(normals.size()):
#					if buckets[mb].dir.dot(normals[t]) > 0:
#						buckets[mb].triangles.append_array(indices)
#	var p_end_time = OS.get_unix_time()
#	print(p_end_time - p_start_time)
	print("building...")
	for vid in range(0, base_array[ArrayMesh.ARRAY_VERTEX].size()):
#		if vid in exact_points.keys():
#			continue
		if exact_points[vid] != -1:
			var new_vertex = gender_array[ArrayMesh.ARRAY_VERTEX][exact_points[vid]]
			var new_normal = gender_array[ArrayMesh.ARRAY_NORMAL][exact_points[vid]]
			shape_vertices.push_back(new_vertex)
			shape_normals.push_back(new_normal)
			continue
		var best_triangle : = {}
		var best_distance : = 1000000.0
		var pt = base_array[ArrayMesh.ARRAY_VERTEX][vid]
		var nb: Vector3 = base_array[ArrayMesh.ARRAY_NORMAL][vid]
#		var triangles = gender_trigrid.radius_search(pt, 1.0)
#		print(triangles.size())
		var indices: PoolIntArray

		for mb in range(buckets.size()):
			if check_normal(nb, buckets[mb].dir):
				indices = PoolIntArray(Array(indices) + Array(buckets[mb].triangles))
		if vid % 100 == 0:
			print("vertex: ", vid, " ", indices.size())
		for idx in range(0, indices.size(), 3):
			var index1 = indices[idx]
			var ng: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][index1]
			if nb.dot(ng) < 0:
				continue
			var index2 = indices[idx + 1]
			var index3 = indices[idx + 2]
			var p1 = gender_array[ArrayMesh.ARRAY_VERTEX][index1]
			var p2 = gender_array[ArrayMesh.ARRAY_VERTEX][index2]
			var p3 = gender_array[ArrayMesh.ARRAY_VERTEX][index3]
			var bc : = get_baricentric(pt, p1, p2, p3)
			if bc.length() < best_distance:
				best_distance = bc.length()
				best_triangle.triangle = [index1, index2, index3]
				best_triangle.triangle_v = [p1, p2, p3]
				best_triangle.baricentric = bc
		if best_triangle.empty():
			shape_vertices.push_back(pt)
			bad_verts += 1
#			shape_uvs.push_back(base_array[ArrayMesh.ARRAY_TEX_UV2][vid])
			continue
		var bc: Vector3 = best_triangle.baricentric
		var v = best_triangle.triangle_v
		var t = best_triangle.triangle
		var new_vertex: Vector3 = v[0] * bc.x + v[1] * bc.y + v[2] * bc.z
		var n1: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][t[0]]
		var n2: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][t[1]]
		var n3: Vector3 = gender_array[ArrayMesh.ARRAY_NORMAL][t[2]]
		var new_normal: Vector3 = n1 * bc.x + n2 * bc.y + n3 * bc.z
#		var uv1 = gender_array[ArrayMesh.ARRAY_TEX_UV2][t[0]]
#		var uv2 = gender_array[ArrayMesh.ARRAY_TEX_UV2][t[1]]
#		var uv3 = gender_array[ArrayMesh.ARRAY_TEX_UV2][t[2]]
#		var new_uv: Vector2 = uv1 * bc.x + uv2 * bc.y + uv3 * bc.z
		shape_vertices.push_back(new_vertex)
		shape_normals.push_back(new_normal)
#		shape_uvs.push_back(new_uv)
	print("bad verts: ", bad_verts)
	print("building diffmap data")
	for xid in range(0, base_array[ArrayMesh.ARRAY_INDEX].size(), 3):
		if xid % 100 == 0:
			print("vertex: ", xid)
		var p1_index = base_array[ArrayMesh.ARRAY_INDEX][xid + 0]
		var p2_index = base_array[ArrayMesh.ARRAY_INDEX][xid + 1]
		var p3_index = base_array[ArrayMesh.ARRAY_INDEX][xid + 2]
		var p1 = base_array[ArrayMesh.ARRAY_TEX_UV2][p1_index]
		var p2 = base_array[ArrayMesh.ARRAY_TEX_UV2][p2_index]
		var p3 = base_array[ArrayMesh.ARRAY_TEX_UV2][p3_index]
		var base_v1 = base_array[ArrayMesh.ARRAY_VERTEX][p1_index]
		var base_v2 = base_array[ArrayMesh.ARRAY_VERTEX][p2_index]
		var base_v3 = base_array[ArrayMesh.ARRAY_VERTEX][p3_index]
		var bv = [base_v1, base_v2, base_v3]
		var shape_v1 = shape_vertices[p1_index]
		var shape_v2 = shape_vertices[p2_index]
		var shape_v3 = shape_vertices[p3_index]
		var sv = [shape_v1, shape_v2, shape_v3]
		var base_n1 = base_array[ArrayMesh.ARRAY_NORMAL][p1_index]
		var base_n2 = base_array[ArrayMesh.ARRAY_NORMAL][p2_index]
		var base_n3 = base_array[ArrayMesh.ARRAY_NORMAL][p3_index]
		var bn = [base_n1, base_n2, base_n3]
		var shape_n1 = shape_normals[p1_index]
		var shape_n2 = shape_normals[p2_index]
		var shape_n3 = shape_normals[p3_index]
		var sn = [shape_n1, shape_n2, shape_n3]
		var d = [Vector3(), Vector3(), Vector3()]
		var nd = [Vector3(), Vector3(), Vector3()]
		for u in range(3):
			for e in range(3):
				d[u][e] = sv[u][e] - bv[u][e]
				nd[u][e] = sn[u][e] - bn[u][e]
		diffmap.base_v += bv
		diffmap.shape_v += sv
		diffmap.triangles += [p1_index, p2_index, p3_index]
		diffmap.triangles_uv += [p1, p2, p3]
		diffmap.triangles_v += d
		diffmap.triangles_n += nd
	print("done")
	var end_time = OS.get_unix_time()
	print_debug("create_common2gender: ", end_time - start_time)
	return diffmap

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
