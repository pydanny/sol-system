# Sol System

A Godot 4 vector spaceflight time trial. Open `project.godot` in Godot and press Run.

Space launches the ship from Earth. W/Up thrusts, A/D or Left/Right rotates, and S/Down brakes. Escape pauses; R restarts. Enter the outer flyby ring of Mercury, Venus, Mars, Jupiter, Saturn, Uranus, and Neptune to finish. Your elapsed time is your score; lower is better. Personal bests persist locally.

The ship stays centered as the world scrolls. Planets orbit Sol and each attracts the ship alongside the sun. Each planet has half the sun’s gravitational strength for powerful slingshot flybys. Gravity weakens with distance and is softened near planet centers to keep flight stable. Close to a planet, gravity can overpower thrust; approach with momentum to swing past it. Planet surface collisions bounce the ship relative to the moving planet, retaining sideways motion and adding an outward kick above local escape speed. Bounce boosts can exceed the normal cruising speed. Radar shows the whole compact system; edge markers point toward unvisited planets. Colliding with the sun reflects the ship’s velocity, preserving its speed and sideways motion. Outer boundary acceleration helps recover wayward flights. There is no fuel limit or hard time cutoff.

The planetary system is about 9,600 world units across, with a soft outer boundary at radius 5,700. Orbital distances, planet and sun radii, and flyby zones are doubled from the original layout. Ship size and thrust are unchanged; normal cruising speed is 680 units/second. Actual completion time depends on route and piloting; the five-minute target has not yet been validated with player testing.

Verification: `Godot --path "Sol System" --script res://verify.gd` checks launch, orbits, gravity, visits, completion, reset, and stable physics, and renders `preview.png`.
