extends Spatial

var gender = "female"
var skeleton
var test = true
func _ready():
	print(characters.accessory_data)
	if test:
		var hf = MeshInstance.new()
		add_child(hf)
		var hb = MeshInstance.new()
		add_child(hb)
		characters.spawn_accessory(hf, "female", "hair", "front_hair1")
		characters.spawn_accessory(hb, "female", "hair", "back_hair1")
