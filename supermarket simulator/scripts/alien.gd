extends Node2D

@onready var bodySprite := $Body
@onready var eyesSprite := $Eyes
@onready var earsSprite := $Ears
@onready var pupilsSprite := $Pupils
@onready var mouthSprite := $Mouth

const bodies = {
	0: preload("res://supermarket simulator/assets/body0.png")
}

const ears = {
	0: preload("res://supermarket simulator/assets/ears0.png"),
	1: preload("res://supermarket simulator/assets/ears0.png"),
	2: preload("res://supermarket simulator/assets/ears2.png")
}

const eyes = {
	0: preload("res://supermarket simulator/assets/eyes0.png")
}

const mouths = {
	0: preload("res://supermarket simulator/assets/mouth0.png"),
	1: preload("res://supermarket simulator/assets/mouth1.png"),
	2: preload("res://supermarket simulator/assets/mouth2.png")
}

const pupils = {
	0: preload("res://supermarket simulator/assets/pupil0.png"),
	1: preload("res://supermarket simulator/assets/pupil1.png"),
	2: preload("res://supermarket simulator/assets/pupil2.png")
}

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bodySprite.texture = bodies[rng.randi_range(0,bodies.size()-1)]
	eyesSprite.texture = eyes[rng.randi_range(0,eyes.size()-1)]
	earsSprite.texture = ears[rng.randi_range(0,ears.size()-1)]
	pupilsSprite.texture = pupils[rng.randi_range(0,pupils.size()-1)]
	mouthSprite.texture = mouths[rng.randi_range(0,mouths.size()-1)]
