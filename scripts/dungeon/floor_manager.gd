extends Node2D
class_name FloorManager

## Manages the visual representation of a dungeon floor
## Uses _draw() for simple colored-tile rendering

@export var tile_size: int = 16

var floor_data: Dictionary
var grid_rect: ColorRect
var grid_drawer: GridDrawer

@onready var generator: DungeonGenerator = $DungeonGenerator


func _ready():
	add_to_group("floor_managers")
	generator.floor_generated.connect(_on_floor_generated)


func generate_floor():
	floor_data = generator.generate()
	EventBus.floor_generated.emit(floor_data)


func _on_floor_generated(data: Dictionary):
	floor_data = data
	_render_tiles()
	_spawn_player()


func _render_tiles():
	if grid_drawer:
		grid_drawer.queue_free()

	grid_drawer = GridDrawer.new()
	grid_drawer.name = "GridDrawer"
	grid_drawer.floor_data = floor_data
	grid_drawer.tile_size = tile_size
	add_child(grid_drawer)


func _spawn_player():
	var start_pos = get_start_position()
	var player_scene = load("res://scripts/entities/player.tscn") if ResourceLoader.exists("res://scripts/entities/player.tscn") else null
	if not player_scene:
		player_scene = _create_player_scene()

	var player = player_scene.instantiate()
	player.position = start_pos
	player.tile_size = tile_size

	if not player.stats:
		player.stats = PokemonStats.new()
		player.stats.init_from_data(GameData.get_pokemon("pikachu"), 5)

	add_child(player)


func _create_player_scene() -> PackedScene:
	var scene = PackedScene.new()
	var player = PlayerEntity.new()
	player.name = "Player"
	player.collision_layer = 1
	player.collision_mask = 1

	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = _create_player_texture()
	player.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "Collision"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(tile_size - 2, tile_size - 2)
	collision.shape = shape
	player.add_child(collision)

	scene.pack(player)
	return scene


func _create_player_texture() -> Texture2D:
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.85, 0.0, 1.0))
	return ImageTexture.create_from_image(img)


func is_tile_walkable(tile_pos: Vector2i) -> bool:
	return generator.is_walkable(tile_pos)


func get_start_position() -> Vector2:
	if floor_data.has("rooms") and floor_data["rooms"].size() > 0:
		var start_room: Rect2i = floor_data["rooms"][0]
		var center = start_room.get_center()
		return Vector2(center.x * tile_size + tile_size / 2, center.y * tile_size + tile_size / 2)
	return Vector2(tile_size * 5, tile_size * 5)


## GridDrawer - renders the dungeon grid using _draw()
class GridDrawer extends Node2D:
	var floor_data: Dictionary
	var tile_size: int = 16

	var _colors: Dictionary = {
		0: Color(0.4, 0.35, 0.3),
		6: Color(0.35, 0.3, 0.25),
		4: Color(0.9, 0.7, 0.1)
	}

	func _ready():
		queue_redraw()

	func _draw():
		if floor_data.is_empty():
			return
		var grid = floor_data["grid"]
		for y in range(grid.size()):
			for x in range(grid[y].size()):
				var tile = grid[y][x]
				match tile:
					0, 4, 6:
						draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), _colors[tile])
					1:
						draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), Color(0.2, 0.18, 0.15), false)
					2:
						draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), Color(0.15, 0.25, 0.55))
					_:
						pass
