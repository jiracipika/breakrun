extends RefCounted

const SAFFRON = Color("ffca45")
const CORAL = Color("ec725b")
const COBALT = Color("283e78")
const TEAL = Color("187c83")
const PAPER = Color("fff4db")

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	parent.add_child(node)
	return node

static func build(parent: Node3D) -> Node3D:
	var world := Node3D.new()
	world.name = "World"
	parent.add_child(world)
	box(world, Vector3(8.6, 0.5, 170), Vector3(0, -0.35, -65), CORAL)
	for side in [-1, 1]:
		box(world, Vector3(0.24, 0.55, 160), Vector3(side * 4.3, 0.0, -65), PAPER)
		box(world, Vector3(0.28, 0.10, 160), Vector3(side * 4.3, 0.32, -65), COBALT)
	var tiles := Node3D.new()
	tiles.name = "Tiles"
	world.add_child(tiles)
	for i in range(18):
		var tile := Node3D.new()
		tile.position.z = -i * 8.0
		tiles.add_child(tile)
		box(tile, Vector3(8.1, 0.02, 0.08), Vector3(0, -0.08, 0), Color("cb5b50"))
		for lane_edge in [-1, 1]:
			box(tile, Vector3(0.12, 0.025, 3), Vector3(lane_edge * 1.25, -0.065, 0), PAPER)
		box(tile, Vector3(0.38, 0.03, 0.9), Vector3(3.8, -0.05, 0), SAFFRON)
	var buildings := Node3D.new()
	buildings.name = "Buildings"
	world.add_child(buildings)
	for i in range(22):
		var block := Node3D.new()
		var side: int = -1 if i % 2 == 0 else 1
		block.position = Vector3(side * (7.1 + (i % 3) * 0.9), -6, -float(i / 2) * 13)
		buildings.add_child(block)
		var h: float = 3.0 + (i % 4) * 1.6
		var c: Color = Color("d87667") if i % 3 == 0 else Color("f4a57d")
		box(block, Vector3(4.6, h + 10, 8), Vector3(0, h / 2.0 - 5, 0), c)
		box(block, Vector3(4.9, 0.22, 8.3), Vector3(0, h, 0), PAPER)
		box(block, Vector3(0.12, 0.8, 7.8), Vector3(-side * 2.31, h - 1.0, 0), COBALT)
		for w in range(3):
			box(block, Vector3(0.13, 1.25, 0.65), Vector3(-side * 2.32, h - 3.0, -2.4 + w * 2.4), TEAL)
		if i % 3 == 0:
			box(block, Vector3(2.4, 0.15, 3.3), Vector3(-side * 2.5, h - 1.5, 0), SAFFRON)
			box(block, Vector3(1.2, 1.1, 1.2), Vector3(0.4, h + 0.6, -1), TEAL)
	# The old fixed decorative gantry was removed: it read as a distant finish gate
	# and confused obstacle readability. Reusable chunk arches replace it later.
	return world

static func limb(parent: Node3D, id: String, pivot: Vector3, size: Vector3, color: Color) -> Node3D:
	var joint := Node3D.new()
	joint.name = id
	joint.position = pivot
	parent.add_child(joint)
	box(joint, size, Vector3(0, -size.y * 0.5, 0), color)
	return joint

static func courier(parent: Node3D) -> Node3D:
	var actor := Node3D.new()
	actor.name = "Runner"
	parent.add_child(actor)
	box(actor, Vector3(0.78, 0.78, 0.44), Vector3(0, 1.33, 0), SAFFRON)
	box(actor, Vector3(0.49, 0.49, 0.46), Vector3(0, 1.98, 0), Color("ad7254"))
	box(actor, Vector3(0.52, 0.18, 0.48), Vector3(0, 2.21, 0.015), COBALT)
	box(actor, Vector3(0.14, 0.6, 0.05), Vector3(0.13, 1.34, 0.25), COBALT)
	box(actor, Vector3(0.31, 0.17, 0.05), Vector3(-0.16, 1.4, 0.25), PAPER)
	for side in [-1, 1]:
		var leg := limb(actor, "LegL" if side == -1 else "LegR", Vector3(side * 0.23, 1.0, 0), Vector3(0.27, 0.82, 0.28), COBALT)
		box(leg, Vector3(0.32, 0.22, 0.52), Vector3(0, -0.8, -0.09), PAPER)
		var arm := limb(actor, "ArmL" if side == -1 else "ArmR", Vector3(side * 0.51, 1.62, 0), Vector3(0.26, 0.67, 0.30), SAFFRON)
		box(arm, Vector3(0.25, 0.23, 0.28), Vector3(0, -0.68, 0), COBALT)
		var tail := box(actor, Vector3(0.28, 0.6, 0.08), Vector3(side * 0.24, 0.83, 0.32), SAFFRON)
		tail.rotation.x = -0.30
	return actor

static func enemy(parent: Node3D, kind: String) -> Node3D:
	var actor := Node3D.new()
	parent.add_child(actor)
	if kind == "barrier":
		box(actor, Vector3(1.9, 0.85, 0.3), Vector3(0, 0.6, 0), COBALT)
		for i in range(4):
			var stripe := box(actor, Vector3(0.18, 0.85, 0.34), Vector3(-0.65 + i * 0.43, 0.6, 0), SAFFRON)
			stripe.rotation.z = -0.35
	elif kind == "hurdle":
		# Low bar but taller and higher-contrast so it reads at distance.
		box(actor, Vector3(2.1, 0.2, 0.18), Vector3(0, 0.62, 0), SAFFRON)
		box(actor, Vector3(2.1, 0.06, 0.2), Vector3(0, 0.5, 0), PAPER)
		for side in [-1, 1]:
			box(actor, Vector3(0.14, 0.62, 0.18), Vector3(side * 1.0, 0.31, 0), COBALT)
		box(actor, Vector3(2.3, 0.03, 0.5), Vector3(0, 0.015, 0), COBALT)
	else:
		var sway: float = 0.22 if kind == "dummy" else 0.0
		box(actor, Vector3(0.7, 0.85, 0.48), Vector3(sway, 1.05, 0), TEAL)
		box(actor, Vector3(0.62, 0.43, 0.45), Vector3(sway, 1.76, 0), COBALT)
		box(actor, Vector3(0.43, 0.09, 0.05), Vector3(sway, 1.78, 0.26), PAPER)
		for side in [-1, 1]:
			box(actor, Vector3(0.25, 0.6, 0.25), Vector3(side * 0.23, 0.35, 0), COBALT)
			box(actor, Vector3(0.27, 0.60, 0.27), Vector3(side * 0.5, 1.1, 0), TEAL)
		if kind == "shield":
			box(actor, Vector3(1.28, 1.4, 0.22), Vector3(0, 1.0, 0.53), TEAL)
			for i in range(3):
				var slash := box(actor, Vector3(0.13, 0.70, 0.25), Vector3(-0.32 + i * 0.32, 1.0, 0.54), PAPER)
				slash.rotation.z = -0.35
	return actor
