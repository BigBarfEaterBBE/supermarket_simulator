extends Node2D

@export var container_size := Vector3i(6, 4, 5) #X = width, Y = heigh, Z = depth
@export var cell_size: int = 64 #pixel size
@export var views := ["top", "front", "side"]
var view_index := 0

var placed_items := [] #each entry = pos: vector3i, size: vector3i
var placed_visuals: Node2D
var grid = [] #2d array track occupancy
var cursor_3d := Vector3i.ZERO

var current_item = {"name":"Milk", "size":Vector3i(1,3,2)} # width x height x depth
var preview_rect: ColorRect
var grid_lines: Node2D
var grid_size: Vector2i

var grid_offset: Vector2

func _ready():
	#create grid lines
	grid_lines = Node2D.new()
	grid_lines.position = get_viewport_rect().size / 2
	add_child(grid_lines)
	#init grid array
	rebuild_grid()
	#creatae prev
	preview_rect = ColorRect.new()
	preview_rect.color = Color(0,1,0,0.5)
	add_child(preview_rect)
	#hold placed visuals
	placed_visuals = Node2D.new()
	add_child(placed_visuals)
	
	update_preview()

func draw_grid_lines():
	for child in grid_lines.get_children():
		child.queue_free()
	var line_color = Color(0.7, 0.7, 0.7)
	#vert lines
	for x in range(grid_size.x + 1):
		var line = Line2D.new()
		line.width = 2
		line.default_color = line_color
		line.points = [
			Vector2(x * cell_size, 0) - grid_offset,
			Vector2(x * cell_size, grid_size.y * cell_size) - grid_offset
		]
		grid_lines.add_child(line)
	#horizontal lines
	for y in range(grid_size.y + 1):
		var line = Line2D.new()
		line.width = 2
		line.default_color = line_color
		line.points = [
			Vector2(0, y * cell_size) - grid_offset,
			Vector2(grid_size.x * cell_size, y * cell_size) - grid_offset
		]
		grid_lines.add_child(line)

func _process(_delta):
	handle_input()
	update_preview()

func handle_input():
	var delta := Vector3i.ZERO
	match views[view_index]:
		"top":
			if Input.is_action_just_pressed("move_left"): delta.x -= 1
			if Input.is_action_just_pressed("move_right"): delta.x += 1
			if Input.is_action_just_pressed("move_up"): delta.z -= 1
			if Input.is_action_just_pressed("move_down"): delta.z += 1
		"front":
			if Input.is_action_just_pressed("move_left"): delta.x -= 1
			if Input.is_action_just_pressed("move_right"): delta.x += 1
			if Input.is_action_just_pressed("move_up"): delta.y -= 1
			if Input.is_action_just_pressed("move_down"): delta.y += 1
		"side":
			if Input.is_action_just_pressed("move_left"): delta.z -= 1
			if Input.is_action_just_pressed("move_right"): delta.z += 1
			if Input.is_action_just_pressed("move_up"): delta.y -= 1
			if Input.is_action_just_pressed("move_down"): delta.y += 1
	cursor_3d += delta
	#clamp container
	var item: Vector3i = current_item["size"]
	cursor_3d.x = clamp(cursor_3d.x, 0, container_size.x - item.x)
	cursor_3d.y = clamp(cursor_3d.y, 0, container_size.y - item.y)
	cursor_3d.z = clamp(cursor_3d.z, 0, container_size.z - item.z)
	#switch view
	if Input.is_action_just_pressed("view_next"):
		view_index = (view_index + 1) % views.size()
		update_grid_view()
	if Input.is_action_just_pressed("view_prev"):
		view_index = (view_index - 1 + views.size()) % views.size()
		update_grid_view()
		
	#place item
	if Input.is_action_just_pressed("place_item"):
		var cursor_2d := get_cursor_2d_for_view()
		var item_size_2d := get_item_size_for_view()
		if can_place(item_size_2d, cursor_2d):
			place_item(item_size_2d, cursor_2d)
			redraw_placed_items()

func update_preview():
	var cursor_2d := get_cursor_2d_for_view()
	var item_size_2d := get_item_size_for_view()
	
	preview_rect.size = Vector2(
		item_size_2d.x * cell_size,
		item_size_2d.y * cell_size
	)
	preview_rect.position = get_viewport_rect().size / 2 - grid_offset + Vector2(cursor_2d.x * cell_size, cursor_2d.y * cell_size)
	preview_rect.color = (Color(0,1,0,0.5) if can_place(item_size_2d, cursor_2d) else Color(1,00,0,0.5))

func can_place(size: Vector2i, pos: Vector2i) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			var gx = pos.x + x
			var gy = pos.y + y
			if gx >= grid_size.x or gy >= grid_size.y:
				return false
			if grid[gy][gx]:
				return false
	return true

func place_item(size: Vector2i, pos: Vector2i):
	placed_items.append({
		"pos": cursor_3d,
		"size": current_item["size"]
	})
	rebuild_grid()

func update_grid_view():
	rebuild_grid()
	redraw_placed_items()
	
	var colors = [
		Color(0.7, 0.7, 0.7),
		Color(0.6,0.6,1.0),
		Color(1.0,0.6,0.6)
	]
	
	for line in grid_lines.get_children():
		line.default_color = colors[view_index]

#return active 2d grid size
func get_grid_size_for_view() -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(container_size.x, container_size.z)
		"front":
			return Vector2i(container_size.x, container_size.y)
		"side":
			return Vector2i(container_size.z, container_size.y)
	return Vector2i.ZERO

func rebuild_grid():
	grid_size = get_grid_size_for_view()
	grid.clear()
	grid.resize(grid_size.y)
	for y in range(grid_size.y):
		grid[y] = []
		for x in range(grid_size.x):
			grid[y].append(false)
	#project placed items
	for item in placed_items:
		var size_2d := get_item_size_for_view_from_3d(item["size"])
		var pos_2d := get_cursor_2d_for_view_from_3d(item["pos"])
		for y in range(size_2d.y):
			for x in range(size_2d.x):
				var gx := pos_2d.x + x
				var gy := pos_2d.y + y
				if gx >= 0 and gy >= 0 and gx < grid_size.x and gy < grid_size.y:
					grid[gy][gx] = true
	grid_offset = Vector2(
		grid_size.x * cell_size / 2,
		grid_size.y * cell_size / 2
	)
	draw_grid_lines()

func get_item_size_for_view() -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(current_item["size"].x, current_item["size"].z)
		"front":
			return Vector2i(current_item["size"].x, current_item["size"].y)
		"side":
			return Vector2i(current_item["size"].z, current_item["size"].y)
	return Vector2i.ONE

func get_cursor_2d_for_view() -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(cursor_3d.x, cursor_3d.z)
		"front":
			return Vector2i(cursor_3d.x, cursor_3d.y)
		"side":
			return Vector2i(cursor_3d.z, cursor_3d.y)
	return Vector2i.ZERO

func redraw_placed_items():
	for child in placed_visuals.get_children():
		child.queue_free()
	
	for item in placed_items:
		var rect := ColorRect.new()
		rect.color = Color(0.2, 0.8, 0.2, 0.8)
		
		var size_2d := get_item_size_for_view_from_3d(item["size"])
		var pos_2d := get_cursor_2d_for_view_from_3d(item["pos"])
		
		rect.size = Vector2(size_2d.x, size_2d.y) * cell_size
		rect.position = (get_viewport_rect().size / 2 - grid_offset + Vector2(pos_2d.x, pos_2d.y) * cell_size)
		placed_visuals.add_child(rect)

func get_item_size_for_view_from_3d(size: Vector3i) -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(size.x, size.z)
		"front":
			return Vector2i(size.x, size.y)
		"side":
			return Vector2i(size.z, size.y)
	return Vector2i.ONE

func get_cursor_2d_for_view_from_3d(pos: Vector3i) -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(pos.x, pos.z)
		"front":
			return Vector2i(pos.x,pos.y)
		"side":
			return Vector2i(pos.z,pos.y)
	return Vector2i.ZERO
