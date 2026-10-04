extends StaticBody2D
class_name InteractableEnvironment

@onready var hitbox: Area2D = $Hitbox
@onready var mud_use_timer: Timer = $Timers/MudUse

var interaction_count: int = 0
var max_interactions: int = 1 #starting

func _ready() -> void:
	Global.playerInteracted.connect(_on_player_interacted)
	mud_use_timer.start()

func _on_player_interacted(object_name: String, player: CharacterBody2D) -> void:
	if !get_tree().get_nodes_in_group("PlayerPERSON").is_empty():
		max_interactions = get_tree().get_nodes_in_group("PlayerPERSON").size() #update number of max uses mud can have based on amount of players in the game
	if !is_multiplayer_authority():
		return
	if object_name == self.name:
		if !mud_use_timer.is_stopped():
			print("Can't interact now. Waiting...")
		elif mud_use_timer.is_stopped():
			trigger_interaction(player)

func trigger_interaction(player: CharacterBody2D) -> void:
	if interaction_count >= max_interactions:
		print("TI: Max interaction count. Stopping")
		disable_interaction()
	else:
		interaction_count += 1
		if player.has_method("set") or "is_muddy" in player:
			player.is_muddy = true
			var mud_wear_off: Timer = player.get_node("Timers/MudWearOff")
			if !mud_wear_off.timeout.is_connected(_on_mud_wear_off):
				mud_wear_off.timeout.connect(_on_mud_wear_off.bind(player))
			mud_wear_off.start()
			print("Player muddy + timer start: ", player.is_muddy)
		print("Player interacted with: ", self.name, " Interaction count: ", interaction_count)
		mud_use_timer.start()

func _on_mud_wear_off(player: CharacterBody2D):
	player.is_muddy = false
	print("not muddy no mo")

func disable_interaction() -> void:
	hitbox.monitoring = false
