extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	game.persist_scores = false
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.planets.size() == 8)
	assert(game.FIELD_RADIUS == 5700 and game.SUN_RADIUS == 112)
	assert(game.SHIP_RADIUS == 19 and game.THRUST == 310)
	assert(game.RADII[7] == 4740 and game.SIZES[4] == 92)
	assert(game.ship.distance_to(game.planets[2]) > game.SIZES[2] + game.SHIP_RADIUS, "Launch must be outside enlarged Earth")
	assert(game.ship.distance_to(game.planets[2]) < 100)
	var initial = game.planets[0]
	game.orbit_time = 10
	game.update_planets()
	assert(initial.distance_to(game.planets[0]) > 1)
	assert(game.gravity_at(Vector2(2700,0)).x < 0)
	assert(game.PLANET_MU == game.SUN_MU * 0.5, "Planet gravity must be half the sun’s strength")
	for i in 8:
		var near_point: Vector2 = game.planets[i] + Vector2(100, 0)
		var pull: Vector2 = game.planet_gravity_at(near_point, i)
		assert(pull.x < -100 and absf(pull.y) < 0.001, "Each planet must noticeably attract the ship")
		assert(pull.length() > game.planet_gravity_at(game.planets[i] + Vector2(300, 0), i).length(), "Gravity must weaken with distance")
		assert(game.planet_gravity_at(game.planets[i], i) == Vector2.ZERO, "Planet centers must have finite gravity")
		for distance in range(1, 201):
			assert(is_finite(game.planet_gravity_at(game.planets[i] + Vector2(distance, 0), i).length()), "Strong planet gravity must remain finite")
	# Compare identical coasting steps with Neptune nearby and far away.
	game.running = true
	game.ship = game.planets[7] + Vector2(100, 0)
	game.velocity = Vector2.ZERO
	game._physics_process(1.0 / 60)
	var nearby_velocity: Vector2 = game.velocity
	var original_phase: float = game.phases[7]
	game.reset_run()
	game.running = true
	game.ship = game.planets[7] + Vector2(100, 0)
	game.velocity = Vector2.ZERO
	game.phases[7] += PI
	game._physics_process(1.0 / 60)
	assert(nearby_velocity.x < game.velocity.x - 0.5, "Planet gravity must affect actual ship motion")
	game.phases[7] = original_phase
	game.reset_run()
	game.running = true
	game.elapsed = 123.45
	game.ship = game.planets[2]
	game.check_visits()
	assert(game.visited.is_empty())
	for i in 8:
		if i != 2:
			game.ship = game.planets[i]
			game.check_visits()
	assert(game.won and game.visited.size() == 7)
	game.reset_run()
	assert(not game.won and game.visited.is_empty() and game.elapsed == 0)
	game.running = true
	for i in 600:
		game._physics_process(1.0/60)
	assert(is_finite(game.ship.x) and is_finite(game.velocity.y))
	game.ship = Vector2(70, 0)
	game.velocity = Vector2(-200, 60)
	game.resolve_sun_collision()
	assert(game.ship.is_equal_approx(Vector2(game.SUN_RADIUS + game.SHIP_RADIUS, 0)), "Sun penetration was not resolved")
	assert(game.velocity.is_equal_approx(Vector2(200, 60)), "Sun bounce must reflect inward velocity and retain tangential velocity")
	game.ship = Vector2(70, 0)
	game.velocity = Vector2(200, 60)
	game.resolve_sun_collision()
	assert(game.velocity.is_equal_approx(Vector2(200, 60)), "Outgoing ship must not bounce inward")
	game.ship = Vector2.ZERO
	game.velocity = Vector2.ZERO
	game.resolve_sun_collision()
	assert(is_finite(game.ship.x) and game.ship.length() == game.SUN_RADIUS + game.SHIP_RADIUS, "Sun center collision must recover")
	game.reset_run()
	for i in 8:
		var radius: float = game.SIZES[i] + game.SHIP_RADIUS
		var surface_velocity: Vector2 = game.planet_velocity(i)
		game.ship = game.planets[i] + Vector2(radius - 1, 0)
		game.velocity = surface_velocity + Vector2(-200, 60)
		game.resolve_planet_collisions()
		var relative: Vector2 = game.velocity - surface_velocity
		assert(game.ship.distance_to(game.planets[i]) > radius, "Planet collision must resolve penetration")
		assert(relative.x > 0 and absf(relative.y - 60) < 0.01, "Bounce must preserve sideways motion in the planet frame")
		var escape_energy: float = game.PLANET_MU / sqrt(2.0 * radius * radius)
		assert(relative.x * relative.x * 0.5 > escape_energy, "Bounce must provide enough outward speed to escape local gravity")
		game.ship = game.planets[i]
		game.velocity = surface_velocity
		game.resolve_planet_collisions()
		assert(is_finite(game.velocity.x) and game.ship.distance_to(game.planets[i]) > radius, "Center collisions must recover safely")
	# A boost must survive the following physics frame without being cut to cruising speed.
	game.reset_run()
	game.running = true
	game.ship = game.planets[0] + Vector2(30, 0)
	game.velocity = game.planet_velocity(0) + Vector2(-200, 60)
	game.resolve_planet_collisions()
	game.ship = Vector2(2700, 0)
	game.velocity = Vector2(900, 0)
	game._physics_process(1.0 / 60)
	assert(game.velocity.length() > 890, "Escape boost must survive the speed limiter")
	game.reset_run()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview.png")
	print("PASS: Earth launch, moving orbits, gravity, seven flybys, finish, reset, stable flight, sun bounce, individual planet gravity, planet escape bounces")
	quit()
