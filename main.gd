extends Node2D

const PLAYER_CONTROLLER = preload("uid://disid262nfj6n")

var players: Array[CharacterBody2D]

func _ready() -> void:
	Networking.host_created.connect(on_host_created)


func on_host_created() -> void:
	# Spawn the server player
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)


# The server spawns the player that just connected
func spawn_player(peer_id: int) -> void:
	var new_player := PLAYER_CONTROLLER.instantiate() as CharacterBody2D
	new_player.name = str(peer_id)
	add_child(new_player)
	initialize_player(new_player)


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
