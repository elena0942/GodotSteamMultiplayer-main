extends Node2D

const PLAYER_CONTROLLER = preload("uid://dp0anu84vqtlk")

var players: Array[CharacterBody2D]

func _ready() -> void:
	Networking.host_created.connect(on_host_created)

func on_host_created() -> void:
	# Spawn the server player
	_on_player_connected(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


# The server spawns the player that just connected
func _on_player_connected(peer_id: int):
	var new_player = PLAYER_CONTROLLER.instantiate()
	new_player.name = str(peer_id)
	add_child(new_player)
	initialize_player(new_player)

func _on_player_disconnected(peer_id: int):
	print("Player disconnected: ", peer_id)
	var player_node = $".".get_node_or_null(str(peer_id))
	
	if player_node:
		player_node.queue_free()

func initialize_player(player: CharacterBody2D) -> void:
	player.position = $SpawnPoint.position
	for other in players:
		player.add_collision_exception_with(other)
	players.append(player)


func _on_host_pressed() -> void:
	Networking.host_lobby()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody2D:
		initialize_player(node)
