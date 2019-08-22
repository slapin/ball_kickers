extends Spatial

onready var characters = [load("res://characters/female_2018.escn"), load("res://characters/male_2018.escn")]
var body_mi: MeshInstance
#var body_mesh: ArrayMesh
#var orig_body_mesh: ArrayMesh
var cloth_mis: Dictionary = {}
#var cloth_meshes: Array = []
#var cloth_orig_meshes: Array = []
var clothes: Dictionary ={
	"dress": {
		"helper": ""
	},
	"panties": {
		"helper": ""
	},
	"suit": {
		"helper": ""
	},
	"bra": {
		"helper": ""
	},
	"top": {
		"helper": ""
	}
}
#var min_point: Vector3 = Vector3()
#var max_point: Vector3 = Vector3()
#var min_normal: Vector3 = Vector3()
#var max_normal: Vector3 = Vector3()
#var maps = {}
#var vert_indices = {}
var _vert_indices = {}
var controls = {}
var dna: DNA

var helper_names : = ["skirt"]

func update_modifier(value: float, modifier: String):
	var should_show : = false
	if body_mi.visible:
		body_mi.hide()
		should_show = true
	var val = value / 100.0
	val = clamp(val, 0.0, 1.0)
	dna.set_modifier_value(modifier, val)
	print(modifier, " ", val)
	body_mi.mesh = dna.modify_part("body")
	if should_show:
		body_mi.show()
	for k in cloth_mis.keys():
		if cloth_mis[k].visible:
			cloth_mis[k].hide()
			cloth_mis[k].mesh = dna.modify_part(k)
			cloth_mis[k].show()

func toggle_clothes(mi: MeshInstance, cloth_name: String):
	if !mi.visible:
		print("mod start")
		mi.mesh = dna.modify_part(cloth_name)
		print("mod end")
	mi.visible = !mi.visible

func find_mesh(base: Node, mesh_name: String) -> MeshInstance:
	assert base
	var queue = [base]
	var mi: MeshInstance
	while queue.size() > 0:
		var item = queue[0]
		assert item
		queue.pop_front()
		if item is MeshInstance && item.name == mesh_name:
			mi = item
			break
		for c in item.get_children():
			assert c
			queue.push_back(c)
	return mi
#func modify_mesh(orig_mesh: ArrayMesh, mi: MeshInstance, v_indices: Dictionary):
#	var should_show : = false
#	if mi.visible:
#		mi.hide()
#		should_show = true
#	mi.mesh = null
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
#				for u in range(2):
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
#	mi.mesh = mod_mesh
#	if should_show:
#		mi.show()
func update_slider(value: float, control: String, slider: HSlider):
	var modifier = ""
	if value >= 0:
		modifier = controls[control].plus
		if controls[control].has("minus"):
			dna.set_modifier_value(controls[control].minus, 0.0)
	else:
		value = -value
		modifier = controls[control].minus
		if controls[control].has("plus"):
			dna.set_modifier_value(controls[control].plus, 0.0)
	update_modifier(value, modifier)
var ch: Node
func rebuild_clothes_menu():
#	cloth_orig_meshes.clear()
	for c in $s/VBoxContainer/clothes.get_children():
		$s/VBoxContainer/clothes.remove_child(c)
		c.queue_free()
	$s/VBoxContainer/clothes.add_child(HSeparator.new())
	var clothes_label = Label.new()
	clothes_label.text = "Clothes"
	$s/VBoxContainer/clothes.add_child(clothes_label)
	for cloth in clothes.keys():
		var cloth_mi : = find_mesh(ch, cloth)
		if !cloth_mi:
			continue
		var cloth_button = Button.new()
		cloth_button.text = cloth_mi.name
		$s/VBoxContainer/clothes.add_child(cloth_button)
		cloth_button.connect("pressed", self, "toggle_clothes", [cloth_mi, cloth])
func prepare_character(x: int) -> void:
	if ch != null:
		remove_child(ch)
		ch.queue_free()
	ch = characters[x].instance()
	add_child(ch)
	ch.rotation.y = PI
	rebuild_clothes_menu()
	body_mi = find_mesh(ch, "body")
#	body_mesh = body_mi.mesh.duplicate(true)
#	orig_body_mesh = body_mi.mesh.duplicate(true)
	_vert_indices = dna.vert_indices[x]
	dna.add_mesh("body", body_mi.mesh, dna.vert_indices[x])
#	cloth_meshes.clear()
	cloth_mis.clear()
	for cloth in clothes.keys():
		var cloth_mi : = find_mesh(ch, cloth)
		if !cloth_mi:
			continue
		cloth_mi.mesh = dna.add_cloth_mesh(cloth, clothes[cloth].helper, cloth_mi.mesh)
		cloth_mis[cloth] = cloth_mi
#		prepare_cloth(body_mi, cloth_mi)
#		cloth_meshes.push_back(cloth_mi.mesh)
func button_female():
	prepare_character(0)
func button_male():
	prepare_character(1)
func _ready():
	dna = DNA.new("res://characters/common/config.bin")
#	var fd = File.new()
#	fd.open("res://characters/common/config.bin", File.READ)
#	min_point = fd.get_var()
#	max_point = fd.get_var()
#	min_normal = fd.get_var()
#	max_normal = fd.get_var()
#	maps = fd.get_var()
#	print(maps.keys())
#	vert_indices = fd.get_var()
#	fd.close()
#	print("min: ", min_point, " max: ", max_point)
#	for k in maps.keys():
#		print(k, ": ", maps[k].rect)
	
var state : = 0
func build_contols():
	for k in dna.get_modifier_list():
		if k.ends_with("_plus") && false:
			var cname = k.replace("_plus", "")
			if !controls.has(cname):
				controls[cname] = {}
			controls[cname].plus = k
		elif k.ends_with("_minus") && false:
			var cname = k.replace("_minus", "")
			if !controls.has(cname):
				controls[cname] = {}
			controls[cname].minus = k
		else:
			var cname = k
			controls[cname] = {}
			controls[cname].plus = k
	for k in controls.keys():
		var ok = true
		for m in helper_names:
			if k.begins_with(m + "_"):
				ok = false
				break
		if !ok:
			continue
		var l = Label.new()
		l.text = k
		$s/VBoxContainer.add_child(l)
		var slider : = HSlider.new()
		slider.rect_min_size = Vector2(180, 30)
		print(controls[k])
		
		if controls[k].has("minus") && controls[k].has("plus"):
			slider.min_value = -100
			slider.max_value = 100
		else:
			slider.min_value = 0
			slider.max_value = 100
		$s/VBoxContainer.add_child(slider)
		slider.connect("value_changed", self, "update_slider", [k, slider])
		slider.focus_mode = Control.FOCUS_CLICK
			
func _process(delta):
	match(state):
		0:
#			find_same_verts()
			prepare_character(0)
			state = 1
		1:
#			$Panel.hide()
			assert body_mi.mesh
			build_contols()
			$s/VBoxContainer/button_female.connect("pressed", self, "button_female")
			$s/VBoxContainer/button_male.connect("pressed", self, "button_male")
			state = 2
