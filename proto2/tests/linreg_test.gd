extends MainLoop

var pct

func _initialize():
	print("hello, world!")
	pct = LinReg.new()
	return 
func _iteration(delta):
	return pct.iterate(delta)
