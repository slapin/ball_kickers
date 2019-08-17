extends Reference

class_name GridRule

func new_vertex(pos):
	var v = {
		"pos": pos,
		"neighbors": [],
		"seed": false
	}
	return v

func get_suggestion(rdata, v, b):
	var pforward = 1.0
	var pturn = 0.09
	var lmin = 20.0
	var lmax = 20.0
	var suggestion = []
	var wait = true

	var prev = v.pos - v.neighbors[v.neighbors.size() - 1].pos
	prev - prev.normalized()
	var n = prev.tangent()
	if n.length() < lmin:
		n = n.normalized() * lmin
	var vp = prev.normalized() * rand_range(lmin, lmax)
	var rnd = rdata.randf()
	if rnd <= pforward:
		var sv = new_vertex(v.pos + vp)
		sv.seed = true
		suggestion.append(new_vertex(v.pos + vp))
		wait = false
	rnd = rdata.randf()
	if rnd <= pturn * b * b:
		suggestion.append(new_vertex(v.pos + n))
		wait = true
	rnd = rdata.randf()
	if rnd <= pturn * b * b:
		suggestion.append(new_vertex(v.pos - n))
		wait = true
		
	return suggestion
