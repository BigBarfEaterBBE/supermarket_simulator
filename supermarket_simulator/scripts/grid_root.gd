extends Node3D
@export var grid_size := Vector3i(6, 4, 5)
@export var cell_size := 1.0

var grid: Grid3D
var cursor := Vector3i.ZERO
var current_item := ItemData.new(1, "Milk", Vector3i(1,3,1))
var preview
var offset: Vector3

#create grid cubes
func _ready():
	offset = Vector3( (grid_size.x - 1) * 0.5, (grid_size.y - 1) *0.5, (grid_size.z - 1) * 0.5) * cell_size
	preview = preload("res://supermarket_simulator/scenes/item_preview.tscn").instantiate()
	preview.item_size = current_item.size
	preview.build()
	add_child(preview)
	grid = Grid3D.new(grid_size)
	for x in grid_size.x:
		for y in grid_size.y:
			for z in grid_size.z:
				var cube = MeshInstance3D.new()
				cube.mesh = BoxMesh.new()
				var mat := StandardMaterial3D.new()
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mat.albedo_color = Color(0.85, 0.95, 0.85)
				cube.material_override = mat
				cube.scale = Vector3.ONE * 0.95
				cube.position = (Vector3(x, y, z) * cell_size) - offset
				$Cells.add_child(cube)

#movement
func _process(_delta):
	if Input.is_action_just_pressed("move_left"):
		cursor.x -= 1
	if Input.is_action_just_pressed("move_right"):
		cursor.x += 1
	if Input.is_action_just_pressed("move_forward"):
		cursor.z -= 1
	if Input.is_action_just_pressed("move_back"):
		cursor.z += 1
	
	cursor = cursor.clamp(Vector3i.ZERO, grid_size - Vector3i.ONE)
	
	update_preview()
	
	if Input.is_action_just_pressed("place_item"):
		if grid.can_place(current_item.size, cursor):
			grid.place(current_item.id, current_item.size, cursor)

func update_preview():
	preview.position = (Vector3(cursor) *  cell_size) - offset
	var valid = grid.can_place(current_item.size, cursor)
	for cube in preview.get_node("Blocks").get_children():
		if valid:
			cube.material_override.albedo_color = Color(0, 1, 0, 0.5)
		else:
			cube.material_override.albedo_color = Color(1, 0, 0, 0.5)
