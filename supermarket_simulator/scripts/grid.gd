class_name Grid3D

var size: Vector3i
var cells := {}

func _init(grid_size: Vector3i):
	size = grid_size
	for x in size.x:
		for y in size.y:
			for z in size.z:
				cells[Vector3i(x,y,z)] = null

# check if user can place object
func can_place(item_size: Vector3i, pos: Vector3i) -> bool:
	for x in item_size.x:
		for y in item_size.y:
			for z in item_size.z:
				var p = pos + Vector3i(x, y, z)
				
				if not cells.has(p):
					return false
				if cells[p] != null:
					return false
	return true

# place item
func place(item_id: int, item_size: Vector3i, pos: Vector3i):
	for x in item_size.x:
		for y in item_size.y:
			for z in item_size.z:
				cells[pos + Vector3i(x, y, z)] = item_id
