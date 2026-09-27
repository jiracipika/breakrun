extends SceneTree
func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")
	var m = Model.new()
	m.start(42)
	m.hp = 99
	for i in range(roundi(46.0 / (1.0 / 120.0))):
		m.step(1.0 / 120.0)
	m.hp = 3
	m.enemies.clear()
	m._invulnerability = 0.0
	m.owned_upgrades.append("relay")
	m.enemies.append({"id": 70, "kind": "dummy", "lane": -1, "z": 20.0,
		"phase": "launched", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": true, "swept": true, "ricocheted": true, "previous_z": 20.0})
	m.enemies.append({"id": 71, "kind": "dummy", "lane": 1, "z": 20.5,
		"phase": "launched", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": true, "swept": true, "ricocheted": true, "previous_z": 20.5})
	var last: int = m.score
	for i in range(30):
		m.step(1.0 / 120.0)
		if m.score != last:
			print("tick ", i, " score ", last, "->", m.score, " feedback=", m.feedback, " enemies=")
			for e in m.enemies:
				print("   id=", e.id, " kind=", e.kind, " lane=", e.lane, " z=", e.z, " phase=", e.phase)
			last = m.score
	quit(0)
