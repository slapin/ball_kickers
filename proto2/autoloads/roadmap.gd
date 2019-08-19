extends Node
signal complete

var map_width = 1280
var map_height = 1280
var map_rect = Rect2(0, 0, map_width, map_height)

enum {STATE_INIT, STATE_ITERATION, STATE_EDGES1, STATE_EDGES2, STATE_EDGES3, STATE_POLYGONS1, STATE_POLYGONS2, STATE_COMPLETE}
var state = STATE_INIT

var min_distance = 12.0
var pgrow = 0.5

var rules = {}
var edges = []
var pos2vertex = {}
var lot_points = []
var lot_triangles = []
var pos2edge = {}
var road_width: float = 6.0
var pos2id = {}
var minpos = Vector2()
var maxpos = Vector2()
var vertex_queue = []
var vertices = []
var front = []
var lots: Lots

class Lots:
	enum {LOT_FOREST, LOT_AIRPORT, LOT_PARK, LOT_CEMETERY, LOT_RESIDENTAL, LOT_INDUSTRIAL}
	var lot_types = {
		"forest": {
			"w": 500,
			"h": 500,
			"type": LOT_FOREST,
			"center_distance": 400.0
		},
		"airport": {
			"w": 500,
			"h": 500,
			"type": LOT_AIRPORT,
			"center_distance": 400.0
		},
		"park": {
			"w": 300,
			"h": 300,
			"type": LOT_PARK,
			"center_distance": 0.0
		},
		"cemetery": {
			"w": 200,
			"h": 200,
			"type": LOT_CEMETERY,
			"center_distance": 0.0
		},
		"residental1": {
			"w": 100,
			"h": 100,
			"type": LOT_RESIDENTAL,
			"center_distance": 0.0
		},
		"residental2": {
			"w": 50,
			"h": 50,
			"type": LOT_RESIDENTAL,
			"center_distance": 0.0
		},
		"residental3": {
			"w": 20,
			"h": 20,
			"type": LOT_RESIDENTAL,
			"center_distance": 0.0
		},
		"industrial": {
			"w": 100,
			"h": 100,
			"type": LOT_RESIDENTAL,
			"center_distance": 200.0
		},
	}
	var lots = []
	func make_lot_polygon(lot_name: String):
		var lot_type = lot_types[lot_name]
		var p1 = Vector2(-lot_type.w * 0.5, -lot_type.h * 0.5)
		var p2 = Vector2(lot_type.w * 0.5, -lot_type.h * 0.5)
		var p3 = Vector2(lot_type.w * 0.5, lot_type.h * 0.5)
		var p4 = Vector2(-lot_type.w * 0.5, lot_type.h * 0.5)
		return [p1, p2, p3, p4]
#	func get_polygon_center(polygon):
#		var ret: Vector2 = Vector2()
#		for m in range(polygon.size()):
#			ret += polygon[m]
#		return ret / 4.0
	func get_lot_transform(p1: Vector2, p2: Vector2, road_width: float, sidewalk_width: float, polygon: Array):
		var n = (p2-p1).tangent().normalized()
		var offset1 = n * (road_width + sidewalk_width)
		var offset2 = Vector2()
		for v in range(polygon.size()):
			if offset2.x < polygon[v].x:
				offset2.x = polygon[v].x
			if offset2.y < polygon[v].y:
				offset2.y = polygon[v].y
		var ret = Transform2D((p2 - p1).angle(), p1.linear_interpolate(p2, 0.5) + offset1 + offset2)
		return ret
	func transformed_polygon(xform: Transform2D, polygon: Array):
		return Array(Geometry.transform_points_2d(PoolVector2Array(polygon), xform))
	func polygon_intersects_road(polygon, vertices):
		for v in range(vertices.size()):
			var p1 = vertices[v].pos
			for k in vertices[v]._neighbors:
				var p2 = vertices[k].pos
				if Geometry.segment_intersects_segment_2d(p1, p2, polygon[0], polygon[1]):
					return true
				if Geometry.segment_intersects_segment_2d(p1, p2, polygon[1], polygon[2]):
					return true
				if Geometry.segment_intersects_segment_2d(p1, p2, polygon[2], polygon[3]):
					return true
				if Geometry.segment_intersects_segment_2d(p1, p2, polygon[3], polygon[0]):
					return true
				if Geometry.point_is_inside_triangle(p1, polygon[0], polygon[1], polygon[2]):
					return true
				if Geometry.point_is_inside_triangle(p1, polygon[0], polygon[2], polygon[3]):
					return true
				if Geometry.point_is_inside_triangle(p2, polygon[0], polygon[1], polygon[2]):
					return true
				if Geometry.point_is_inside_triangle(p2, polygon[0], polygon[2], polygon[3]):
					return true
		return false
	func generate_lots(vertices, road_width, sidewalk_width, map_width, map_height):
		for v in range(vertices.size()):
			var p1 = vertices[v].pos
			for k in vertices[v]._neighbors:
				for d in range(10):
					var p2 = vertices[k].pos
					var lot_type_name = lot_types.keys()[randi() % lot_types.keys().size()]
					var polygon = make_lot_polygon(lot_type_name)
					var xform = get_lot_transform(p1, p2, road_width, sidewalk_width, polygon)
					if polygon_intersects_road(transformed_polygon(xform, polygon), vertices):
						continue
					var xfpoly = transformed_polygon(xform, polygon)
					var bad = false
					for r in lots:
						var poly2 = transformed_polygon(r.xform, r.polygon)
						if Geometry.intersect_polygons_2d(xfpoly, poly2).size() > 0:
							bad = true
							break
					if xform.origin.distance_to(Vector2(map_width * 0.5, map_height * 0.5)) < lot_types[lot_type_name].center_distance:
						bad = true
					if bad:
						continue
					lots.push_back({
						"polygon": polygon,
						"xform": xform
					})
					break
			

#class PointDB:
#	var _points: PoolVector2Array = PoolVector2Array()
#	var _triangles: PoolIntArray = PoolIntArray()
#	var _grid: Array = []
#	var _grid_size: int = -1
#	var grid_w: int
#	var grid_h: int
#	var grid_offset: Vector2
#	var _edges = {}
#	var _eid2id = {}
#	var _id2data = {}
#	var _id2pos = {}
#	var _pos2id = {}
#	var _id2edge = {}
#	var _edge2data = {}
#	func build_grid(points: Array, grid_size: int):
#		_points = points
#		_triangles = Geometry.triangulate_delaunay_2d(_points)
#		_grid_size = grid_size
#		_pos2id.clear()
#		_id2pos.clear()
#		_id2data.clear()
#		_id2edge.clear()
#		_grid.clear()
#		_edges.clear()
#		_edge2data.clear()
#		var rect: Rect2 = Rect2()
#		for p in range(_points.size()):
#			rect = rect.expand(_points[p])
#			_pos2id[_points[p]] = p
#			_id2pos[p] = _points[p]
#		rect.position.x = floor(rect.position.x / grid_size - 1) * grid_size
#		rect.position.y = floor(rect.position.x / grid_size - 1) * grid_size
#		rect.size.x = ceil(rect.size.x / grid_size + 1) * grid_size
#		rect.size.y = ceil(rect.size.x / grid_size + 1) * grid_size
#		grid_w = int((rect.size.x + 1)/ grid_size)
#		grid_h = int((rect.size.x + 1)/ grid_size)
#		grid_offset = rect.position
#		_grid.resize((grid_w + 1) * (grid_h + 1))
#		for p in range(_points.size()):
#			var grid_x = int((_points[p].x - grid_offset.x) / grid_size)
#			var grid_y = int((_points[p].y - grid_offset.y) / grid_size)
#			if !_grid[grid_w * grid_y + grid_x]:
#				_grid[grid_w * grid_y + grid_x] = PoolIntArray()
#			_grid[grid_w * grid_y + grid_x].push_back(p)
#		for tri in range(0, _triangles.size(), 3):
#			var p1 = _triangles[tri + 0]
#			var p2 = _triangles[tri + 1]
#			var p3 = _triangles[tri + 2]
#			add_edge_id(p1, p2)
#			add_edge_id(p2, p3)
#			add_edge_id(p3, p1)
#	func add_point_data(p: Vector2, data: Dictionary):
#		if _pos2id.has(p):
#			_id2data[_pos2id[p]] = data
#		else:
#			breakpoint
#			print_debug("Bad point added")
#	func get_point_data(p: Vector2) -> Dictionary:
#		if _pos2id.has(p):
#			return _id2data[_pos2id[p]]
#		else:
#			return {}
#	func add_edge_id(a: int, b: int):
#		var edge_id = hash([a, b])
#		_edges[edge_id] = [a, b]
#		if _id2edge.has(a):
#			_id2edge[a].push_back(edge_id)
#		else:
#			_id2edge[a] = [edge_id]
#		if _id2edge.has(b):
#			_id2edge[b].push_back(edge_id)
#		else:
#			_id2edge[b] = [edge_id]
#	func add_edge(a: Vector2, b: Vector2):
#		if _pos2id.has(a) && _pos2id.has(b):
#			add_edge_id(_pos2id[a], _pos2id[b])
#		else:
#			breakpoint
#			print_debug("Bad edge added")
#	func add_edge_data(a: Vector2, b: Vector2, data: Dictionary):
#		assert a in _points
#		assert b in _points
#		var ai = _pos2id[a]
#		var bi = _pos2id[b]
#		var edge_id = hash([ai, bi])
#		var edge_id_rev = hash([bi, ai])
#		if _edges.has(edge_id):
#			_edge2data[edge_id] = data
#			return true
#		elif _edges.has(edge_id_rev):
#			_edge2data[edge_id_rev] = data
#			return true
#		else:
#			print_debug("No such edge ", [a, b])
#			return false
#	func get_edge_data(a: Vector2, b: Vector2) -> Dictionary:
#		var ai = _pos2id[a]
#		var bi = _pos2id[b]
#		var edge_id = hash([ai, bi])
#		var edge_id_rev = hash([bi, ai])
#		if _edge2data.has(edge_id):
#			return _edge2data[edge_id]
#		elif _edge2data.has(edge_id_rev):
#			return _edge2data[edge_id_rev]
#		else:
#			return {}
#	func get_point_edges(a: Vector2) -> Array:
#		var ret : = []
#		var edges = _id2edge[_pos2id[a]]
#		for e in edges:
#			var ed = _edges[e]
#			ret.push_back([_id2pos[ed[0]], _id2pos[ed[1]]])
#		return ret
#	func get_polygons() -> Array:
#		var ret = []
#		for t in range(0, _triangles.size(), 3):
#			var p1 = _points[_triangles[t + 0]]
#			var p2 = _points[_triangles[t + 1]]
#			var p3 = _points[_triangles[t + 2]]
#			ret.push_back([p1, p2, p3, get_edge_data(p1, p2), get_edge_data(p2, p3), get_edge_data(p3, p1)])
#		return ret



var rnd: RandomNumberGenerator
var noise: OpenSimplexNoise
var complete = false
#var db: PointDB

var axiom = [
	new_vertex(10, 10),
	new_vertex(60, 10),
	new_vertex(110, 10),
	new_vertex(110, 60),
	new_vertex(110, 110),
	new_vertex(110, 160),
	new_vertex(60, 160),
	new_vertex(10, 160),
	new_vertex(10, 110),
	new_vertex(10, 60),
]


func cleanup():
	minpos = Vector2()
	maxpos = Vector2()
	vertex_queue.clear()
	vertices.clear()
	edges.clear()
	pos2vertex.clear()
	pos2edge.clear()
	pos2id.clear()
	front.clear()

func new_vertex(x, y):
	return {
			"pos": Vector2(x, y),
			"neighbors": [],
			"type": 0,
			"seed": false
	}

func are_lines_intersecting(a, b, c, d):
	var cd = d - c
	var ab = b - a
	var div = cd.y * ab.x - cd.x * ab.y
	if abs(div) > 0.001:
		var ac = a - c
		var ua = ((cd.x * ac.y) - (cd.y * ac.x)) / div
		if not ua >= 0.0 or not ua <= 1.0:
			return false
		var ub = ((ab.x * ac.y) - (ab.y * ac.x)) / div
		if ub >= 0.0 and ub <= 1.0:
			return true
	return false

func find_edge(p1, p2):
	if pos2edge.has(p1) && pos2edge.has(p2):
		for e in pos2edge[p1] + pos2edge[p2]:
			if edges[e].p1 == p1 && edges[e].p2 == p2:
				return e
			if edges[e].p1 == p2 && edges[e].p2 == p1:
				return e
	return null
func add_edge(p1, p2, road):
	var id = edges.size()
	var edge = {
		"p1": p1,
		"p2": p2,
		"road": road,
		"id": id,
	}
	edges.push_back(edge)
	if pos2edge.has(vertices[p1].pos):
		pos2edge[vertices[p1].pos].push_back(id)
	else:
		pos2edge[vertices[p1].pos] = [id]
	if pos2edge.has(vertices[p2].pos):
		pos2edge[vertices[p2].pos].push_back(id)
	else:
		pos2edge[p2] = [id]

	return id

#func get_internal_angle(ecur, enext):
#	var adj_p = -1
#	var p_a = -1
#	var p_b = -1
#	var road_a = false
#	var road_b = false
#	var m_a = [-1, -1]
#	var m_b = [-1, -1]
#	var idx_a = -1
#	var idx_b = -1
#	road_a = edges[ecur].road
#	road_b = edges[enext].road
#	if !road_a && !road_b:
#		return null
#	if edges[ecur].p1 == edges[enext].p1:
#		adj_p = edges[ecur].p1
#		p_a = edges[ecur].p2
#		p_b = edges[enext].p2
#		road_a = edges[ecur].road
#		road_b = edges[enext].road
#		m_a = [adj_p, p_a]
#		m_b = [adj_p, p_b]
#		idx_a = 0
#		idx_b = 0
#	elif edges[ecur].p1 == edges[enext].p2:
#		adj_p = edges[ecur].p1
#		p_a = edges[ecur].p2
#		p_b = edges[enext].p1
#		m_a = [adj_p, p_a]
#		m_b = [p_b, adj_p]
#		idx_a = 0
#		idx_b = 1
#	elif edges[ecur].p2 == edges[enext].p1:
#		adj_p = edges[ecur].p2
#		p_a = edges[ecur].p1
#		p_b = edges[enext].p2
#		m_a = [p_a, adj_p]
#		m_b = [adj_p, p_b]
#		idx_a = 1
#		idx_b = 0
#	elif edges[ecur].p2 == edges[enext].p2:
#		adj_p = edges[ecur].p2
#		p_a = edges[ecur].p1
#		p_b = edges[enext].p1
#		m_a = [p_a, adj_p]
#		m_b = [p_b, adj_p]
#		idx_a = 1
#		idx_b = 1
#	var v_a = vertices[p_a].pos - vertices[adj_p].pos
#	var v_b = vertices[p_b].pos - vertices[adj_p].pos
#	var n_a = v_a.tangent().normalized()
#	var n_b = v_b.tangent().normalized()
#	var pos = vertices[adj_p].pos
#	if road_a:
#		pos += n_a * road_width
#	if road_b:
#		pos += n_a * road_width
#	var ret = {}
#	ret.vertex = new_vertex(pos.x, pos.y)
#	ret.adj = adj_p
#	ret.a = p_a
#	ret.b = p_b
#	ret.vertex._neighbors = [p_a, p_b]
#	ret.vertex.neighbors = [vertices[p_a], vertices[p_b]]
#	ret.m_a = m_a
#	ret.m_b = m_b
#	ret.idx_a = idx_a
#	ret.idx_b = idx_b
#	return ret

#func adjust_triangle(tri):
#	var newtri = []
#	var new_edges = []
#	for i in range(3):
#		newtri.push_back(tri[i])
#	for i in range(3):
#		var j = (i + 1) % 3
#		var ecur = tri[i]
#		var enext = tri[(i + 1) % 3]
#		var ang = get_internal_angle(ecur, enext)
#		if ang != null:
#			var id = vertices.size()
#			ang.vertex._index = id
#			vertices.push_back(ang.vertex)
#			var m_a = ang.m_a.duplicate()
#			m_a[ang.idx_a] = id
#			var m_b = ang.m_a.duplicate()
#			m_b[ang.idx_b] = id
#			add_edge(m_a[0], m_b[0], false)

func convert_vertices():
	for e in range(vertices.size()):
		pos2vertex[vertices[e].pos] = vertices[e]
		vertices[e]._index = e
		pos2id[vertices[e].pos] = e
	for e in range(vertices.size()):
		vertices[e]._neighbors = []
		for h in vertices[e].neighbors:
			assert h
#			print(pos2vertex[h.pos])
			vertices[e]._neighbors.push_back(pos2vertex[h.pos]._index)
func has_neighbor(v, n):
	var ret = false
	for p in v.neighbors:
		if p.pos == n.pos:
			ret = true
			break
	return ret
func add_neighbor(v, n):
	if !has_neighbor(v, n):
		v.neighbors.push_back(n)
	if !has_neighbor(n, v):
		v.neighbors.push_back(n)
	if !n._index in v._neighbors:
		v._neighbors.push_back(n._index)
	if !v._index in n._neighbors:
		n._neighbors.push_back(v._index)
func remove_neighbor(v, n):
	if has_neighbor(v, n):
		v.neighbors.erase(n)
	if has_neighbor(n, v):
		n.neighbors.erase(v)
	if n._index in v._neighbors:
		v._neighbors.erase(n._index)
	if v._index in n._neighbors:
		n._neighbors.erase(v._index)
	
#func update_neighbors():
#	for e in range(points.size()):
#		if pos2vertex.has(points[e]):
#			continue
#		var nv = new_vertex(points[e].x, points[e].y)
#		nv._index = vertices.size()
#		nv._neighbors = []
#		vertices.push_back(nv)
#		pos2vertex[nv.pos] = vertices[nv._index]
#		pos2id[nv.pos] = nv._index
#	for t in range(0, triangulation.size(), 3):
#		for k in range(3):
#			var prev = k
#			var cur = (k + 1) % 3
#			var next = (k + 2) % 3
#			var pprev = triangulation[t + prev]
#			var pcur = triangulation[t + cur]
#			var pnext = triangulation[t + next]
#			add_neighbor(pos2vertex[points[pcur]], pos2vertex[points[pprev]])
#			add_neighbor(pos2vertex[points[pcur]], pos2vertex[points[pnext]])
#func build_edges():
#	print("tri count: ", triangulation.size() / 3)
#	for i in range(0, triangulation.size(), 3):
#		var p1 = points[triangulation[i + 0]]
#		var p2 = points[triangulation[i + 1]]
#		var p3 = points[triangulation[i + 2]]
#		var e1 = null
#		var e2 = null
#		var e3 = null
#		e1 = find_edge(pos2id[p1], pos2id[p2])
#		e2 = find_edge(pos2id[p2], pos2id[p3])
#		e3 = find_edge(pos2id[p3], pos2id[p1])
#		if e1 == null:
#			e1 = add_edge(pos2vertex[p1]._index, pos2vertex[p2]._index, false)
#		if e2 == null:
#			e2 = add_edge(pos2vertex[p2]._index, pos2vertex[p3]._index, false)
#		if e3 == null:
#			e3 = add_edge(pos2vertex[p3]._index, pos2vertex[p1]._index, false)
#		var triangle = [e1, e2, e3]
#		triangles.push_back(triangle)
func sort_edges(edge_data: PoolIntArray) -> PoolIntArray:
	assert edge_data.size() > 0
	var inb = Array(edge_data)
	var cur = -1
	var cur_p = -1
	var ret = PoolIntArray()
	while inb.size() > 0:
		var data = inb.pop_front()
		if cur == -1:
			cur = data
			cur_p = edges[cur].p2
			ret.push_back(data)
		else:
			var cur_p1 = edges[cur].p1
			var cur_p2 = edges[cur].p2
			var data_p1 = edges[data].p1
			var data_p2 = edges[data].p2
			if cur_p == data_p1:
				ret.push_back(data)
				cur = data
				cur_p = data_p2
			elif cur_p == data_p2:
				ret.push_back(-(data + 1))
				cur = data
				cur_p = data_p1
			else:
#				print("unmatched ", cur, " ", data)
#				print(cur, ": ", edges[cur].p1, " - ", edges[cur].p2)
#				print(data, ": ", edges[data].p1, " - ", edges[data].p2)
				inb.push_back(data)
#	for p in edge_data:
#		print(p, ": ", edges[p].p1, " - ", edges[p].p2)
#	print(ret.size(), " ", edge_data.size(), " ", edge_data, " -> ", ret)
	assert ret.size() > 0 && ret.size() == edge_data.size()
	return ret
func edges2points(edge_data):
	var ret = {}
	var sorted_data = sort_edges(PoolIntArray(edge_data))
	ret.points = []
	ret.edges = []
	var idx = 0
	for e in sorted_data:
		if e >= 0:
			ret.points.push_back(vertices[edges[e].p1].pos)
		else:
			ret.points.push_back(vertices[edges[-(e + 1)].p2].pos)
		ret.edges.push_back({
			"indices": [idx, (idx + 1) % sorted_data.size()],
			"road": edges[e].road
		})
		idx += 1
	assert ret.points.size() > 0 && ret.points.size() == edge_data.size()
	return ret
#func build_polygons():
#	print("triangulation: ", triangulation.size())
#	print("triangles count: ", triangles.size())
#	print("points count: ", points.size())
#	for p in range(triangles.size()):
#		var polygon = {}
#		var data = edges2points(triangles[p])
#		polygon.vertices = data.points
#		polygon.edges = data.edges
#		polygon.road = false
#		for e in range(triangles[p].size()):
#			if edges[triangles[p][e]].road:
#				polygon.road = true
#		polygons.push_back(polygon)
#		if p % 100 == 0:
#			print(p)
#func separate_polygons(p):
#	var ret = []
#	var new_p = {}
#	var modp = p.duplicate()
#	for w in range(p.edges.size()):
#		var ecur = w
#		var enext = (w + 1) % p.edges.size()
##		print(ecur, " ", enext, " ", p.edges[ecur].indices[0], " ", p.edges[enext].indices[0])
##		print(p.points)
##		print(p.points[p.edges[ecur].indices[0]])
#		var cur_p1 = p.vertices[p.edges[ecur].indices[0]]
#		var cur_p2 = p.vertices[p.edges[ecur].indices[1]]
#		var next_p1 = p.vertices[p.edges[enext].indices[0]]
#		var next_p2 = p.vertices[p.edges[enext].indices[1]]
#		assert cur_p2 == next_p1
#		var v_a = cur_p1 - cur_p2
#		var v_b = next_p2 - cur_p2
#		var n_a = v_a.tangent().normalized()
#		var n_b = v_b.tangent().normalized()
#		var pos = cur_p2
#		if p.edges[ecur].road:
#			pos += n_a * road_width
#		if p.edges[enext].road:
#			pos += n_a * road_width
#		new_p[p.edges[ecur].indices[1]] = pos
#		new_p[p.edges[enext].indices[0]] = pos
#		modp.vertices[p.edges[ecur].indices[1]] = pos
#		modp.vertices[p.edges[enext].indices[0]] = pos
#		p.edges[ecur].road = false
#	modp.road = false
#	ret.push_back(modp)
#	for e in p.edges:
#		if !e.road:
#			continue
#		var p1 = p.vertices[e.indices[0]]
#		var p2 = p.vertices[e.indices[1]]
#		var p3 = new_p[e.indices[0]]
#		var p4 = new_p[e.indices[1]]
#		var road_polygon = {}
#		road_polygon.vertices = [p3, p1, p2]
#		road_polygon.edges = [
#		{
#			"indices": [0, 1],
#			"road": true
#		},
#		{
#			"indices": [1, 2],
#			"road": true
#		},
#		{
#			"indices": [2, 0],
#			"road": true
#		},
#		]
#		road_polygon.road = true
#		ret.push_back(road_polygon)
#		road_polygon.vertices = [p3, p2, p4]
#		road_polygon.edges = [
#		{
#			"indices": [0, 1],
#			"road": true
#		},
#		{
#			"indices": [1, 2],
#			"road": true
#		},
#		{
#			"indices": [2, 0],
#			"road": true
#		},
#		]
#		road_polygon.road = true
#		road_polygon = {}
#		ret.push_back(road_polygon)
#	return ret
#func separate_roads():
#	var new_polys = []
#	for p in polygons:
#		if p.road:
#			polygon_queue.push_back(p)
#		else:
#			new_polys.push_back(p)
#	polygons = new_polys
#	while polygon_queue.size() > 0:
#		var item = polygon_queue.pop_front()
#		var road = false
#		var lot = true
#		for e in item.edges:
#			if e.road == true:
#				road = true
#			if e.road == false:
#				lot = true
#		if road && lot:
#			var new_polygons = separate_polygons(item)
#			for p in new_polygons:
#				polygon_queue.push_back(p)
#		else:
#			polygons.push_back(item)

func adjacent_edges(e1, e2):
	if edges[e1].p1 == edges[e2].p1:
		return true
	elif edges[e1].p1 == edges[e2].p2:
		return true
	elif edges[e1].p2 == edges[e2].p1:
		return true
	elif edges[e1].p2 == edges[e2].p2:
		return true
	else:
		return false
#func check_triangles():
#	for t in triangles:
#		if !adjacent_edges(t[0], t[1]):
#			return false
#		if !adjacent_edges(t[1], t[2]):
#			return false
#		if !adjacent_edges(t[2], t[0]):
#			return false
#	return true
		
func build(rnd_seed):
	cleanup()
	rnd.seed = rnd_seed
	noise.seed = rnd_seed
	for k in range(axiom.size()):
		var cur = k
		var next = (k + 1) % axiom.size()
		if !axiom[cur] in axiom[next].neighbors:
			axiom[next].neighbors.push_back(axiom[cur])
		if !axiom[next] in axiom[cur].neighbors:
			axiom[cur].neighbors.push_back(axiom[next])
		axiom[cur].axiom = true
		vertices.push_back(axiom[k])
	for k in vertices:
		if minpos.x > k.pos.x:
			minpos.x = k.pos.x
		if minpos.y > k.pos.y:
			minpos.y = k.pos.y
		if maxpos.x < k.pos.x:
			maxpos.x = k.pos.x
		if maxpos.y < k.pos.y:
			maxpos.y = k.pos.y
	front += vertices
	state = STATE_ITERATION
	print_debug("starting iteration")
	set_process(true)
#	for v in vertices:
#		print(v.pos)
func check_suggestion(s, n, front):
#	print(s.pos, " ", map_rect)
	var newfront = front.duplicate()
	if !map_rect.has_point(s.pos):
		return newfront
	if s.pos.distance_to(n.pos) < min_distance:
		return newfront
	for k in n.neighbors:
		if s.pos.distance_to(k.pos) < min_distance:
			return newfront

# requires partitioning algorithm for speedup
	for k in vertices:
		if s.pos.distance_to(k.pos) < min_distance:
			if ! k in n.neighbors:
				n.neighbors.append(k)
			if ! n in k.neighbors:
				k.neighbors.append(n)
			return newfront
		for kn in k.neighbors:
			if n.pos == k.pos || n == k || n == kn || n.pos == kn.pos:
				continue
			if are_lines_intersecting(s.pos, n.pos, k.pos, kn.pos):
				return newfront
	if ! s in n.neighbors:
		n.neighbors.push_back(s)
	if ! n in s.neighbors:
		s.neighbors.push_back(n)
	vertices.push_back(s)
	newfront.push_back(s)
	if s.seed:
		vertex_queue.push_back({"data": s, "priority": 4})
	return newfront

# simple density map
# better use image as data source
func get_density(pos):
		return 0.7

func get_suggestion(v):
	return rules.grid.get_suggestion(rnd, v, get_density(v.pos))

func iteration(front):
	var newfront = []
#	var s = calc_s(front[0])
	for k in front:
		var suggestion = get_suggestion(k)
		for l in suggestion:
			newfront = check_suggestion(l, k, newfront)
# better use priority queue for actual code
	if vertex_queue.size() > 0:
		var item = vertex_queue.pop_front()
		if item.priority == 0:
			newfront.push_back(item.data)
		else:
			item.priority -= 1
			vertex_queue.push_back(item)
	return newfront

func get_height(x, y):
	return noise.get_noise_2d(x * 10.0, y * 10.0) * 5.0

const sidewalk_width = 1.5
#var potential_edges = []
#func implode_road():
##	for t in range(0, db._triangles.size(), 3):
#
##	potential_edges.clear()
#	for v in vertices:
#		for n in v._neighbors:
#			var p1 = v.pos
#			var p2 = vertices[n].pos
#			var dir = (p2 - p1).normalized()
#			var t = dir.tangent()
#			for offset in [-road_width - sidewalk_width,
#					-road_width,
#					road_width, 
#					road_width + sidewalk_width]:
#				var ep1 = p1 + offset
#				var ep2 = p2 + offset
#				for p in [ep1, ep2]:
#					if !p in extra_points && !p in points:
#						extra_points.push_back(p)
#					if !p in road_points:
#						road_points.push_back(p)
#			for offset in [-road_width - sidewalk_width - 0.1,
#					road_width + sidewalk_width + 0.1]:
#				var ep1 = p1 + offset
#				var ep2 = p2 + offset
#				for p in [ep1, ep2]:
#					if !p in extra_points && !p in points:
#						extra_points.push_back(p)
#
#			if !p1 in road_points:
#				road_points.push_back(p1)
#			if !p2 in road_points:
#				road_points.push_back(p2)
#			potential_edges.push_back([p1, ep1])
#			potential_edges.push_back([p1, ep2])
#			potential_edges.push_back([p2, ep3])
#			potential_edges.push_back([p2, ep4])
#			potential_edges.push_back([p1, p2])
#			potential_edges.push_back([ep1, ep2])
#			potential_edges.push_back([ep3, ep4])
#			potential_edges.push_back([ep1, ep4])
#			potential_edges.push_back([ep2, ep3])



#func adjust_triangles():
#	for e in range(0, triangulation.size(), 3):
#		for c in range(3):
#			var adj = points[triangulation[e + (c + 1) % 3]]
#			var point_a = points[triangulation[e + c]]
##			print(points.size())
##			print(e + (c + 2) % 3)
#			var point_b = points[triangulation[e + (c + 2) % 3]]
#			var n1 = (point_a - adj).normalized()
#			var n2 = (point_b - adj).normalized()
#			var pos = adj + n1 * road_width + n2 * road_width
#			if !pos in extra_points && !pos in points:
#				extra_points.push_back(pos)
	


#func build_simple_mesh():
#	var arrays = []
#	var verts = PoolVector3Array()
#	var normals = PoolVector3Array()
#	arrays.resize(ArrayMesh.ARRAY_MAX)
#	var mesh = ArrayMesh.new()
#	for p in polygons:
#		for v in p.vertices:
#			var v3d = Vector3()
#			v3d.x = v.x - float(map_width) / 2.0
#			v3d.z = v.x - float(map_height) / 2.0
#			v3d.y = 0
#			verts.push_back(v3d)
#			normals.push_back(Vector3(1, 1, 1))
#	arrays[ArrayMesh.ARRAY_VERTEX] = verts
#	arrays[ArrayMesh.ARRAY_NORMAL] = normals
#	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
#	return mesh

#func build_d_mesh():
#	var arrays = []
#	var verts = PoolVector3Array()
#	var normals = PoolVector3Array()
#	var indices = PoolIntArray(Geometry.triangulate_delaunay_2d(points))
#	arrays.resize(ArrayMesh.ARRAY_MAX)
#	var mesh = ArrayMesh.new()
#	for v in points:
#		var v3d = Vector3()
#		v3d.x = v.x - float(map_width) / 2.0
#		v3d.z = v.x - float(map_height) / 2.0
#		v3d.y = 0
#		verts.push_back(v3d)
#		normals.push_back(Vector3(1, 1, 1))
#	arrays[ArrayMesh.ARRAY_VERTEX] = verts
#	arrays[ArrayMesh.ARRAY_NORMAL] = normals
#	arrays[ArrayMesh.ARRAY_INDEX] = indices
#	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
#	return mesh
			

#func build_mesh(aabb: AABB, vn: Node):
#	var polylist = []
#	var mesh_aabb = AABB()
#	var rect = Rect2(aabb.position.x + map_width / 2.0,
#		aabb.position.z + map_width / 2.0, aabb.size.x, aabb.size.z)
#	for p in polygons:
#		for v in p.vertices:
##			print(v)
#			if rect.has_point(v) || true:
#				polylist.push_back(p)
#				break
#	var verts_road = PoolVector3Array()
#	var indices_road = PoolIntArray()
#	var normals_road = PoolVector3Array()
#	var verts_lot = PoolVector3Array()
#	var indices_lot = PoolIntArray()
#	var normals_lot = PoolVector3Array()
#	var mesh = ArrayMesh.new()
#	var arrays_roads = []
#	var arrays_lots = []
#	arrays_roads.resize(ArrayMesh.ARRAY_MAX)
#	arrays_lots.resize(ArrayMesh.ARRAY_MAX)
#	var idx_road = 0
#	var idx_lot = 0
#	for p in polylist:
#		var vid = 0
#		for v in p.vertices:
##				var v = p.vertices[e.indices[0]]
#				var v3d = Vector3()
#				v3d.x = v.x - float(map_width) / 2.0
#				v3d.z = v.x - float(map_height) / 2.0
#				v3d.y = get_height(v3d.x, v3d.z)
#				v3d.y = 0
#				v3d *= 0.005
#				mesh_aabb = mesh_aabb.expand(v3d)
#				if p.road:
#					verts_road.push_back(v3d)
#					normals_road.push_back(Vector3(0, 1, 0))
#					indices_road.push_back(idx_road + vid)
#				else:
#					verts_lot.push_back(v3d)
#					normals_lot.push_back(Vector3(0, 1, 0))
#					indices_lot.push_back(idx_lot + vid)
#				vid += 1
#		if p.road:
#			idx_road += 3
#		else:
#			idx_lot += 3
#	print(verts_lot.size())
#	print(verts_lot)
##	print(indices_lot)
##	print(mesh_aabb)
#	arrays_roads[ArrayMesh.ARRAY_VERTEX] = verts_road
##	arrays_roads[ArrayMesh.ARRAY_NORMAL] = normals_road
##	arrays_roads[ArrayMesh.ARRAY_INDEX] = indices_road
#	arrays_lots[ArrayMesh.ARRAY_VERTEX] = verts_lot
##	arrays_lots[ArrayMesh.ARRAY_NORMAL] = normals_lot
##	arrays_lots[ArrayMesh.ARRAY_INDEX] = indices_lot
##	print(verts_lot)
#	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_roads)
##	arrays_lots[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array([Vector3(-1, -1, -1), Vector3(0, 0, 0), Vector3(0, 0, 1)])
#	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_lots)
##	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, PlaneMesh.new().get_mesh_arrays())
#	var mat = SpatialMaterial.new()
#	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
#	mesh.surface_set_material(0, mat)
#	mesh.surface_set_material(1, mat)
#	mesh.custom_aabb = mesh_aabb
#	var mi = MeshInstance.new()
#	vn.add_child(mi)
#	mi.mesh = mesh
#
#	return mesh

func _ready():
	set_process(false)
	rules.grid = GridRule.new()
	rnd = RandomNumberGenerator.new()
	noise = OpenSimplexNoise.new()
#	db = PointDB.new()

func inset_point(v: Dictionary, n:Dictionary, new_pos: Vector2):
	var nv = new_vertex(new_pos.x, new_pos.y)
	nv._index = vertices.size()
	nv._neighbors = []
	remove_neighbor(v, n)
	add_neighbor(v, nv)
	add_neighbor(n, nv)
	vertices.push_back(nv)

class VertexData:
	var data: Dictionary
	var _road_width: float
	var _sidewalk_width: float
	func _init(v: Dictionary, road_width: float, sidewalk_width: float):
		data = v
		_road_width = road_width
		_sidewalk_width = sidewalk_width
		assert v.has("_index")
		assert v.has("_neighbors")
	func angle_sort_helper(a, b):
		var v1: Vector2 = a[1] - a[0]
		var v2: Vector2 = b[1] - b[0]
		if v1.angle() < v2.angle():
			return true
		return false
	func get_wedges(vertices: Array) -> Array:
		assert data
		var edges = []
		for id in data._neighbors:
			edges.push_back([data.pos, vertices[id].pos, data._index, id])
		edges.sort_custom(self, "angle_sort_helper")
		var wedges = []
		for h in range(edges.size()):
			var cur = h
			var next = (h + 1) % edges.size()
			var wedge = PoolIntArray([edges[cur][3], edges[cur][2], edges[next][3]])
			wedges.push_back(wedge)
		return wedges
	func get_dir(a: Dictionary, b: Dictionary) -> Vector2:
		return (b.pos - a.pos).normalized()
	func get_dir_pos(a: Vector2, b: Vector2) -> Vector2:
		return (b - a).normalized()
	func get_tangent_pos(a: Vector2, b: Vector2) -> Vector2:
		return get_dir_pos(a, b).tangent().normalized()
	func get_tangent(a: Dictionary, b: Dictionary) -> Vector2:
		return get_tangent_pos(a.pos, b.pos)
	func get_road_end_point(a: Dictionary, intersection: Dictionary) -> Vector2:
		var dir = get_dir(intersection, a)
		return intersection.pos + dir * (_road_width + _sidewalk_width)
	func get_road_offset(a: Dictionary, b: Dictionary):
		var side = get_tangent(a, b)
		return side * _road_width
	func get_sidewalk_offset(a: Dictionary, b: Dictionary):
		var side = get_tangent(a, b)
		return side * _sidewalk_width
	func get_intersection_road_points(a: Dictionary, intersection: Dictionary, b: Dictionary):
		var mida: Vector2 = a.pos.linear_interpolate(intersection.pos, 0.5)
		var midb: Vector2 = b.pos.linear_interpolate(intersection.pos, 0.5)
		var enda: Vector2 = get_road_end_point(a, intersection)
		var endb: Vector2 = get_road_end_point(b, intersection)
		var dira: Vector2 = get_dir(a, intersection)
		var dirb: Vector2 = get_dir(intersection, b)
		var offset_a = get_tangent_pos(a.pos, enda) * _road_width
		var offset_b = get_tangent_pos(endb, b.pos) * _road_width
		# a.pos enda.pos intersection.pos endb.pos b.pos
		var a_side = mida + offset_a
		var enda_side = enda + offset_a
		var b_side = midb + offset_b
		var endb_side = endb + offset_b
		var intersection_side_a = intersection.pos + offset_a
		var intersection_side_b = intersection.pos + offset_b
		var intersection_side = intersection.pos.linear_interpolate(intersection.pos + offset_a + offset_b, 0.5) 
		var mid_point = Geometry.segment_intersects_segment_2d(
									enda_side,
									intersection_side_a + dira * _road_width * 2.0,
									intersection_side_b - dirb * _road_width * 2.0,
									endb_side)
		if mid_point:
			intersection_side = mid_point
		
		var points_main = [mida, enda, intersection.pos, endb, midb]
		var points_side = [a_side, enda_side, intersection_side, endb_side, b_side]
		var triangles = []
		for k in range(5 - 1):
			triangles += [k + 5, k, k + 1, k + 5, k + 1, k + 6]
		return {
			"points_main": points_main,
			"points_side": points_side,
			"points_total": points_main + points_side,
			"triangles": triangles
		}

	func get_straight_road_segment_points(a: Dictionary, b: Dictionary):
		var mida: Vector2 = a.pos.linear_interpolate(b.pos, 0.5)
		var enda: Vector2 = get_road_end_point(a, b)
		var offset_a = get_tangent_pos(a.pos, enda) * _road_width
		var a_side = a.pos + offset_a
		var mida_side = mida + offset_a
		var enda_side = enda + offset_a
		var b_side = b.pos + offset_a
		var a_side2 = a.pos - offset_a
		var mida_side2 = mida - offset_a
		var enda_side2 = enda - offset_a
		var b_side2 = b.pos - offset_a
		var points_main = [a.pos, mida, enda, b.pos]
		var points_side = [a_side, mida_side, enda_side, b_side]
		var points_side2 = [a_side2, mida_side2, enda_side2, b_side2]
		var triangles = []
		for k in range(4 - 1):
			triangles += [k + 4, k, k + 1, k + 4, k + 1, k + 5]
		for k in range(8, 12 - 1, 1):
			triangles += [k + 4, k, k + 1, k + 4, k + 1, k + 5]
		return {
			"points_main": points_main,
			"points_side": points_side,
			"points_side2": points_side2,
			"points_total": points_side2 + points_main + points_main + points_side,
			"triangles": triangles
		}
		
	func get_wedge_road_points(wedge: Array, vertices: Array):
		if wedge[0] != wedge[2]:
			var a = vertices[wedge[0]]
			var b = vertices[wedge[2]]
			var intersection = vertices[wedge[1]]
			return get_intersection_road_points(a, intersection, b)
		else:
			var a = vertices[wedge[0]]
			var b = vertices[wedge[1]]
			return get_straight_road_segment_points(a, b)
	func get_all_road_points(vertices: Array) -> Array:
		var ret : = []
		var wedges = get_wedges(vertices)
		for wedge in wedges:
			ret.push_back(get_wedge_road_points(wedge, vertices))
		return ret

func _process(delta):
	match(state):
		STATE_INIT:
			pass
		STATE_ITERATION:
			if randf() > 0.5:
				if front.size() > 0 || vertex_queue.size() > 0:
					front = iteration(front)
				else:
					state = STATE_EDGES1
					print("vertex num: ", vertices.size())
		STATE_EDGES1:
			print_debug("iteration finished")
#			var ax_verts = []
#			for k in vertices:
#				if k.has("axiom") && k.axiom == true:
#					for l in vertices:
#						if l == k:
#							continue
#						if k in l.neighbors:
#							l.neighbors.erase(k)
#					ax_verts.push_back(k)
#			for v in ax_verts:
#				vertices.erase(v)
#			print_debug("cleanup finished")
			convert_vertices()
			print_debug("conversion finished")
			state = STATE_EDGES2
		STATE_EDGES2:
			for v in range(vertices.size()):
				var vdata = VertexData.new(roadmap.vertices[v], roadmap.road_width, roadmap.sidewalk_width)
				vertices[v]._vdata = vdata
				vertices[v]._points = vdata.get_all_road_points(vertices)
#			points = []
#			for k in vertices:
#				points.push_back(k.pos)
#			db = PointDB.new()
#			db.build_grid(points, 64)
#			print_debug("points: ", points.size())
#			assert points.size() == db._points.size()
#			for v in vertices:
#				assert db._pos2id.has(v.pos)
#			for v in vertices:
#				for n in v.neighbors:
#					assert db._pos2id.has(n.pos)
#			print_debug("data tests passed")
#			print(points.size(), " ", db._points.size())
				
#			for e in range(vertices.size()):
#				for h in vertices[e]._neighbors:
#					add_edge(e, h, true)
#			print_debug("edges added")
			state = STATE_EDGES3
		STATE_EDGES3:
			for v in range(vertices.size()):
				for entry in range(vertices[v]._points.size()):
					var points = vertices[v]._points[entry].points_total
					var points_3d = []
					for p in points:
						var p3d = Vector3(p.x - map_width * 0.5, get_height(p.x - map_width * 0.5, p.y - map_height * 0.5), p.y - map_height * 0.5)
						points_3d.push_back(p3d)
					vertices[v]._points[entry].points3d = points_3d
					
#			implode_road()
#			print(points.size(), " ", extra_points.size())
#			adjust_triangles()
#			print(points.size(), " ", extra_points.size())
#			points = PoolVector2Array(Array(points) + extra_points)
#			print(extra_points.size())
#			triangulation = Geometry.triangulate_delaunay_2d(points)
#			db.build_grid(points,64)
#			print_debug("edges3")
#
#			var bad_edges = []
#			for v in vertices:
#				for n in v.neighbors:
##					print(points.size(), " ", db._points.size())
#					assert points.size() == db._points.size()
#					assert v.pos in points
#					assert n.pos in points
#					assert v.pos in db._points
#					assert n.pos in db._points
#					if !db.add_edge_data(v.pos, n.pos, {"road": true}):
#						bad_edges.push_back([v._index, n._index])
#			if bad_edges.size() > 0:
#				print("bad edges: ", bad_edges, " ", bad_edges.size())
#			for pe in extra_points:
#				var e = db.get_point_edges(pe)
#				for d in e:
#					db.add_edge_data(d[0], d[1], {"road": true})
#				for e in bad_edges:
#						var p1: Vector2 = vertices[e[0]].pos
#						var p2: Vector2 = vertices[e[1]].pos
#						var new_pos: Vector2
#						if p1.distance_squared_to(p2) > 20.0 * 20.0:
#							new_pos = p1 + (p2 - p1).normalized() * 20.0
#						else:
#							new_pos = vertices[e[0]].pos.linear_interpolate(vertices[e[1]].pos, 0.5)
#						inset_point(vertices[e[0]], vertices[e[1]], new_pos)
#				state = STATE_EDGES2
#			else:
#				state = STATE_POLYGONS1
			state = STATE_POLYGONS1
#						
#			for p in extra_points:
#				db.add_point_data(p, {"road": false})
#				var edges = db.get_point_edges(p)
#				for me in edges:
#					var np = me[0]
#					if np == p:
#						np = me[1]
#					var edges2 = db.get_point_edges(np)
#					var road = false
#					for me2 in edges2:
#						var data = db.get_edge_data(me2[0], me2[1])
#						if data.has("road") && data.road == true:
#							road = true
#							break
#					if road:
#						db.add_edge_data(me[0], me[1], {"road": true})
						
#			update_neighbors()
#			print("neighbors updated")
#			build_edges()
#			print("edges built")
#			print_debug("edges build complete")
#			if !check_triangles():
#				print("bad triangles")
#			print(triangulation)
		STATE_POLYGONS1:
			lots = Lots.new()
			lots.generate_lots(vertices, road_width, sidewalk_width, map_width, map_height)
#			db = LotsDB.new(vertices, road_width, sidewalk_width)
#			polygon_queue = db.get_polygons()
#			for r in range(polygon_queue.size()):
#				if polygon_queue[r].size() == 6:
#					polygon_queue[r].push_back({})
#			
#			print("building polygons")
#			build_polygons()
			state = STATE_POLYGONS2
			print("polygons built")
		STATE_POLYGONS2:
#			if polygon_queue.size() > 0:
#				var item = polygon_queue.pop_front()
#				var p1 = item[0]
#				var p2 = item[1]
#				var p3 = item[2]
#				var e1 = [p1, p2]
#				var e2 = [p2, p3]
#				var e3 = [p3, p1]
#				var more_polys = []
#				if !item[6].has("type"):
#					if item[3].has("road") && item[3].road == true:
#						more_polys += implode_road_poly(0, item)
#					elif item[4].has("road") && item[3].road == true:
#						more_polys += implode_road_poly(1, item)
#					elif item[5].has("road") && item[3].road == true:
#						more_polys += implode_road_poly(2, item)
#					else:
#						assert false
					
					
#			separate_roads()
#			print(polygons)
			state = STATE_COMPLETE
		STATE_COMPLETE:
			print_debug("world build complete")
			set_process(false)
			emit_signal("complete")
			state = STATE_INIT
