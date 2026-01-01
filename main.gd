extends Node2D

# Grid size
const SIZE_X := 6
const SIZE_Y := 4
const SIZE_Z := 5

# 3D grid dictionary: key = Vector3i(x,y,z), value = block type string
var grid_3d := {}

# Cursor position
var cursor := Vector3i(0,0,0)

# TileMaps
@onready var top_map := $TopViewTileMap
@onready var front_map := $FrontViewTileMap
@onready var side_map := $SideViewTileMap

# Views
enum View { TOP, FRONT, SIDE }
var current_view := View.TOP

# Tile IDs
const TILE_GRID := Vector2i(2,0)
const TILE_MILK_TOP := Vector2i(2, 0)
const TILE_MILK_FRONT := Vector2i(3,1)
const TILE_MILK_SIDE := Vector2i(1,1)

func _ready():
	var screen_center = get_viewport_rect().size / 2

	top_map.scale = Vector2(0.25, 0.25)
	front_map.scale = Vector2(0.25, 0.25)
	side_map.scale = Vector2(0.25, 0.25)

	top_map.position = screen_center
	front_map.position = screen_center
	side_map.position = screen_center

	center_tilemap(top_map, SIZE_X, SIZE_Z)
	center_tilemap(front_map, SIZE_X, SIZE_Y)
	center_tilemap(side_map, SIZE_Z, SIZE_Y)


	top_map.visible = true
	front_map.visible = false
	side_map.visible = false

	redraw()


func center_tilemap(map: TileMap, width: int, height: int):
	var tile_size = map.tile_set.tile_size * Vector2i(map.scale)
	# Offset so the TileMap is centered at its current position
	map.position -= Vector2(width * tile_size.x / 2, height * tile_size.y / 2)

func _input(event):
	# Move cursor
	if event.is_action_pressed("move_left"):
		cursor.x = clamp(cursor.x - 1, 0, SIZE_X - 1)
	elif event.is_action_pressed("move_right"):
		cursor.x = clamp(cursor.x + 1, 0, SIZE_X - 1)
	elif event.is_action_pressed("move_up"):
		cursor.z = clamp(cursor.z - 1, 0, SIZE_Z - 1)
	elif event.is_action_pressed("move_down"):
		cursor.z = clamp(cursor.z + 1, 0, SIZE_Z - 1)
	elif event.is_action_pressed("move_up_y"):
		cursor.y = clamp(cursor.y + 1, 0, SIZE_Y - 1)
	elif event.is_action_pressed("move_down_y"):
		cursor.y = clamp(cursor.y - 1, 0, SIZE_Y - 1)

	# Place a milk block at the cursor
	elif event.is_action_pressed("place_block"):
		grid_3d[cursor] = "milk"
		redraw()

	# Switch views
	elif event.is_action_pressed("view_top"):
		current_view = View.TOP
		top_map.visible = true
		front_map.visible = false
		side_map.visible = false
		redraw()
	elif event.is_action_pressed("view_front"):
		current_view = View.FRONT
		top_map.visible = false
		front_map.visible = true
		side_map.visible = false
		redraw()
	elif event.is_action_pressed("view_side"):
		current_view = View.SIDE
		top_map.visible = false
		front_map.visible = false
		side_map.visible = true
		redraw()

func redraw():
	# Clear all TileMaps
	top_map.clear()
	front_map.clear()
	side_map.clear()
	for x in range(SIZE_X):
		for z in range(SIZE_Z):
			top_map.set_cell(0, Vector2i(x,z), 0, TILE_GRID)

	for x in range(SIZE_X):
		for y in range(SIZE_Y):
			front_map.set_cell(0, Vector2i(x, SIZE_Y - 1 - y), 0, TILE_GRID)

	for z in range(SIZE_Z):
		for y in range(SIZE_Y):
			side_map.set_cell(0, Vector2i(z, SIZE_Y - 1 - y), 0, TILE_GRID)

	# --- DRAW PLACED BLOCKS OVER GRID ---
	for pos in grid_3d.keys():
		top_map.set_cell(0, Vector2i(pos.x, pos.z), 0, TILE_MILK_TOP)
		front_map.set_cell(0, Vector2i(pos.x, SIZE_Y - 1 - pos.y), 0, TILE_MILK_FRONT)
		side_map.set_cell(0, Vector2i(pos.z, SIZE_Y - 1 - pos.y), 0, TILE_MILK_SIDE)
	queue_redraw()
func _draw():
	var map := get_active_map()
	if map == null:
		return

	var tile_size = map.tile_set.tile_size * Vector2i(map.scale)
	var color = Color(1, 1, 1, 0.35)

	var offset = map.position

	match current_view:
		View.TOP:
			draw_grid(SIZE_X, SIZE_Z, tile_size, color, offset)
		View.FRONT:
			draw_grid(SIZE_X, SIZE_Y, tile_size, color, offset)
		View.SIDE:
			draw_grid(SIZE_Z, SIZE_Y, tile_size, color, offset)

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

func get_active_map() -> TileMap:
	match current_view:
		View.TOP:
			return top_map
		View.FRONT:
			return front_map
		View.SIDE:
			return side_map
	return null
