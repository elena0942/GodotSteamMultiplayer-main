extends ProgressBar

@export var player: CharacterBody2D
@onready var health = player.health
@onready var max_health = player.max_health

func _ready():
	player.healthChanged.connect(update)
	update(health, max_health)

func update(health, max_health):
	value = health
