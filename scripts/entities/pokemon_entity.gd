extends CharacterBody2D
class_name PokemonEntity

## Base class for all Pokemon entities (player, allies, enemies)

@export var stats: PokemonStats
@export var tile_size: int = 16

var grid_position: Vector2i:
	set(value):
		grid_position = value
		target_pixel = Vector2(value * tile_size)
	get:
		return grid_position

var target_pixel: Vector2
var is_moving: bool = false


func _ready():
	grid_position = Vector2i(floor(position.x / tile_size), floor(position.y / tile_size))
	target_pixel = position


func _physics_process(delta):
	if is_moving:
		position = position.move_toward(target_pixel, 120.0 * delta)
		if position.distance_to(target_pixel) < 1.0:
			position = target_pixel
			is_moving = false


func set_grid_position(new_pos: Vector2i):
	grid_position = new_pos
	is_moving = true


func blocks_movement() -> bool:
	return true


func take_turn():
	pass
