extends Node

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
		print("loading ", e)
		var load_path = "res://" + e
		var item = load(load_path)
		assert(item)
		common.push_back(item)
		print("done loading ", e)

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

func _ready():
	print("loading data")
	load_data()
	print("data loaded")
	var fd = File.new()
	fd.open("characters/blendmaps.bin", File.WRITE);
	var bcount = 0
	for c in common:
		var obj = c.instance()
		for cm in ["base", "tights_helper", "robe_helper", "skirt_helper"]:
			print(obj.name, " ", cm)
			var mesh: ArrayMesh = get_mesh(obj, cm)
			bcount += mesh.get_blend_shape_count()
	fd.store_32(bcount)
	var deflate_size = 0
	var rle_size = 0
	for c in common:
		var obj = c.instance()
		print(obj.name)
		for cm in ["base", "tights_helper", "robe_helper", "skirt_helper"]:
			print(cm)
			var mesh: ArrayMesh = get_mesh(obj, cm)
			var base_array = mesh.surface_get_arrays(0)
			assert(base_array.size() > 0)
			var shape_arrays = mesh.surface_get_blend_shape_arrays(0)
			assert(shape_arrays.size() > 0)
			for x in range(mesh.get_blend_shape_count()):
				var triset = TriangleSet.new()
				var shape_name = mesh.get_blend_shape_name(x)
				print(obj.name, " ", shape_name, " ", x)
				var shape_array = shape_arrays[x]
				triset.create_from_array_shape(base_array, shape_array)
				var img = Image.new()
				var imgn = Image.new()
				img.create(512, 512, false, Image.FORMAT_RGBA8)
				imgn.create(512, 512, false, Image.FORMAT_RGBA8)
				triset.draw(img, imgn, 1)
				var rledata = triset.get_data(img, imgn)
				triset.save(fd, cm.replace("_helper", "") + ":" + shape_name, img, imgn)
#				var minp = triset.get_min()
#				var maxp = triset.get_max()
#				var min_normal = triset.get_min_normal()
#				var max_normal = triset.get_max_normal()
#				fd.store_pascal_string(cm.replace("_helper", "") + ":" + shape_name)
#				fd.store_float(minp.x)
#				fd.store_float(minp.y)
#				fd.store_float(minp.z)
#				fd.store_float(maxp.x)
#				fd.store_float(maxp.y)
#				fd.store_float(maxp.z)
#				fd.store_32(img.get_width())
#				fd.store_32(img.get_height())
#				fd.store_32(img.get_format())
#				fd.store_32(img.get_data().size())
#				var imgbuf = img.get_data().compress(File.COMPRESSION_FASTLZ)
#				fd.store_32(imgbuf.size())
#				fd.store_buffer(imgbuf)
#				fd.store_float(min_normal.x)
#				fd.store_float(min_normal.y)
#				fd.store_float(min_normal.z)
#				fd.store_float(max_normal.x)
#				fd.store_float(max_normal.y)
#				fd.store_float(max_normal.z)
#				fd.store_32(imgn.get_width())
#				fd.store_32(imgn.get_height())
#				fd.store_32(imgn.get_format())
#				fd.store_32(imgn.get_data().size())
#				var imgnbuf = imgn.get_data().compress(File.COMPRESSION_FASTLZ)
#				print("rle size = ", rledata.size(), ", deflate size = ", imgbuf.size() + imgnbuf.size())
#				rle_size += rledata.size()
#				deflate_size += imgbuf.size() + imgnbuf.size()
#				fd.store_32(imgnbuf.size())
#				fd.store_buffer(imgnbuf)
				img.save_png("res://" + common_path + "/" + cm + "_" + shape_name + ".png")
				imgn.save_png("res://" + common_path + "/" + cm + "_" + shape_name + "_normal.png")
	fd.close()
	print("saved")
# FIXME: convert the below to C++ to save gender maos too
#	var c = characters.characters[1]
#	var obj = c.instance()
#	print(obj.name)
#	print("body")
#	var mesh_target: ArrayMesh = load("res://characters/accessory/female/body/body_default.mesh")
#	print("base")
#	var mesh_base: ArrayMesh = get_mesh(common[0].instance(), "base")
#	assert(mesh_target)
#	assert(mesh_base)
#	var base_array = mesh_base.surface_get_arrays(0)
#	var target_array = mesh_target.surface_get_arrays(0)
#	var triset = TriangleSet.new()
#	triset.create_from_mesh_difference(base_array, 1, target_array, 1)
#	var img = Image.new()
#	var imgn = Image.new()
#	img.create(512, 512, false, Image.FORMAT_RGBA8)
#	imgn.create(512, 512, false, Image.FORMAT_RGBA8)
#	triset.draw(img, imgn, 1)
#	img.save_png("res://" + common_path + "/female.png")
#	imgn.save_png("res://" + common_path + "/female_normal.png")
#	var minp = triset.get_min()
#	var maxp = triset.get_max()
#	var min_normal = triset.get_min_normal()
#	var max_normal = triset.get_max_normal()
#	print([minp, maxp, min_normal, max_normal])
	print("complete")
	get_tree().quit()
#	print("deflate size: ", deflate_size, " rle size: ", rle_size)

