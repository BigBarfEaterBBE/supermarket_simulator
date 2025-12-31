extends Node2D

@onready var top_map := $TileMap

func _ready():
	# Ensure layer 0 exists
	top_map.set_cell(
		0,
		Vector2i(0, 0),
		0,        # your top milk tile
		Vector2i(2, 0)
	)
