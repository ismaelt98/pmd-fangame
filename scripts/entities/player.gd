extends GridMover
class_name PlayerEntity

## Player-specific entity with input handling and team management

@export var team: Array = []


func _ready():
	super._ready()


func get_facing_enemy() -> PokemonEntity:
	var facing_tile = grid_position + facing
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(tile_size - 2, tile_size - 2)
	query.shape = shape
	query.transform = Transform2D(0, Vector2(facing_tile * tile_size))

	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is PokemonEntity and collider != self:
			return collider

	return null


func use_attack(move_id: String, target: PokemonEntity):
	if not target:
		return
	var move_data = GameData.get_move(move_id)
	if move_data.is_empty():
		return

	if not target.has_method("take_damage"):
		return

	var power = move_data.get("power", 40)
	var atk_stat = stats.attack if move_data.get("category", "physical") == "physical" else stats.sp_attack
	var def_stat = target.stats.defense if move_data.get("category", "physical") == "physical" else target.stats.sp_defense

	var damage = _calc_damage(atk_stat, power, def_stat, move_data.get("type", ""), target.stats.types)
	target.take_damage(damage)


func take_damage(amount: int):
	var actual = stats.take_damage(amount)
	EventBus.player_damaged.emit(actual, self)
	if stats.fainted:
		EventBus.game_over.emit()


func _calc_damage(atk: int, power: int, defense: int, move_type: String, defender_types: Array) -> int:
	var base = int(floor((((2.0 + level) / 250.0) * (float(atk) / max(defense, 1)) * power + 2) * _random_factor()))
	var stab = 1.5 if move_type in stats.types else 1.0
	var effectiveness = GameData.get_type_effectiveness(move_type, defender_types)
	return int(floor(base * stab * effectiveness))


func _random_factor() -> float:
	return randf_range(0.85, 1.0)


var level: int = 1
