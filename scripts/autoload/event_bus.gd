extends Node

signal player_moved(new_position: Vector2i, direction: Vector2i)
signal turn_advanced(turn_number: int)
signal enemy_turn_started
signal enemy_turn_ended
signal floor_generated(floor_data: Dictionary)
signal stairs_reached(floor_number: int)
signal player_damaged(amount: int, source: Node)
signal enemy_defeated(enemy: Node)
signal item_picked_up(item_data: Dictionary)
signal hunger_changed(new_value: int, max_value: int)
signal game_over
