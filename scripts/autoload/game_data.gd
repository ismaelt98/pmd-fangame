extends Node

## Global game state and data loader

var player_team: Array = []
var inventory: Array = []
var money: int = 0
var current_floor: int = 1
var current_dungeon_id: String = ""
var story_flags: Dictionary = {}
var play_time: float = 0.0

var all_pokemon: Dictionary = {}
var all_moves: Dictionary = {}
var all_abilities: Dictionary = {}
var all_items: Dictionary = {}
var all_dungeons: Dictionary = {}
var type_chart: Dictionary = {}


func _ready():
	_load_all_data()


func _load_all_data():
	all_pokemon = _load_json("res://data/pokemon.json")
	all_moves = _load_json("res://data/moves.json")
	all_abilities = _load_json("res://data/abilities.json")
	all_items = _load_json("res://data/items.json")
	all_dungeons = _load_json("res://data/dungeons.json")
	type_chart = _load_json("res://data/type_chart.json")


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open: %s" % path)
		return {}
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data


func get_move(move_id: String) -> Dictionary:
	return all_moves.get(move_id, {})


func get_pokemon(pokemon_id: String) -> Dictionary:
	return all_pokemon.get(pokemon_id, {})


func get_dungeon(dungeon_id: String) -> Dictionary:
	return all_dungeons.get(dungeon_id, {})


func get_type_effectiveness(attack_type: String, defender_types: Array) -> float:
	var multiplier: float = 1.0
	for def_type in defender_types:
		var row = type_chart.get(attack_type, {})
		multiplier *= row.get(def_type, 1.0)
	return multiplier


func reset_run():
	player_team.clear()
	inventory.clear()
	money = 0
	current_floor = 1
	current_dungeon_id = ""
	story_flags.clear()
	play_time = 0.0
