extends SceneTree
func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")
	var m = Model.new()
	m.start(42)
	m.hp = 99
	for i in range(roundi(46.0 / (1.0 / 120.0))):
		m.step(1.0 / 120.0)
	print("distance=", m.distance, " inspector_empty=", m.inspector.is_empty(), " inspector=", m.inspector)
	m.enemies.clear()
	m._invulnerability = 0.0
	m.inspector.pattern = "bash"
	m.inspector.lane = m.lane
	m.inspector.phase = "telegraph"
	m.inspector.pattern_time = 0.89
	for i in range(6):
		m.step(1.0 / 120.0)
		print("t+", i, " phase=", m.inspector.phase, " pattern_time=", m.inspector.pattern_time, " dodged=", m.inspector.dodged, " hp=", m.hp, " invuln=", m._invulnerability, " state=", m.state)
	quit(0)
