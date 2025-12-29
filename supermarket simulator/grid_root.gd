extends Node2D

@export var grid_size: Vector2i = Vector2i(6, 4) #columns, rows
@export var cell_size: int = 64 #pixel size
@export var views := ["top", "front", "side"]
var view_index := 0

var grid = [] #2d array track occupancy
var cursor := Vector2i.ZERO

var current_item = {"name":"Milk", "size":Vector2i(1,3)} # width x height
var preview_rect: ColorRect
var grid_lines: Node2D

var grid_offset: Vector2

func _ready():
	#init grid array
	grid.resize(grid_size.y)
	for y in range(grid_size.y):
		grid[y] = []
		for x in range(grid_size.x):
			grid[y].append(false) #false = empty
	#center grid
	grid_offset = Vector2((grid_size.x * cell_size)/2, (grid_size.y * cell_size)/2)
	#create grid lines
	grid_lines = Node2D.new()
	grid_lines.position = get_viewport_rect().size / 2
	add_child(grid_lines)
	draw_grid_lines()
	#creatae prev
	preview_rect = ColorRect.new()
	preview_rect.color = Color(0,1,0,0.5)
	preview_rect.size = Vector2(
		current_item["size"].x * cell_size,
		current_item["size"].y * cell_size
	)
	preview_rect.position = get_viewport_rect().size / 2 -grid_offset
	add_child(preview_rect)
	
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
	#wasd moves cursor
	if Input.is_action_just_pressed("move_left"):
		cursor.x = max(0, cursor.x - 1)
	if Input.is_action_just_pressed("move_right"):
		cursor.x = min(grid_size.x - current_item["size"].x, cursor.x + 1)
	if Input.is_action_just_pressed("move_up"):
		cursor.y = max(0, cursor.y - 1)
	if Input.is_action_just_pressed("move_down"):
		cursor.y = min(grid_size.y - current_item["size"].y, cursor.y + 1)
	#switch view
	if Input.is_action_just_pressed("view_next"):
		view_index = (view_index + 1) % views.size()
		update_grid_view()
	if Input.is_action_just_pressed("view_prev"):
		view_index = (view_index - 1 + views.size()) % views.size()
		update_grid_view()
		
	#place item
	if Input.is_action_just_pressed("place_item"):
		if can_place(current_item["size"], cursor):
			place_item(current_item["size"], cursor)

func update_preview():
	preview_rect.position = get_viewport_rect().size / 2 - grid_offset + Vector2(cursor.x * cell_size, cursor.y * cell_size)

	if can_place(current_item["size"], cursor):
		preview_rect.color = Color(0, 1, 0, 0.5)
	else:
		preview_rect.color = Color(1,0,0,0.5)

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
	for y in range(size.y):
		for x in range(size.x):
			grid[pos.y + y][pos.x + x] = true

func update_grid_view():
	#tint grid diff for each view FOR NOW
	var colors = [Color(0.7, 0.7, 0.7), Color(0.6, 0.6, 1), Color(1, 0.6, 0.6)]
	for line in grid_lines.get_children():
		line.default_color = colors[view_index]
