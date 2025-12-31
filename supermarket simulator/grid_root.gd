extends Node2D

@export var milk_texture: Texture2D
@export var container_size := Vector3i(6, 4, 5) #X = width, Y = heigh, Z = depth
@export var cell_size: int = 64 #pixel size
@export var views := ["top", "front", "side"]
var view_index := 0
const FACE_COLORS = {
	"top": Color(0.9, 0.9, 0.9),
	"bottom": Color(0.3, 0.3, 0.3),
	"front": Color(0.8, 0.9, 1.0),
	"back": Color(0.5, 0.6, 0.7),
	"left": Color(0.9, 0.8, 0.7),
	"right": Color(0.7, 0.6, 0.5)
}

var placed_items := [] #each entry = pos: vector3i, size: vector3i
var placed_visuals: Node2D
var grid = [] #2d array track occupancy
var grid_3d := {} #dict<Vector3i, bool>
var cursor_3d := Vector3i.ZERO
var current_item = {"name":"Milk", "size":Vector3i(1,3,2), "rotation": Vector3i.ZERO} # width x height x depth

var preview_rect: ColorRect
var grid_lines: Node2D
var grid_size: Vector2i
var grid_offset: Vector2

func _ready():
	#create grid lines
	grid_lines = Node2D.new()
	grid_lines.position = get_viewport_rect().size / 2
	add_child(grid_lines)
	#init grid + visuals
	placed_visuals = Node2D.new()
	add_child(placed_visuals)
	rebuild_grid()
	#setup prev
	preview_rect = ColorRect.new()
	preview_rect.color = Color(0,1,0,0.5)
	add_child(preview_rect)
	update_preview()

func _process(_delta):
	handle_input()
	update_preview()

#----------------INPUTS----------------
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
			if Input.is_action_just_pressed("move_up"): delta.y += 1
			if Input.is_action_just_pressed("move_down"): delta.y -= 1
		"side":
			if Input.is_action_just_pressed("move_left"): delta.z -= 1
			if Input.is_action_just_pressed("move_right"): delta.z += 1
			if Input.is_action_just_pressed("move_up"): delta.y += 1
			if Input.is_action_just_pressed("move_down"): delta.y -= 1
	cursor_3d += delta
	clamp_cursor()
	
	#switch view
	if Input.is_action_just_pressed("view_next"):
		view_index = (view_index + 1) % views.size()
		update_grid_view()
	if Input.is_action_just_pressed("view_prev"):
		view_index = (view_index - 1 + views.size()) % views.size()
		update_grid_view()
		
	#place item
	if Input.is_action_just_pressed("place_item"):
		var place_pos := cursor_3d
		if views[view_index] == "top":
			var y := find_stack_height(cursor_3d, current_item["size"])
			if y == -1:
				return
			place_pos.y = y
		else:
			if not has_support(cursor_3d, current_item["size"]):
				return
			place_pos.y = cursor_3d.y
		placed_items.append({
			"pos": place_pos,
			"size": current_item["size"],
			"rotation": current_item["rotation"]
		})
		rebuild_grid()
		redraw_placed_items()
	
	#rotate item
	if Input.is_action_just_pressed("rotate_item"):
		rotate_current_item()
		update_preview()

func clamp_cursor():
	var size: Vector3i = current_item["size"]
	cursor_3d.x = clamp(cursor_3d.x, 0, container_size.x - size.x)
	cursor_3d.y = clamp(cursor_3d.y, 0, container_size.y - size.y)
	cursor_3d.z = clamp(cursor_3d.z, 0, container_size.z - size.z)

func place_item_if_valid(pos: Vector3i):
	# Determine the correct Y position (drop height)
	var drop_y = 0
	while drop_y < container_size.y:
		var test_pos = Vector3i(pos.x, drop_y, pos.z)
		if collides_3d(test_pos, current_item["size"]):
			break
		drop_y += 1
	drop_y -= 1  # last valid position
	
	if drop_y < 0:
		return  # can't place anywhere
	
	var placed_pos = Vector3i(pos.x, drop_y, pos.z)
	placed_items.append({"pos": placed_pos, "size": current_item["size"]})
	rebuild_grid()
	redraw_placed_items()


#----------------PREVIEW----------------
func update_preview():
	var cursor_2d := get_cursor_2d_from_3d(cursor_3d, current_item["size"])
	var size_2d := get_item_size_for_view()
	
	preview_rect.size = size_2d * cell_size
	preview_rect.position = get_viewport_rect().size / 2 - grid_offset + Vector2(cursor_2d.x * cell_size, cursor_2d.y * cell_size)
	preview_rect.color = Color(0,1,0,0.5) if can_place_preview(cursor_3d) else Color(1,0,0,0.5)

#----------------PLACEMENT----------------
func can_place_preview(pos: Vector3i) -> bool:
	if views[view_index] == "top":
		return find_stack_height(pos, current_item["size"]) != -1
	return has_support(pos, current_item["size"]) \
		and not collides_3d(pos, current_item["size"])




func can_place(size: Vector2i, pos: Vector2i) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			var gx = pos.x + x
			var gy = pos.y + y
			if gx < 0 or gy < 0 or gx >= grid_size.x or gy >= grid_size.y or grid[gy][gx]:
				return false
	return true

#----------------GRID----------------
func update_grid_view():
	rebuild_grid()
	redraw_placed_items()
	set_grid_color(view_index)

func rebuild_grid():
	# --- rebuild 3D occupancy ---
	grid_3d.clear()
	for item in placed_items:
		var pos: Vector3i = item["pos"]
		var size: Vector3i = item["size"]
		for y in range(size.y):
			for z in range(size.z):
				for x in range(size.x):
					grid_3d[pos + Vector3i(x, y, z)] = true

	# --- rebuild 2D grid for current view ---
	grid_size = get_grid_size_for_view()
	grid.clear()
	grid.resize(grid_size.y)
	for y in range(grid_size.y):
		grid[y] = []
		for x in range(grid_size.x):
			grid[y].append(false)

	# --- project 3D occupancy into 2D ---
	for cell in grid_3d.keys():
		var pos_2d := get_cursor_2d_from_3d(cell)
		if pos_2d.x >= 0 and pos_2d.y >= 0 \
		and pos_2d.x < grid_size.x and pos_2d.y < grid_size.y:
			grid[pos_2d.y][pos_2d.x] = true

	# --- grid visuals ---
	grid_offset = Vector2(
		grid_size.x * cell_size / 2,
		grid_size.y * cell_size / 2
	)
	draw_grid_lines()


func draw_grid_lines():
	for child in grid_lines.get_children():
		child.queue_free()
	var color = Color(0.7, 0.7, 0.7)
	#vert lines
	for x in range(grid_size.x + 1):
		var line = Line2D.new()
		line.width = 2
		line.default_color = color
		line.points = [
			Vector2(x * cell_size, 0) - grid_offset,
			Vector2(x * cell_size, grid_size.y * cell_size) - grid_offset
		]
		grid_lines.add_child(line)
	#horizontal lines
	for y in range(grid_size.y + 1):
		var line = Line2D.new()
		line.width = 2
		line.default_color = color
		line.points = [
			Vector2(0, y * cell_size) - grid_offset,
			Vector2(grid_size.x * cell_size, y * cell_size) - grid_offset
		]
		grid_lines.add_child(line)

func set_grid_color(index: int):
	var colors = [Color(0.7,0.7,0.7), Color(0.6,0.6,1.0), Color(1.0, 0.6,0.6)]
	for line in grid_lines.get_children():
		line.default_color = colors[index]

#----------------UTILITIES----------------
func collides_3d(pos: Vector3i, size: Vector3i) -> bool:
	for y in range(size.y):
		for z in range(size.z):
			for x in range(size.x):
				var cell = pos + Vector3i(x, y, z)
				if grid_3d.has(cell):
					return true
	return false

func find_stack_height(pos: Vector3i, size: Vector3i) -> int:
	var y := container_size.y - size.y
	while y >= 0:
		var test_pos = Vector3i(pos.x, y, pos.z)
		if has_support(test_pos, size) and not collides_3d(test_pos,size):
			return y
		y -= 1
	return -1

func get_depth_shade_factor(pos: Vector3i) -> float:
	match views[view_index]:
		"top":
			return float(pos.y) / max(1, container_size.y - 1)
		"front":
			return float(pos.z) / max(1, container_size.z - 1)
		"side":
			return float(pos.x) / max(1, container_size.x - 1)
	return 0.0

func get_grid_size_for_view() -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(container_size.x, container_size.z)
		"front":
			return Vector2i(container_size.x, container_size.y)
		"side":
			return Vector2i(container_size.z, container_size.y)
	return Vector2i.ZERO

func get_item_size_for_view() -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(current_item["size"].x, current_item["size"].z)
		"front":
			return Vector2i(current_item["size"].x, current_item["size"].y)
		"side":
			return Vector2i(current_item["size"].z, current_item["size"].y)
	return Vector2i.ONE

func get_item_size_for_view_from_3d(size: Vector3i) -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(size.x, size.z)
		"front":
			return Vector2i(size.x, size.y)
		"side":
			return Vector2i(size.z, size.y)
	return Vector2i.ONE

func get_cursor_2d_from_3d(pos: Vector3i, size: Vector3i = Vector3i.ONE) -> Vector2i:
	match views[view_index]:
		"top":
			return Vector2i(pos.x, pos.z)
		"front":
			#bottom align using height
			return Vector2i(pos.x,container_size.y - pos.y - size.y)
		"side":
			return Vector2i(pos.z,container_size.y - pos.y - size.y)
	return Vector2i.ZERO

func get_visible_face_for_item(item: Dictionary) -> String:
	var rot: Vector3i = item["rotation"]
	match views[view_index]:
		"top":
			if rot.y % 2 == 0:
				return "top"
			else:
				return "bottom"

		"front":
			if rot.z % 2 == 0:
				return "front"
			else:
				return "back"

		"side":
			if rot.x % 2 == 0:
				return "right"
			else:
				return "left"
	return "top"
		

func get_visible_face_for_view() -> String:
	match views[view_index]:
		"top":
			return "top"
		"front":
			return "front"
		"side":
			return "right"
	return "top"

func has_support(pos: Vector3i, size: Vector3i) -> bool:
	#on floor
	if pos.y == 0:
		return true
	#if box below is occupied
	for z in range(size.z):
		for x in range(size.x):
			var below := Vector3i(pos.x + x, pos.y - 1, pos.z + z)
			if grid_3d.has(below):
				return true
	return false

func redraw_placed_items():
	for child in placed_visuals.get_children():
		child.queue_free()
	
	for item in placed_items:
		var rect := ColorRect.new()
		var face := get_visible_face_for_item(item)
		var base_color = FACE_COLORS[face]
		
		var depth := get_depth_shade_factor(item["pos"])
		var shade = lerp(1.0, 0.5, depth)
		rect.color = Color(
			base_color.r * shade,
			base_color.g * shade,
			base_color.b * shade,
			0.9
		)
		
		var size_2d := get_item_size_for_view_from_3d(item["size"])
		var pos_2d := get_cursor_2d_from_3d(item["pos"], item["size"])
		
		rect.size = Vector2(size_2d.x, size_2d.y) * cell_size
		rect.position = (get_viewport_rect().size / 2 - grid_offset + Vector2(pos_2d.x, pos_2d.y) * cell_size)
		placed_visuals.add_child(rect)

func rotate_current_item():
	var size: Vector3i = current_item["size"]
	var rot: Vector3i = current_item["rotation"]
	
	match views[view_index]:
		"top":
			current_item["size"] = Vector3i(size.z, size.y, size.x)
			current_item["rotation"].y = (rot.y + 1) % 4
		"front":
			current_item["size"] = Vector3i(size.y, size.x, size.z)
			current_item["rotation"].z = (rot.z + 1) % 4
		"side":
			current_item["size"] = Vector3i(size.x, size.z, size.y)
			current_item["rotation"].x = (rot.x + 1) % 4
