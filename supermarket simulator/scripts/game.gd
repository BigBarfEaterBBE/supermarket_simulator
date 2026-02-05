extends Node2D

@export var item_scene = preload("res://supermarket simulator/scenes/item.tscn")
@onready var item_folder_node = $Items
@onready var spawn_timer = $SpawnTimer
@onready var checkout = $Checkout
@onready var spawn_sfx: AudioStreamPlayer2D = $SpawnFX

const SPAWN_POS := Vector2(299, 206)

var items_remaining := 0
var alien_active := false

func start_new_alien():
	items_remaining = randi_range(2,6)
	alien_active = true
	
	checkout.appear(items_remaining)
	start_spawn_timer()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_new_alien()

func start_spawn_timer():
	spawn_timer.wait_time = randf_range(3.0, 5.0)
	spawn_timer.start()

func spawn_item():
	
	if not alien_active:
		return
	if items_remaining <= 0:
		return
	
	var item_instance = item_scene.instantiate()
	item_folder_node.add_child(item_instance)
	item_instance.z_index = -100
	item_instance.position = SPAWN_POS
	
	spawn_sfx.play()

func has_item_available() -> bool:
	return item_folder_node.get_child_count() > 0

func consume_item():
	if item_folder_node.get_child_count() == 0:
		return
	
	var item = item_folder_node.get_child(0)
	item.queue_free()
	items_remaining -= 1
	
	if items_remaining <= 0:
		end_alien()

func end_alien():
	alien_active = false
	checkout.disappear()
	spawn_timer.stop()
	
	await get_tree().create_timer(2.0).timeout
	start_new_alien()


func _on_Spawn_timer_timeout() -> void:
	spawn_item()
	start_spawn_timer()
