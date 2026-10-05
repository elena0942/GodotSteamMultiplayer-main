extends StaticBody2D
class_name InteractableEnvironment

@onready var hitbox: Area2D = $Hitbox
@onready var mud_use_timer: Timer = $Timers/MudUse

var interaction_count: int = 0
var max_interactions: int = 1 #starting
var player_in_range: CharacterBody2D = null
var can_interact: bool

func _ready() -> void:
	Global.playerInteracted.connect(_on_player_interacted)
	if !hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	if !hitbox.area_exited.is_connected(_on_hitbox_area_exited):
		hitbox.area_exited.connect(_on_hitbox_area_exited)
	mud_use_timer.start()

func _process(delta: float) -> void:
	if player_in_range == null:
		return
	var key = player_in_range.get_node_or_null("Key")
	if key == null:
		print("KEY NULL")
		return
	can_interact = mud_use_timer.is_stopped() and interaction_count < max_interactions
	key.visible = can_interact

func _on_player_interacted(object_name: String, player: CharacterBody2D) -> void:
	if !get_tree().get_nodes_in_group("PlayerPERSON").is_empty():
		max_interactions = get_tree().get_nodes_in_group("PlayerPERSON").size() #update number of max uses mud can have based on amount of players in the game
	if !is_multiplayer_authority():
		return
	var key = player.get_node_or_null("Key")
	if object_name == self.name:
		if !mud_use_timer.is_stopped():
			print("Can't interact now. Waiting...")
			key.hide()
		elif mud_use_timer.is_stopped():
			key.show()
			trigger_interaction(player)

func trigger_interaction(player: CharacterBody2D) -> void:
	if interaction_count >= max_interactions:
		disable_interaction()
	else:
		interaction_count += 1
		if player.has_method("set") or "is_muddy" in player:
			player.is_muddy = true
			var mud_wear_off: Timer = player.get_node("Timers/MudWearOff")
			if !mud_wear_off.timeout.is_connected(_on_mud_wear_off):
				mud_wear_off.timeout.connect(_on_mud_wear_off.bind(player))
			mud_wear_off.start()
		mud_use_timer.start()

func _on_mud_wear_off(player: CharacterBody2D):
	player.is_muddy = false

func disable_interaction() -> void:
	var key = player_in_range.get_node_or_null("Key")
	key.hide()
	hitbox.monitoring = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	if !area.is_in_group("PlayerHB"):
		return
	var player = area.get_parent()
	if player is CharacterBody2D and "is_muddy" in player:
		print("DB player: ", player)
		player_in_range = player
		var key = player_in_range.get_node_or_null("Key")
		if key:
			key.show()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if !area.is_in_group("PlayerHB"):
		return
	var player = area.get_parent()
	if player == player_in_range:
		var key = player_in_range.get_node_or_null("Key")
		if key:
			key.hide()
		player_in_range = null
