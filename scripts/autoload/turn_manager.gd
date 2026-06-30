extends Node

## Turn-based system for Mystery Dungeon style gameplay
## One input = one turn. Player moves, then enemies move.

enum TurnState { WAITING_INPUT, PLAYER_ACTING, ENEMY_TURN, PROCESSING }

var turn_count: int = 0
var state: TurnState = TurnState.WAITING_INPUT
var player_ref: Node = null
var enemy_list: Array = []
var action_queue: Array = []


func _ready():
	EventBus.enemy_defeated.connect(_on_enemy_defeated)


func register_player(player_node: Node):
	player_ref = player_node


func register_enemy(enemy_node: Node):
	if enemy_node not in enemy_list:
		enemy_list.append(enemy_node)


func unregister_enemy(enemy_node: Node):
	enemy_list.erase(enemy_node)


func request_player_action(action_data: Dictionary):
	if state != TurnState.WAITING_INPUT:
		return

	state = TurnState.PLAYER_ACTING
	action_queue.push_front(action_data)
	_process_actions()


func _process_actions():
	while action_queue.size() > 0:
		var action = action_queue.pop_back()
		match action.get("type", ""):
			"move":
				if player_ref and player_ref.has_method("move_to"):
					player_ref.move_to(action["position"])

			"attack":
				if player_ref and player_ref.has_method("use_attack"):
					player_ref.use_attack(action["move_id"], action["target"])

			"interact":
				if player_ref and player_ref.has_method("interact"):
					player_ref.interact()

			"use_item":
				if player_ref and player_ref.has_method("use_item"):
					player_ref.use_item(action["item_id"])

		await get_tree().process_frame

	state = TurnState.ENEMY_TURN
	await _execute_enemy_turn()

	turn_count += 1
	EventBus.turn_advanced.emit(turn_count)
	state = TurnState.WAITING_INPUT


func _execute_enemy_turn():
	EventBus.enemy_turn_started.emit()

	for enemy in enemy_list:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_turn"):
			enemy.take_turn()
			await get_tree().process_frame

	EventBus.enemy_turn_ended.emit()


func _on_enemy_defeated(enemy: Node):
	unregister_enemy(enemy)


func can_act() -> bool:
	return state == TurnState.WAITING_INPUT
