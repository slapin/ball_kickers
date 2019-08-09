extends Control

func update_desc():
	var sel: TreeItem = $v/Tree.get_selected()
	if sel:
		var desc = sel.get_metadata(0).description
		$v/desc.text = desc
	else:
		$v/desc.text = ""
func display_journal():
	if visible:
		$v/Tree.clear()
		var queue = []
		for k in world.quests:
			queue.push_back({"obj": k, "parent": null})
		while queue.size() > 0:
			var item = queue[0]
			queue.pop_front()
			var ti: TreeItem
			if item.parent == null:
				ti = $v/Tree.create_item()
			else:
				ti = $v/Tree.create_item(item.parent)
			ti.set_text(0, "Quest: " + item.obj.get_title())
			ti.set_metadata(0, {"description": item.obj.get_description()})
			if item.obj.is_complete():
				ti.set_text(1, "COMPLETE")
			for o in item.obj._objectives:
				var te: TreeItem = $v/Tree.create_item(ti)
				te.set_text(0, "Task: " + o.get_title())
				if o.is_complete():
					te.set_text(1, "COMPLETE")
				te.set_metadata(0, {"description": o.get_title()})
			for o in item.obj._children:
				queue.push_back({"obj": o, "parent": ti})
		update_desc()
func _ready():
	connect("visibility_changed", self, "display_journal")
	$v/okbutton.connect("pressed", self, "hide")
	$v/Tree.connect("item_selected", self, "update_desc")
