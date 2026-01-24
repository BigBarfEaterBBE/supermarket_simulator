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

#rotation
var rotation_state ={
	"xy": 0,
	"xz": 0,
	"yz": 0
}

# Tile IDs
const TILE_GRID := Vector2i(2,0)
const TILE_MILK_TOP := Vector2i(2, 0)
const TILE_MILK_FRONT_MIDDLE := Vector2i(3,2)
const TILE_MILK_FRONT_BOTTOM := Vector2i(3,3)
const TILE_MILK_FRONT_TOP := Vector2i(3,1)
const TILE_MILK_SIDE_BOTTOM := Vector2i(1,3)
const TILE_MILK_SIDE_MIDDLE := Vector2i(1,2)
const TILE_MILK_SIDE_TOP := Vector2i(1,1)
const TILE_MILK_TOP_XY := Vector2i(1, 0)
const TILE_MILK_FRONT_BOTTOM_XY = Vector2i(0,2)
const TILE_MILK_FRONT_MIDDLE_XY = Vector2i(1,2)
const TILE_MILK_FRONT_TOP_XY = Vector2i(2,2)
const TILE_MILK_SIDE_BOTTOM_XY = Vector2i(0,1)
const TILE_MILK_SIDE_MIDDLE_XY = Vector2i(1,1)
const TILE_MILK_SIDE_TOP_XY = Vector2i(2,1)

var TILE_MAP = {
	"none": {
		"top": [TILE_MILK_TOP],
		"front": [TILE_MILK_FRONT_BOTTOM, TILE_MILK_FRONT_MIDDLE, TILE_MILK_FRONT_TOP],
		"side": [TILE_MILK_SIDE_BOTTOM, TILE_MILK_SIDE_MIDDLE, TILE_MILK_SIDE_TOP]
	},
	"xy": {
		"top": [TILE_MILK_TOP_XY],
		"front": [TILE_MILK_FRONT_BOTTOM_XY, TILE_MILK_FRONT_MIDDLE_XY, TILE_MILK_FRONT_TOP_XY],
		"side": [TILE_MILK_SIDE_TOP_XY, TILE_MILK_SIDE_MIDDLE_XY, TILE_MILK_SIDE_MIDDLE_XY]
	},
	"xz": {
		"top": [TILE_MILK_FRONT_BOTTOM, TILE_MILK_FRONT_MIDDLE, TILE_MILK_FRONT_TOP],
		"front": [TILE_MILK_SIDE_BOTTOM, TILE_MILK_SIDE_MIDDLE, TILE_MILK_SIDE_TOP],
		"side": [TILE_MILK_TOP]
	},
	"yz": {
		"top": [TILE_MILK_SIDE_BOTTOM, TILE_MILK_SIDE_MIDDLE, TILE_MILK_SIDE_TOP],
		"front": [TILE_MILK_TOP],
		"side": [TILE_MILK_FRONT_BOTTOM, TILE_MILK_FRONT_MIDDLE, TILE_MILK_FRONT_TOP]
	}
}

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
	var tile_size = Vector2(map.tile_set.tile_size) * map.scale
	# Offset so the TileMap is centered at its current position
	map.position -= Vector2(width * tile_size.x / 2, height * tile_size.y / 2)

func _input(event):
	#rotation
	if event.is_action_pressed("rotate_xy"):
		rotation_state["xy"] = (rotation_state["xy"] + 1) % 2
	elif event.is_action_pressed("rotate_xz"):
		rotation_state["xz"] = (rotation_state["xz"] + 1) % 2
	elif event.is_action_pressed("rotate_yz"):
		rotation_state["yz"] = (rotation_state["yz"] + 1) % 2
	# Move cursor
	if event.is_action_pressed("move_left"):
		match current_view:
			View.TOP, View.FRONT:
				cursor.x = clamp(cursor.x - 1, 0, SIZE_X - 1)
			View.SIDE:
				cursor.z = clamp(cursor.z - 1, 0, SIZE_Z - 1)

	elif event.is_action_pressed("move_right"):
		match current_view:
			View.TOP, View.FRONT:
				cursor.x = clamp(cursor.x + 1, 0, SIZE_X - 1)
			View.SIDE:
				cursor.z = clamp(cursor.z + 1, 0, SIZE_Z - 1)

	elif event.is_action_pressed("move_up"):
		match current_view:
			View.TOP:
				cursor.z = clamp(cursor.z - 1, 0, SIZE_Z - 1)
			View.FRONT, View.SIDE:
				cursor.y = clamp(cursor.y + 1, 0, SIZE_Y - 1)

	elif event.is_action_pressed("move_down"):
		match current_view:
			View.TOP:
				cursor.z = clamp(cursor.z + 1, 0, SIZE_Z - 1)
			View.FRONT, View.SIDE:
				cursor.y = clamp(cursor.y - 1, 0, SIZE_Y - 1)

	# Place a milk block at the cursor
	elif event.is_action_pressed("place_block"):
		place_block(cursor)
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
	# --- DRAW PLACED BLOCKS OVER GRID ---
	for pos in grid_3d.keys():
		top_map.set_cell(0, Vector2i(pos.x, pos.z), 0, TILE_MILK_TOP)
		# front
		var base_y_front = SIZE_Y - 1- pos.y
		front_map.set_cell(0, Vector2i(pos.x, base_y_front), 0, TILE_MILK_FRONT_BOTTOM)
		front_map.set_cell(0, Vector2i(pos.x, base_y_front - 1), 0, TILE_MILK_FRONT_MIDDLE)
		front_map.set_cell(0, Vector2i(pos.x, base_y_front - 2), 0, TILE_MILK_FRONT_TOP)
		#side
		var base_y_side = SIZE_Y - 1 - pos.y
		side_map.set_cell(0, Vector2i(pos.z, base_y_side), 0, TILE_MILK_SIDE_BOTTOM)
		side_map.set_cell(0, Vector2i(pos.z, base_y_side - 1), 0, TILE_MILK_SIDE_MIDDLE)
		side_map.set_cell(0, Vector2i(pos.z, base_y_side - 2), 0, TILE_MILK_SIDE_TOP)
	queue_redraw()
func _draw():
	var map := get_active_map()
	if map == null:
		return

	var tile_size = Vector2(map.tile_set.tile_size) * map.scale
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

func place_block(pos: Vector3i):
	var _rotation = "none"
	if rotation_state["xy"] == 1:
		_rotation = "xy"
	elif rotation_state["xz"] == 1:
		_rotation = "xz"
	elif rotation_state["yz"] == 1:
		_rotation = "yz"
	#select tile atlas 0 = normal 1 = rotated
	var atlas_id
	if _rotation == "xy":
		atlas_id = 0
	else:
		atlas_id = 1
	# get correct tile set for rotation
	var tiles = TILE_MAP[_rotation]
	var face_map = {}
	match _rotation:
		"none", "xy":
			face_map = {
				"top": "top",
				"front": "front",
				"side": "side"
			}
		"xz":
			face_map = {
				"top": "side",
				"front": "top",
				"side": "front"
			}
		"yz":
			face_map = {
				"top": "front",
				"front": "side",
				"side": "top"
			}
	grid_3d[Vector3i(pos.x, pos.y, pos.z)] = {
		"type": "milk",
		"rotation": _rotation
	}
	
	#drawing block
	var top_tile_array = tiles[face_map["top"]]
	for i in range(top_tile_array.size()):
		top_map.set_cell(0, Vector2i(pos.x, pos.z - i), atlas_id, top_tile_array[i])
	var front_tile_array = tiles[face_map["front"]]
	for i in range(front_tile_array.size()):
		front_map.set_cell(0, Vector2i(pos.x, SIZE_Y - 1 - pos.y - i), atlas_id, front_tile_array[i])
	var side_tile_array = tiles[face_map["side"]]
	for i in range(side_tile_array.size()):
		side_map.set_cell(0, Vector2i(pos.z, SIZE_Y - 1 - pos.y - i), atlas_id, side_tile_array[i])

func get_rotation_key() -> String:
	#prio xy, xz, yz
	if rotation_state["xy"] == 1:
		return "xy"
	elif rotation_state["xz"] == 1:
		return "xz"
	elif rotation_state["yz"] == 1:
		return "yz"
	else:
		return "none"
