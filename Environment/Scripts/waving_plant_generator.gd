@tool
extends TileMapLayer

@onready var tile_map_layer: TileMapLayer = $"."

func _ready():
	set_instance_shader_parameter("RandomStrength", randf_range(-5.0, 5.0))

#func check_tile(coords: Vector2i) -> void:
	#var tile_data: TileData = tile_map_layer.get_cell_tile_data(coords)
	#
	#if tile_data:
		#var is_waving = tile_data.get_custom_data("waving")
		#if is_waving:
			#set_instance_shader_parameter("RandomStrength", randf_range(-5.0, 5.0))
			#print("Tile exists")
		#else:
			#print("Tile has no custom material data")
	#else:
		#print("Tile does not exist")
