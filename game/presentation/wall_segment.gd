@tool
class_name WallSegment
extends StaticBody3D

## Editor-visible module. Edit dimensions/transform, not generated internals.
## Collision dimensions are rebuilt directly; no scaled physics bodies.
const WAINSCOT_HEIGHT: float = 1.15
const UPPER_COLOR: Color = Color("858b7c")
const LOWER_COLOR: Color = Color("3d5b4e")

@export var dimensions: Vector3 = Vector3(4.0, 3.1, 0.18):
	set(value):
		dimensions = Vector3(maxf(0.05, value.x), maxf(1.3, value.y), maxf(0.05, value.z))
		if is_node_ready():
			_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var lower_height: float = minf(WAINSCOT_HEIGHT, dimensions.y)
	_set_box("Lower", Vector3(dimensions.x, lower_height, dimensions.z), lower_height * 0.5, LOWER_COLOR)
	_set_box("Upper", Vector3(dimensions.x, dimensions.y - lower_height, dimensions.z), lower_height + (dimensions.y - lower_height) * 0.5, UPPER_COLOR)
	var collider: CollisionShape3D = get_node_or_null("Shape") as CollisionShape3D
	if collider == null:
		collider = CollisionShape3D.new()
		collider.name = "Shape"
		add_child(collider)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	collider.position.y = dimensions.y * 0.5

func _set_box(node_name: String, size: Vector3, center_y: float, color: Color) -> void:
	var instance: MeshInstance3D = get_node_or_null(node_name) as MeshInstance3D
	if instance == null:
		instance = MeshInstance3D.new()
		instance.name = node_name
		add_child(instance)
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	box.material = material
	instance.mesh = box
	instance.position.y = center_y
