extends Node2D

@export var item_scene = preload("res://supermarket simulator/scenes/item.tscn")
@onready var item_folder_node = $Items
@onready var spawn_timer = $SpawnTimer

const SPAWN_POS := Vector2(299, 206)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_spawn_timer()

func start_spawn_timer():
	spawn_timer.wait_time = randf_range(3.0, 5.0)
	spawn_timer.start()

func spawn_item():
	var item_instance = item_scene.instantiate()
	item_folder_node.add_child(item_instance)
	item_instance.z_index = -100
	item_instance.position = SPAWN_POS

func has_item_available() -> bool:
	return item_folder_node.get_child_count() > 0

func consume_item():
	if item_folder_node.get_child_count() == 0:
		return
	
	var item = item_folder_node.get_child(0)
	item.queue_free()


func _on_Spawn_timer_timeout() -> void:
	spawn_item()
	start_spawn_timer()
