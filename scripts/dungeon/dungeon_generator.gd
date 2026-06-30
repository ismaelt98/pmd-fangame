extends Node
class_name DungeonGenerator

## Procedural dungeon floor generation using BSP (Binary Space Partition)

signal floor_generated(floor_data: Dictionary)

@export var floor_width: int = 30
@export var floor_height: int = 20
@export var min_room_size: int = 4
@export var max_room_size: int = 9
@export var max_rooms: int = 12
@export var tile_size: int = 16

enum Tile { FLOOR, WALL, WATER, LAVA, STAIRS, TRAP, HALLWAY }

var grid: Array = []
var rooms: Array = []


func generate(seed_val: int = -1) -> Dictionary:
	if seed_val != -1:
		seed(seed_val)
	else:
		randomize()

	_init_grid()
	rooms.clear()

	var root = Rect2i(1, 1, floor_width - 2, floor_height - 2)
	_split_bsp(root, 0)

	_carve_rooms()
	_connect_rooms()

	_place_stairs()

	return {
		"width": floor_width,
		"height": floor_height,
		"grid": grid,
		"rooms": rooms,
		"stairs_position": stairs_pos,
		"tile_size": tile_size
	}


func _init_grid():
	grid.clear()
	for y in range(floor_height):
		var row: Array = []
		for x in range(floor_width):
			if x == 0 or y == 0 or x == floor_width - 1 or y == floor_height - 1:
				row.append(Tile.WALL)
			else:
				row.append(Tile.WALL)
		grid.append(row)


func _split_bsp(area: Rect2i, depth: int):
	if rooms.size() >= max_rooms:
		return
	if depth > 5:
		return

	var can_split_h = area.size.x >= min_room_size * 2 + 2
	var can_split_v = area.size.y >= min_room_size * 2 + 2

	if not can_split_h and not can_split_v:
		var room = _create_room(area)
		if room.size.x >= min_room_size and room.size.y >= min_room_size:
			rooms.append(room)
		return

	var split_h: bool
	if can_split_h and can_split_v:
		split_h = randi() % 2 == 0
	elif can_split_h:
		split_h = true
	else:
		split_h = false

	if split_h:
		var split_x = area.position.x + randi_range(area.size.x / 3, 2 * area.size.x / 3)
		var left = Rect2i(area.position.x, area.position.y, split_x - area.position.x, area.size.y)
		var right = Rect2i(split_x, area.position.y, area.end.x - split_x, area.size.y)
		_split_bsp(left, depth + 1)
		_split_bsp(right, depth + 1)
	else:
		var split_y = area.position.y + randi_range(area.size.y / 3, 2 * area.size.y / 3)
		var top = Rect2i(area.position.x, area.position.y, area.size.x, split_y - area.position.y)
		var bottom = Rect2i(area.position.x, split_y, area.size.x, area.end.y - split_y)
		_split_bsp(top, depth + 1)
		_split_bsp(bottom, depth + 1)


func _create_room(area: Rect2i) -> Rect2i:
	var w = randi_range(min_room_size, min(max_room_size, area.size.x - 2))
	var h = randi_range(min_room_size, min(max_room_size, area.size.y - 2))
	var x = area.position.x + randi_range(1, area.size.x - w - 1)
	var y = area.position.y + randi_range(1, area.size.y - h - 1)
	return Rect2i(x, y, w, h)


func _carve_rooms():
	for room in rooms:
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				grid[y][x] = Tile.FLOOR


func _connect_rooms():
	for i in range(rooms.size() - 1):
		var a = rooms[i].get_center()
		var b = rooms[i + 1].get_center()
		_carve_hallway(a.x, a.y, b.x, b.y)


func _carve_hallway(x1: int, y1: int, x2: int, y2: int):
	var x = x1
	var y = y1

	while x != x2:
		if x < x2:
			x += 1
		else:
			x -= 1
		if grid[y][x] == Tile.WALL:
			grid[y][x] = Tile.HALLWAY

	while y != y2:
		if y < y2:
			y += 1
		else:
			y -= 1
		if grid[y][x] == Tile.WALL:
			grid[y][x] = Tile.HALLWAY


var stairs_pos: Vector2i

func _place_stairs():
	var last_room = rooms[rooms.size() - 1]
	var pos = last_room.get_center()
	grid[pos.y][pos.x] = Tile.STAIRS
	stairs_pos = pos


func get_tile(pos: Vector2i) -> int:
	if pos.x < 0 or pos.y < 0 or pos.x >= floor_width or pos.y >= floor_height:
		return Tile.WALL
	return grid[pos.y][pos.x]


func is_walkable(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	return tile == Tile.FLOOR or tile == Tile.HALLWAY or tile == Tile.STAIRS


func get_random_floor_tile() -> Vector2i:
	var candidates: Array = []
	for y in range(floor_height):
		for x in range(floor_width):
			if grid[y][x] == Tile.FLOOR:
				candidates.append(Vector2i(x, y))
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return Vector2i.ZERO
