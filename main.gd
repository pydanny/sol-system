extends Node2D

const INK = Color("e6f5f3")
const MUTED = Color("718c9c")
const TEAL = Color("65f5cf")
const SUN_MU = 18000000.0
const SUN_RADIUS = 56.0
const SHIP_RADIUS = 19.0
const THRUST = 310.0
const MAX_SPEED = 680.0
const NAMES = ["MERCURY", "VENUS", "EARTH", "MARS", "JUPITER", "SATURN", "URANUS", "NEPTUNE"]
const RADII = [260.0, 460.0, 690.0, 950.0, 1320.0, 1680.0, 2020.0, 2370.0]
const SIZES = [12.0, 21.0, 23.0, 17.0, 46.0, 38.0, 29.0, 28.0]
# Arcade-scaled gravitational parameters: distinct pulls, with thrust strong enough to escape.
const PLANET_MU = [260000.0, 760000.0, 900000.0, 420000.0, 2400000.0, 1850000.0, 1250000.0, 1150000.0]
const COLORS = [Color("b7aaa0"), Color("e5ba7e"), Color("63b9f7"), Color("f3836f"), Color("dfbd91"), Color("ecd49a"), Color("8adfd5"), Color("779af9")]
var planets: Array[Vector2] = []
var phases = [0.3, 2.5, -1.2, 0.7, 3.4, 1.8, 4.4, 5.6]
var ship = Vector2.ZERO
var velocity = Vector2.ZERO
var heading = 0.0
var elapsed = 0.0
var orbit_time = 0.0
var visited: Dictionary = {}
var running = false
var won = false
var paused = false
var thrusting = false
var flash = 0.0
var notice = "LAUNCH FROM EARTH"
var best = 0.0
var persist_scores = true
var trail: Array[Vector2] = []
var stars: Array[Vector3] = []
var font = ThemeDB.fallback_font

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in 280:
		stars.append(Vector3(rng.randf_range(-6000,6000), rng.randf_range(-6000,6000), rng.randf_range(0.5,1.7)))
	var save = ConfigFile.new()
	if persist_scores and save.load("user://scores.cfg") == OK:
		best = save.get_value("score", "best", 0.0)
	reset_run()

func update_planets() -> void:
	planets.clear()
	for i in 8:
		var angle: float = phases[i] + orbit_time * sqrt(SUN_MU / pow(RADII[i],3)) * 0.45
		planets.append(Vector2.from_angle(angle) * RADII[i])

func reset_run() -> void:
	orbit_time = 0.0
	elapsed = 0.0
	visited.clear()
	running = false
	won = false
	paused = false
	trail.clear()
	update_planets()
	ship = planets[2] + planets[2].normalized() * 60.0
	heading = ship.angle()
	velocity = Vector2(-planets[2].y, planets[2].x).normalized() * sqrt(SUN_MU / RADII[2]) * 0.45
	notice = "LAUNCH FROM EARTH"
	flash = 3.0

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_run()
		if event.keycode == KEY_SPACE:
			if won:
				reset_run()
			running = true
		if event.keycode == KEY_ESCAPE and running and not won:
			paused = not paused

func _physics_process(delta: float) -> void:
	thrusting = false
	if running and not won and not paused:
		elapsed += delta
		orbit_time += delta
		update_planets()
		var turn = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		heading += turn * 2.8 * delta
		thrusting = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		var acceleration = gravity_at(ship)
		if thrusting:
			acceleration += Vector2.from_angle(heading) * THRUST
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			velocity *= exp(-1.5 * delta)
		velocity = (velocity + acceleration * delta).limit_length(MAX_SPEED)
		ship += velocity * delta
		resolve_sun_collision()
		if ship.length() > 2850.0:
			velocity += -ship.normalized() * 700.0 * delta
		check_visits()
		trail.append(ship)
		if trail.size() > 180:
			trail.pop_front()
	flash = maxf(0, flash - delta)
	queue_redraw()

func resolve_sun_collision() -> void:
	var collision_radius = SUN_RADIUS + SHIP_RADIUS
	if ship.length_squared() >= collision_radius * collision_radius:
		return
	var normal = ship.normalized() if not ship.is_zero_approx() else -velocity.normalized()
	if normal.is_zero_approx():
		normal = Vector2.RIGHT
	ship = normal * collision_radius
	if velocity.dot(normal) < 0.0:
		velocity = velocity.bounce(normal)
		notice = "SOLAR BOUNCE"
		flash = 2.0

func gravity_at(point: Vector2) -> Vector2:
	var result = -point.normalized() * SUN_MU / maxf(point.length_squared(), 10000.0)
	for i in 8:
		result += planet_gravity_at(point, i)
	return result

func planet_gravity_at(point: Vector2, index: int) -> Vector2:
	var offset = planets[index] - point
	# Softening avoids singularities and makes acceleration continuous through a planet.
	var softening: float = SIZES[index] + SHIP_RADIUS
	return offset * PLANET_MU[index] / pow(offset.length_squared() + softening * softening, 1.5)

func check_visits() -> void:
	for i in 8:
		if i != 2 and not visited.has(i) and ship.distance_to(planets[i]) < SIZES[i] + 85.0:
			visited[i] = true
			notice = NAMES[i] + " VISITED"
			flash = 3.0
	if visited.size() == 7:
		won = true
		if best == 0.0 or elapsed < best:
			best = elapsed
			var save = ConfigFile.new()
			save.set_value("score", "best", best)
			if persist_scores:
				save.save("user://scores.cfg")

func label_at(pos: Vector2, value: String, size: int = 16, color: Color = INK) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func clock_text(value: float) -> String:
	return "%02d:%05.2f" % [int(value) / 60, fmod(value,60.0)]

func screen(point: Vector2) -> Vector2:
	return get_viewport_rect().size * 0.5 + point - ship

func _draw() -> void:
	var size = get_viewport_rect().size
	var center = size * 0.5
	for star in stars:
		var p = Vector2(fposmod(star.x - ship.x * 0.35, size.x), fposmod(star.y - ship.y * 0.35, size.y))
		draw_circle(p, star.z, Color(0.4,0.6,0.7,0.35))
	for i in 8:
		draw_arc(screen(Vector2.ZERO), RADII[i], 0, TAU, 160, Color(0.23,0.4,0.5,0.22), 1.0, true)
	var sun = screen(Vector2.ZERO)
	draw_circle(sun, 66, Color(1,0.65,0.25,0.07))
	draw_arc(sun, SUN_RADIUS, 0, TAU, 64, Color("ffbf64"), 2, true)
	draw_arc(sun, 45, 0, TAU, 64, Color("ffbf64"), 1, true)
	label_at(sun + Vector2(-15, 5), "SOL", 14, Color("ffbf64"))
	for j in range(1, trail.size()):
		draw_line(screen(trail[j-1]), screen(trail[j]), Color(0.3,0.95,0.8,float(j)/trail.size()*0.25), 1, true)
	for i in 8:
		var p = screen(planets[i])
		var c = COLORS[i]
		draw_circle(p,SIZES[i],Color(c,0.06))
		draw_arc(p,SIZES[i],0,TAU,48,c,2,true)
		if i == 5:
			draw_ellipse_ring(p,c)
		if i != 2:
			draw_arc(p,SIZES[i]+85,0,TAU,64,Color(TEAL if visited.has(i) else c,0.2),1,true)
		label_at(p+Vector2(SIZES[i]+12,0),NAMES[i],14,c)
		label_at(p+Vector2(SIZES[i]+12,20),"VISITED" if visited.has(i) else ("HOME" if i == 2 else "FLYBY ZONE"),11,MUTED)
		if i != 2 and not visited.has(i) and (p.x < 260 or p.x > size.x-30 or p.y < 110 or p.y > size.y-80):
			var direction = (p-center).normalized()
			var edge = center + direction * minf((size.x*0.5-285)/maxf(absf(direction.x),0.001),(size.y*0.5-115)/maxf(absf(direction.y),0.001))
			draw_circle(edge,3,c)
			label_at(edge+Vector2(8,-8),NAMES[i].substr(0,3),11,c)
	var points = PackedVector2Array([center+Vector2.from_angle(heading)*19,center+Vector2.from_angle(heading+2.5)*14,center+Vector2.from_angle(heading-2.5)*14,center+Vector2.from_angle(heading)*19])
	draw_polyline(points, TEAL, 2.3, true)
	if thrusting:
		draw_line(center-Vector2.from_angle(heading)*12,center-Vector2.from_angle(heading)*(28+randf()*12),Color("ffbf64"),3,true)
	draw_ui(size)
	if not running or won or paused:
		draw_overlay(size)

func draw_ellipse_ring(p: Vector2, c: Color) -> void:
	var points = PackedVector2Array()
	for j in 65:
		points.append(p + Vector2(cos(j*TAU/64)*60,sin(j*TAU/64)*15).rotated(-0.35))
	draw_polyline(points,c,1,true)

func draw_ui(size: Vector2) -> void:
	draw_style_box(panel_style(),Rect2(20,20,240, size.y-40))
	label_at(Vector2(42,56),"SOL SYSTEM",25)
	label_at(Vector2(43,80),"ORBITAL GRAND TOUR",11,TEAL)
	draw_line(Vector2(42,100),Vector2(238,100),Color(MUTED,0.3))
	label_at(Vector2(42,127),"FLIGHT TIME",11,MUTED)
	label_at(Vector2(42,165),clock_text(elapsed),32)
	label_at(Vector2(42,194),"PERSONAL BEST  " + (clock_text(best) if best > 0 else "—"),11,MUTED)
	label_at(Vector2(42,234),"DESTINATIONS    %d / 7" % visited.size(),13,TEAL)
	var row = 268.0
	for i in 8:
		if i == 2:
			continue
		draw_circle(Vector2(49,row-5),4,COLORS[i])
		label_at(Vector2(63,row),NAMES[i],13,INK if visited.has(i) else MUTED)
		label_at(Vector2(218,row),"✓" if visited.has(i) else "○",14,TEAL if visited.has(i) else MUTED)
		row += 29
	var radar = Vector2(140,size.y-159)
	draw_arc(radar,85,0,TAU,64,Color(MUTED,0.35),1,true)
	for i in 8:
		draw_circle(radar+planets[i]/2850*85,2.5,COLORS[i])
	draw_circle(radar,4,Color("ffbf64"))
	draw_circle(radar+ship/2850*85,3,TEAL)
	label_at(Vector2(42,size.y-49),"SYSTEM RADAR",10,MUTED)
	label_at(Vector2(288,49),"DEEP SPACE / SOL SECTOR",12,MUTED)
	label_at(Vector2(size.x-205,49),"%03d  m/s" % velocity.length(),18,TEAL)
	label_at(Vector2(288,size.y-30),"W  THRUST     A D  ROTATE     S  BRAKE     ESC  PAUSE     R  RESTART",12,MUTED)
	if flash > 0 and running:
		label_at(Vector2(288,82),notice,16,TEAL)

func panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.045,0.066,0.96)
	style.border_color = Color(0.2,0.4,0.46,0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func draw_overlay(size: Vector2) -> void:
	var p = Vector2(maxf(290,size.x*0.5-240),size.y*0.5-135)
	draw_style_box(panel_style(),Rect2(p,Vector2(510,270)))
	label_at(p+Vector2(28,40),"TOUR COMPLETE" if won else ("FLIGHT PAUSED" if paused else "SEVEN WORLDS. ONE FLIGHT."),25,TEAL)
	if won:
		label_at(p+Vector2(28,95),clock_text(elapsed),42)
		label_at(p+Vector2(28,138),"All seven planets visited. Earth is waiting.",17)
		label_at(p+Vector2(28,222),"SPACE  FLY AGAIN",15,TEAL)
	elif paused:
		label_at(p+Vector2(28,100),"Your flight clock is stopped.",18)
		label_at(p+Vector2(28,222),"ESC  RESUME",15,TEAL)
	else:
		label_at(p+Vector2(28,83),"Depart Earth. Fly through each planet's outer ring.",17)
		label_at(p+Vector2(28,115),"Gravity bends your route. Momentum is your ally.",17,MUTED)
		label_at(p+Vector2(28,155),"W / ↑ thrust · A D / ← → rotate · S / ↓ brake",16)
		label_at(p+Vector2(28,182),"Visit all seven worlds to stop the clock.",16,MUTED)
		label_at(p+Vector2(28,232),"SPACE  LAUNCH",18,TEAL)
