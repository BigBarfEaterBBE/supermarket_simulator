extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var alien: Node2D = $Alien

var items_requested := 0

func appear(item_count: int):
	alien.randomize_appearance()
	items_requested = item_count
	alien.visible = true
	anim.play("pop_in")

func disappear():
	anim.play("exit")
	alien.visible = false

func pop_in():
	anim.play("pop_in")
