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
				var mat := StandardMaterial3D.new()
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mat.albedo_color = Color(0, 1, 0, 0.5)
				cube.material_override = mat
				cube.position = Vector3(x, y, z) * cell_size
				$Blocks.add_child(cube)
				
