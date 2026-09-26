extends Node2D

const PLAYER_CONTROLLER = preload("uid://dp0anu84vqtlk")
const PLAYER_BEAR = preload("uid://swxktdgm3y02")

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
var players: Dictionary = {}

func _ready() -> void:
	spawner.spawn_function = _do_spawn #testing
	Networking.host_created.connect(on_host_created)
	print(players)

func _do_spawn(data: Dictionary) -> Node: #testing
	var scene: PackedScene = PLAYER_CONTROLLER if data["type"] == "player" else PLAYER_BEAR
	var node: CharacterBody2D = scene.instantiate()
	node.owner_peer_id = data["peer_id"]
	node.name = data["type"] + "_" + str(data["peer_id"])
	return node

func on_host_created() -> void:
	# Spawn the server player
	_on_player_connected(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

# The server spawns the player that just connected
func _on_player_connected(peer_id: int):
	print("Player connected: ", peer_id)
	#testing:
	var new_player: CharacterBody2D = spawner.spawn({"type": "player", "peer_id": peer_id})
	initialize_player(peer_id, new_player)
##old, mostly working
	#var new_player = PLAYER_CONTROLLER.instantiate()
	#new_player.owner_peer_id = peer_id
	#new_player.name = "player_" + str(peer_id)
	#
	#add_child(new_player)
	#initialize_player(peer_id, new_player)
	#
	#print(players)

func _on_player_disconnected(peer_id: int):
	print("Player disconnected: ", peer_id)
	var player_node = $".".get_node_or_null(str(peer_id))
	
	if player_node:
		player_node.queue_free()
	players.erase(peer_id)

func initialize_player(peer_id: int, player: CharacterBody2D) -> void:
	player.global_position = $SpawnPoint.position
	for other in players.values():
		player.add_collision_exception_with(other)
	players[peer_id] = player


func _on_host_pressed() -> void:
	Networking.host_lobby()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody2D:
		initialize_player(node.name.to_int(), node)

func _on_randomize_bear_pressed() -> void:
	if multiplayer.is_server():
		request_swap()
	else:
		request_swap.rpc_id(1) #1 means server
	print("Player: ", players.keys(), " Authority: ", get_multiplayer_authority())

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())
		

@rpc("any_peer", "reliable")
func request_swap() -> void:
	if not multiplayer.is_server():
		print("Server, returning")
		return
	var peer_ids : Array = players.keys()
	var chosen_id : int = peer_ids[randi() % players.size()]
	print("Chosen ID: ", chosen_id)
	
	swap_player_type(chosen_id)

func swap_player_type(peer_id: int) -> void:
	var old_player: Node = players[peer_id]
	var saved_position: Vector2 = old_player.global_position #possibly unnecessary on scene swap
## testing:
	remove_child(old_player)
	old_player.free()
	
	var new_player: CharacterBody2D = spawner.spawn({"type": "playerbear", "peer_id": peer_id})
	players[peer_id] = new_player
	new_player.global_position = saved_position
## old, mostly working
	#if old_player.scene_file_path == "res://Player/Scenes/PlayerBear.tscn":
		#print("Returning, player is already a bear")
		#return
	#old_player.name = "retiring_" + str(peer_id) #free the name slot for new player to replace
	#old_player.queue_free()
	#await get_tree().process_frame
	#
	#var new_player: CharacterBody2D = PLAYER_BEAR.instantiate()
	#new_player.owner_peer_id = peer_id
	#new_player.name = "bear_" + str(peer_id) + "_" + str(Time.get_ticks_msec())
	#players[peer_id] = new_player
	#add_child(new_player)
	#new_player.position = saved_position
