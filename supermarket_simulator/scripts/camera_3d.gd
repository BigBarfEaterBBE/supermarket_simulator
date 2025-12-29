extends Camera3D

@export var grid_size := Vector3i(6,4,5)
var camera_distance := 10.0
var views = []
var view_index := 0

func _ready():
	projection = PROJECTION_ORTHOGONAL
	size = max(grid_size.x, grid_size.y, grid_size.z) * 1.2
	views = [
		
		Vector3(0, grid_size.y + camera_distance, 0), #top
		Vector3(0, grid_size.y * 0.5, -grid_size.z - camera_distance), # front
		Vector3(-grid_size.x - camera_distance, grid_size.y * 0.5, 0),
	
	]
	position = views[view_index]
	look_at(Vector3.ZERO, Vector3.UP)

func _process(_delta):
	if Input.is_action_just_pressed("view_next"):
		view_index = (view_index + 1) % views.size()
	if Input.is_action_just_pressed("view_prev"):
		view_index = (view_index - 1 + views.size()) % views.size()
	
	position = views[view_index]
	look_at(Vector3.ZERO, Vector3.UP)
