extends Camera3D

var views = [
	Vector3(90, 0, 0), #top
	Vector3(0, 0, 0), #front
	Vector3(0, 90, 0) #side
]
var view_index := 0

func _process(_delta):
	if Input.is_action_just_pressed("view_next"):
		view_index = (view_index + 1) % views.size()
	if Input.is_action_just_pressed("view_prev"):
		view_index = (view_index - 1 + views.size()) % views.size()
		
		$Camera3D.rotation_degrees = views[view_index]
