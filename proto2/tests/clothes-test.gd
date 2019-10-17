extends Spatial

onready var layers = [$base, $panties, $pants]
var pairs = [[0, 2], [1, 2], [0, 1]]
var cache = []

func cache_data():
	for k in range(layers.size()):
		var arrays = layers[k].mesh.surface_get_arrays(0)
		var data = {}
		data.vertices = arrays[Mesh.ARRAY_VERTEX]
		data.normals = arrays[Mesh.ARRAY_NORMAL]
		data.indices = arrays[Mesh.ARRAY_INDEX]
		data.bs = layers[k].mesh.surface_get_blend_shape_arrays(0)
		data.mat = layers[k].get_surface_material(0)
		data.mesh_mat = layers[k].mesh.surface_get_material(0)
		data.shrunk = shrink_vertices(data.vertices, data.normals)
		data.aabb = layers[k].get_aabb().grow(0.02)
		
		cache.push_back(data)

func update_meshes():
	for k in range(layers.size()):
		layers[k].hide()
		var arrays = layers[k].mesh.surface_get_arrays(0)
		arrays[Mesh.ARRAY_VERTEX] = cache[k].vertices
		layers[k].mesh.surface_remove(0)
		layers[k].mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, cache[k].bs)
		layers[k].set_surface_material(0, cache[k].mat)
		layers[k].mesh.surface_set_material(0, cache[k].mesh_mat)
		layers[k].show()

func get_layer_vertices(layer: int) -> PoolVector3Array:
	return cache[layer].vertices
func get_layer_normals(layer: int) -> PoolVector3Array:
	return cache[layer].normals
func get_layer_triangles(layer: int) -> PoolIntArray:
	return cache[layer].indices
func shrink_vertices(v: PoolVector3Array, n: PoolVector3Array) -> PoolVector3Array:
	var ret : = PoolVector3Array()
	ret.resize(v.size())
	for i in range(v.size()):
		ret[i] = v[i] - n[i].normalized() * 0.035
	return ret
func triangle_check(layer_inner: int, layer_outer: int) -> PoolVector3Array:
	var start_time = OS.get_unix_time()
	var inner_verts = get_layer_vertices(layer_inner)
	var inner_normals = get_layer_normals(layer_inner)
	var inner_verts_shrunk = cache[layer_inner].shrunk
	var outer_verts = get_layer_vertices(layer_outer)
	var outer_triangles = get_layer_triangles(layer_outer)
	for pt in range(inner_verts.size()):
		if !cache[layer_outer].aabb.has_point(inner_verts_shrunk[pt]):
			continue
		for tri in range(0, outer_triangles.size(), 3):
			var ray_pos = inner_verts_shrunk[pt]
			var ray_dir = inner_verts[pt] - inner_verts_shrunk[pt]
			var r = Geometry.ray_intersects_triangle(ray_pos, ray_dir,
				outer_verts[outer_triangles[tri]],
				outer_verts[outer_triangles[tri + 1]],
				outer_verts[outer_triangles[tri + 2]])
			if r:
				var dst = inner_verts_shrunk[pt].distance_to(r)
				if dst <= 0.035:
					var ndist = clamp(dst / 0.035, 0.0, 1.0)
					print(r, " ", ndist)
					inner_verts[pt] = inner_verts_shrunk[pt].linear_interpolate(inner_verts[pt], ndist)
	var end_time = OS.get_unix_time()
	print(" triangle_check time: ", end_time - start_time)
	return inner_verts
func update_layers(layer_inner: int, layer_outer: int):
	var verts = triangle_check(layer_inner, layer_outer)
	cache[layer_inner].vertices = verts
func _ready():
	cache_data()
	for p in pairs:
		update_layers(p[0], p[1])
#	$panties.hide()
#	$pants.hide()
	update_meshes()
