extends Node3D
@export var cell_size := 1.0
var item_size := Vector3i.ONE

func build():
	for child in $Blocks.get_children():
		child.queue_free()
	
	for x in item_size.x:
		for y in item_size.y:
			for z in item_size.z:
				var cube = MeshInstance3D.new()
				cube.mesh = BoxMesh.new()
				cube.material_override = StandardMaterial3D.new()
				cube.material_override.albedo_color = Color(0, 1, 0, 0.5)
				cube.position = Vector3(x, y, z) * cell_size
				$Blocks.add_child(cube)
				
