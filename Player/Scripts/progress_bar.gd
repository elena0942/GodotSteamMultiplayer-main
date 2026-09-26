extends ProgressBar

@export var player: CharacterBody2D

func _ready():
	player.healthChanged.connect(update)
	update()

func update():
	max_value = player.max_health
	value = player.health
