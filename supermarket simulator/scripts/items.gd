extends Node

@export var speed := 70.0
@export var item_spacing := 95.0

@export var end_x := 690.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var children := get_children()
	
	for i in range(children.size()):
		var item := children[i] as Node2D
		if item == null:
			continue
		var target_x := end_x
		# If item in front, stop 
		if i> 0:
			var front_item := children[i-1] as Node2D
			target_x = front_item.position.x - item_spacing
			
		if item.position.x < target_x:
			item.position.x = min(item.position.x + speed * delta, target_x)
			
