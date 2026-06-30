extends CharacterBody2D
class_name GridMover

## Grid-based movement for Mystery Dungeon
## Moves tile by tile, one step per input

@export var tile_size: int = 16
@export var move_speed: float = 120.0
@export var diagonal_movement: bool = true

var grid_position: Vector2i:
	set(value):
		grid_position = value
		target_pixel = Vector2(value * tile_size)
	get:
		return grid_position

var target_pixel: Vector2
var is_moving: bool = false
var facing: Vector2i = Vector2i.DOWN


func _ready():
	grid_position = Vector2i(floor(position.x / tile_size), floor(position.y / tile_size))
	target_pixel = position
	TurnManager.register_player(self)


func _physics_process(delta):
	if not is_moving and TurnManager.can_act():
		_handle_input()

	if is_moving:
		move_toward_target(delta)


func _handle_input():
	var direction := Vector2i.ZERO

	if Input.is_action_just_pressed("move_up"):
		direction = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):
		direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		direction = Vector2i.RIGHT
	elif diagonal_movement and Input.is_action_just_pressed("move_diag_up_left"):
		direction = Vector2i(-1, -1)
	elif diagonal_movement and Input.is_action_just_pressed("move_diag_up_right"):
		direction = Vector2i(1, -1)
	elif diagonal_movement and Input.is_action_just_pressed("move_diag_down_left"):
		direction = Vector2i(-1, 1)
	elif diagonal_movement and Input.is_action_just_pressed("move_diag_down_right"):
		direction = Vector2i(1, 1)
	elif Input.is_action_just_pressed("wait_turn"):
		_wait_turn()
		return
	elif Input.is_action_just_pressed("open_menu"):
		_open_menu()
		return

	if direction != Vector2i.ZERO:
		facing = direction
		var new_grid_pos = grid_position + direction
		if _is_tile_walkable(new_grid_pos):
			var action = {
				"type": "move",
				"position": new_grid_pos
			}
			TurnManager.request_player_action(action)


func move_to(new_grid_pos: Vector2i):
	grid_position = new_grid_pos
	is_moving = true
	EventBus.player_moved.emit(grid_position, facing)


func move_toward_target(delta: float):
	position = position.move_toward(target_pixel, move_speed * delta)
	if position.distance_to(target_pixel) < 1.0:
		position = target_pixel
		is_moving = false


func _is_tile_walkable(tile_pos: Vector2i) -> bool:
	var floor_managers = get_tree().get_nodes_in_group("floor_managers")
	if floor_managers.size() > 0:
		return floor_managers[0].is_tile_walkable(tile_pos)
	return true


func _wait_turn():
	var action = {"type": "wait"}
	TurnManager.request_player_action(action)


func _open_menu():
	EventBus.emit_signal("open_menu")


func get_facing_tile() -> Vector2i:
	return grid_position + facing
