extends Node2D

const PLAYER_CONTROLLER = preload("uid://dp0anu84vqtlk")
const PLAYER_BEAR = preload("uid://swxktdgm3y02")
const TRAIL_COLORS: Array[Color] = [Color.DARK_RED, Color.DARK_OLIVE_GREEN, Color.DARK_CYAN, Color.GOLDENROD]

@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner
var players: Dictionary = {}


func _ready() -> void:
	spawner.spawn_function = _do_spawn #testing
	Networking.host_created.connect(on_host_created)
	print(players)


func _do_spawn(data: Dictionary) -> Node: #testing
	var scene: PackedScene = PLAYER_CONTROLLER if data["type"] == "player" else PLAYER_BEAR
	var node: CharacterBody2D = scene.instantiate()
	node.owner_peer_id = data["peer_id"]
	node.global_position = data["spawn_position"]
	node.net_position = data["spawn_position"]
	if data["type"] == "player":
		node.trail_color = data["color"]
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
	var color: Color = TRAIL_COLORS[players.size() % TRAIL_COLORS.size()]
	var new_player: CharacterBody2D = spawner.spawn({"type": "player", "peer_id": peer_id, "color": color, "spawn_position": $SpawnPoint.position,})
	initialize_player(peer_id, new_player)

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

##redundant
#func _on_multiplayer_spawner_spawned(node: Node) -> void:
	#if node is CharacterBody2D:
		#initialize_player(node.name.to_int(), node)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())

func _on_randomize_bear_pressed() -> void:
	if multiplayer.is_server():
		request_swap()
	else:
		request_swap.rpc_id(1) #1 means server
	print("Player: ", players.keys(), " Authority: ", get_multiplayer_authority())

func _on_make_host_bear_pressed() -> void:
	if multiplayer.is_server():
		swap_player_type(1)
	else:
		request_swap_specific.rpc_id(1) #1 means server
	print("Player: ", players.keys(), " Authority: ", get_multiplayer_authority())

func _on_make_client_bear_pressed() -> void:
	if multiplayer.is_server():
		var client_id := _get_client_peer_id()
		if client_id != 0:
			swap_player_type(client_id)
	else:
		request_swap_specific(-1)

@rpc("any_peer", "reliable")
func request_swap_specific(target_peer_id: int) -> void:
	if not multiplayer.is_server():
		print("Server, returning")
		return
	if target_peer_id == -1: 
		target_peer_id = _get_client_peer_id()
	if target_peer_id != 0 and players.has(target_peer_id):
		swap_player_type(target_peer_id)
	
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

	remove_child(old_player)
	old_player.free()
	
	var new_player: CharacterBody2D = spawner.spawn({"type": "playerbear", "peer_id": peer_id, "spawn_position": saved_position})
	players[peer_id] = new_player
	new_player.global_position = saved_position

func _get_client_peer_id() -> int:
	for peer_id in players.keys():
		if peer_id != 1:
			return peer_id
	return 0
