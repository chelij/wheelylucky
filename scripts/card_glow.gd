extends Control

var phase := 0.0
var glow := Color(0.884, 0.646, 0.0, 1.0)
var margin := 12.0

func _draw() -> void:
	var cw := size.x
	var ch := size.y
	if cw <= 0 or ch <= 0:
		return
	var r := 12.0
	var l := margin  # shorthand
	# Bounding box of the track (inner rect plus corner radius)
	var x1 := l
	var y1 := l
	var x2 := cw - l
	var y2 := ch - l
	# Straight segment lengths
	var sw: float = max(0.0, x2 - x1 - r * 2.0)
	var sh: float = max(0.0, y2 - y1 - r * 2.0)
	var arc_len: float = r * (PI * 0.5)
	var perim: float = sw * 2.0 + sh * 2.0 + arc_len * 4.0
	var steps := 320
	var c_tl := Vector2(x1 + r, y1 + r)
	var c_tr := Vector2(x2 - r, y1 + r)
	var c_br := Vector2(x2 - r, y2 - r)
	var c_bl := Vector2(x1 + r, y2 - r)
	for i in range(steps):
		var t: float = float(i) / float(steps)
		var dist: float = t * perim
		var d1: float = fposmod(t - phase, 1.0)
		var d2: float = fposmod(t - (phase + 0.5), 1.0)
		var d: float = min(d1, d2)
		if d > 0.3:
			continue
		var alpha: float = 1.0 if d <= 0.08 else max(0.0, 1.0 - (d - 0.12) / 0.28)
		var pt: Vector2
		if dist < sw:
			pt = Vector2(x1 + r + dist, y1)
		elif dist < sw + arc_len:
			var a: float = (dist - sw) / r - PI * 0.5
			pt = c_tr + Vector2(cos(a), sin(a)) * r
		elif dist < sw + arc_len + sh:
			var s: float = dist - sw - arc_len
			pt = Vector2(x2, y1 + r + s)
		elif dist < sw + arc_len + sh + arc_len:
			var a: float = (dist - sw - arc_len - sh) / r
			pt = c_br + Vector2(cos(a), sin(a)) * r
		elif dist < sw + arc_len + sh + arc_len + sw:
			var s: float = dist - sw - arc_len - sh - arc_len
			pt = Vector2(x2 - r - s, y2)
		elif dist < sw + arc_len + sh + arc_len + sw + arc_len:
			var a: float = (dist - sw * 2.0 - arc_len * 2.0 - sh) / r + PI * 0.5
			pt = c_bl + Vector2(cos(a), sin(a)) * r
		elif dist < sw + arc_len + sh + arc_len + sw + arc_len + sh:
			var s: float = dist - sw * 2.0 - arc_len * 3.0 - sh
			pt = Vector2(x1, y2 - r - s)
		else:
			var a: float = (dist - sw * 2.0 - arc_len * 3.0 - sh * 2.0) / r + PI
			pt = c_tl + Vector2(cos(a), sin(a)) * r
		draw_circle(pt, 4.0, Color(glow.r, glow.g, glow.b, alpha * 0.5))
