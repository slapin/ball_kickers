extends Reference
class_name DNATool

var min_point = Vector3()
var max_point = Vector3()
var min_normal = Vector3()
var max_normal = Vector3()

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
