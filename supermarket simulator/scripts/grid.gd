extends Node2D

@onready var game := get_parent()

# Grid size
const SIZE_X := 4
const SIZE_Y := 6

# 2D grid dictionary: key = Vector2i(x,y), value = block type string
var grid_2d := {}

# Stores the base positions of placed blocks (not individual tiles)
var placed_blocks := []

# Cursor position 
var cursor := Vector2i(0, 0)

# Rotation state 0 = vertical 1 = horizontal
var rot := 0

# TileMap (only front view now)
@onready var front_map := $FrontViewTileMap

# Tile IDs - Only need vertical tiles now
const TILE_MILK_BOTTOM := Vector2i(3, 3)
const TILE_MILK_MIDDLE := Vector2i(3, 2)
const TILE_MILK_TOP := Vector2i(3, 1)

func _ready():
	var screen_center = get_viewport_rect().size / 3
	
	front_map.scale = Vector2(0.25, 0.25)
	front_map.position = Vector2(200,320)
	
	center_tilemap(front_map, SIZE_X, SIZE_Y)
	redraw()

func center_tilemap(map: TileMap, width: int, height: int):
	var tile_size = Vector2(map.tile_set.tile_size) * map.scale
	map.position -= Vector2(width * tile_size.x / 2, height * tile_size.y / 2)

func _input(event):
	var moved = false
	
	# Rotate the block
	if event.is_action_pressed("rotate"):
		rot = (rot + 1) % 2
		# Clamp cursor to new bounds after rotation
		if rot == 0:  # vertical
			cursor.x = clamp(cursor.x, 0, SIZE_X - 1)
			cursor.y = clamp(cursor.y, 0, SIZE_Y - 3)
		else:  # horizontal
			cursor.x = clamp(cursor.x, 0, SIZE_X - 3)
			cursor.y = clamp(cursor.y, 0, SIZE_Y - 1)
		moved = true
	
	# Move cursor left/right (x-axis)
	if event.is_action_pressed("move_left"):
		if rot == 0:  # Vertical
			cursor.x = clamp(cursor.x - 1, 0, SIZE_X - 1)
		else:  # Horizontal
			cursor.x = clamp(cursor.x - 1, 0, SIZE_X - 3)
		moved = true
	elif event.is_action_pressed("move_right"):
		if rot == 0:  # Vertical
			cursor.x = clamp(cursor.x + 1, 0, SIZE_X - 1)
		else:  # Horizontal
			cursor.x = clamp(cursor.x + 1, 0, SIZE_X - 3)
		moved = true
	
	# Move cursor up/down (y-axis)
	elif event.is_action_pressed("move_up"):
		if rot == 0:  # Vertical
			cursor.y = clamp(cursor.y + 1, 0, SIZE_Y - 3)
		else:  # Horizontal
			cursor.y = clamp(cursor.y + 1, 0, SIZE_Y - 1)
		moved = true
	elif event.is_action_pressed("move_down"):
		if rot == 0:  # Vertical
			cursor.y = clamp(cursor.y - 1, 0, SIZE_Y - 3)
		else:  # Horizontal
			cursor.y = clamp(cursor.y - 1, 0, SIZE_Y - 1)
		moved = true
	
	# Place a milk block at the cursor
	elif event.is_action_pressed("place_block"):
		if can_place_block(cursor, rot):
			place_block(cursor)
			game.consume_item()
			redraw()
	
	# Redraw if cursor moved to update preview
	if moved:
		queue_redraw()

func get_block_position(pos: Vector2i, rotation: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	if rotation == 0: #vertical, w = 1 h = 3
		positions.append(Vector2i(pos.x, pos.y))
		positions.append(Vector2i(pos.x, pos.y+1))
		positions.append(Vector2i(pos.x, pos.y+2))
	else: # horizontal w = 3 h = 1
		positions.append(Vector2i(pos.x, pos.y))
		positions.append(Vector2i(pos.x + 1, pos.y))
		positions.append(Vector2i(pos.x + 2, pos.y))
	return positions

func can_place_block(pos: Vector2i, rotation: int) -> bool:
	if not game.has_item_available():
		return false
	
	var positions = get_block_position(pos, rotation)
	for block_pos in positions:
		if is_occupied(block_pos):
			return false
	return true
	
func is_occupied(pos: Vector2i) -> bool:
	return grid_2d.has(pos)

func _update_tile(tile_pos: Vector2) -> int:
	var tile_alternate: int = 0
	tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
	return tile_alternate

func redraw():
	# Clear the TileMap
	front_map.clear()
	
	# Draw all placed blocks from their base positions
	for block_data in placed_blocks:
		var pos = block_data["position"]
		var block_rotation = block_data["rotation"]
		var y_pos = SIZE_Y - 1 - pos.y
		
		if block_rotation == 0:  # Vertical - use normal tiles
			front_map.set_cell(0, Vector2i(pos.x, y_pos), 0, TILE_MILK_BOTTOM)
			front_map.set_cell(0, Vector2i(pos.x, y_pos - 1), 0, TILE_MILK_MIDDLE)
			front_map.set_cell(0, Vector2i(pos.x, y_pos - 2), 0, TILE_MILK_TOP)
		else:  # Horizontal - use rotated tiles
			var alternate = _update_tile(Vector2(pos.x, y_pos))
			front_map.set_cell(0, Vector2i(pos.x, y_pos), 0, TILE_MILK_BOTTOM, alternate)
			front_map.set_cell(0, Vector2i(pos.x + 1, y_pos), 0, TILE_MILK_MIDDLE, alternate)
			front_map.set_cell(0, Vector2i(pos.x + 2, y_pos), 0, TILE_MILK_TOP, alternate)
	
	queue_redraw()

func _draw():
	var tile_size = Vector2(front_map.tile_set.tile_size) * front_map.scale
	var color = Color(1, 1, 1, 0.35)
	var offset = front_map.position
	
	draw_grid(SIZE_X, SIZE_Y, tile_size, color, offset)
	draw_cursor_preview(tile_size, offset)

func draw_grid(w: int, h: int, tile_size: Vector2, color: Color, offset: Vector2):
	for x in range(w + 1):
		draw_line(
			offset + Vector2(x * tile_size.x, 0),
			offset + Vector2(x * tile_size.x, h * tile_size.y),
			color
		)
	
	for y in range(h + 1):
		draw_line(
			offset + Vector2(0, y * tile_size.y),
			offset + Vector2(w * tile_size.x, y * tile_size.y),
			color
		)

func draw_cursor_preview(tile_size: Vector2, offset: Vector2):
	var can_place = can_place_block(cursor, rot)
	var cursor_color = Color(0,1,0,0.3) if can_place else Color(1, 0, 0, 0.3)
	
	if rot == 0:  # Vertical orientation (3 blocks tall, 1 block wide)
		var base_y = SIZE_Y - 1 - cursor.y
		# Draw 3 squares vertically
		for i in range(3):
			var tile_pos = Vector2i(cursor.x, base_y - i)
			var rect_pos = offset + Vector2(tile_pos.x * tile_size.x, tile_pos.y * tile_size.y)
			var rect = Rect2(rect_pos, tile_size)
			draw_rect(rect, cursor_color)
	else:  # Horizontal orientation (3 blocks wide, 1 block tall)
		var y_pos = SIZE_Y - 1 - cursor.y
		# Draw 3 squares horizontally
		for i in range(3):
			var tile_pos = Vector2i(cursor.x + i, y_pos)
			var rect_pos = offset + Vector2(tile_pos.x * tile_size.x, tile_pos.y * tile_size.y)
			var rect = Rect2(rect_pos, tile_size)
			draw_rect(rect, cursor_color)

func place_block(pos: Vector2i):
	# Mark all positions as occupied in grid_2d for collision detection
	var positions = get_block_position(pos, rot)
	for block_pos in positions:
		grid_2d[block_pos] = true  # Just mark as occupied
	
	# Store only the base position and rotation in placed_blocks for rendering
	placed_blocks.append({
		"position": pos,
		"rotation": rot,
		"type": "milk"
	})
