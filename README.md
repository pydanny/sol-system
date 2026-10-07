# Sol System

A Godot 4 vector spaceflight time trial. Open `project.godot` in Godot and press Run.

Space launches the ship from Earth. W/Up thrusts, A/D or Left/Right rotates, and S/Down brakes. Escape pauses; R restarts. Enter the outer flyby ring of Mercury, Venus, Mars, Jupiter, Saturn, Uranus, and Neptune to finish. Your elapsed time is your score; lower is better. Personal bests persist locally.

The ship stays centered as the world scrolls. Planets orbit Sol and each attracts the ship alongside the sun. Each world has its own gravity strength; gas giants pull harder, close flybys bend your trajectory, and gravity weakens with distance. Forces are softened near planet centers to keep flight stable and allow escape under thrust. Radar shows the whole compact system; edge markers point toward unvisited planets. Colliding with the sun reflects the ship’s velocity, preserving its speed and sideways motion. Outer boundary acceleration helps recover wayward flights. There is no fuel limit or hard time cutoff.

The system is about 4,800 world units across and maximum ship speed is 680 units/second, intended for short runs. Actual completion time depends on route and piloting; the five-minute target has not yet been validated with player testing.

Verification: `Godot --path "Sol System" --script res://verify.gd` checks launch, orbits, gravity, visits, completion, reset, and stable physics, and renders `preview.png`.
