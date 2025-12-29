class_name ItemData

var item_name: String
var size: Vector3i
var id: int

func _init(_id, _name, _size):
	id = _id
	item_name = _name
	size = _size
