extends Resource
class_name PokemonStats

## Pokemon stats resource used by all Pokemon entities

@export var pokemon_id: String = ""
@export var nickname: String = ""
@export var level: int = 1

@export var max_hp: int = 10
@export var hp: int = 10:
	set(value):
		hp = clampi(value, 0, max_hp)
		if hp <= 0:
			fainted = true

@export var attack: int = 5
@export var defense: int = 5
@export var sp_attack: int = 5
@export var sp_defense: int = 5
@export var speed: int = 5

@export var types: Array = []
@export var ability: String = ""
@export var moves: Array = []
@export var fainted: bool = false

@export var experience: int = 0
@export var exp_to_next: int = 100

@export var belly: int = 100
@export var max_belly: int = 100


func init_from_data(data: Dictionary, lv: int = 1):
	pokemon_id = data.get("id", "")
	level = lv
	var base = data.get("base_stats", {})
	max_hp = _calc_stat(base.get("hp", 10), lv) + lv + 10
	hp = max_hp
	attack = _calc_stat(base.get("atk", 5), lv)
	defense = _calc_stat(base.get("def", 5), lv)
	sp_attack = _calc_stat(base.get("spa", 5), lv)
	sp_defense = _calc_stat(base.get("spd", 5), lv)
	speed = _calc_stat(base.get("spe", 5), lv)
	types = data.get("types", [])
	ability = data.get("ability", "")

	var levelup_moves = data.get("moves_levelup", {})
	for move_level in levelup_moves:
		if int(move_level) <= lv:
			for move_id in levelup_moves[move_level]:
				if moves.size() < 4 and move_id not in moves:
					moves.append(move_id)

	exp_to_next = _calc_exp_to_next(lv)


func _calc_stat(base: int, lv: int) -> int:
	return int(floor((base * 2.0 * lv) / 100.0)) + 5


func _calc_exp_to_next(lv: int) -> int:
	return int(pow(float(lv), 3))


func take_damage(amount: int):
	var actual = clampi(amount, 1, hp)
	hp -= actual
	return actual


func heal(amount: int):
	hp = mini(hp + amount, max_hp)


func reduce_belly(amount: int = 1):
	belly = maxi(belly - amount, 0)
	if belly <= 0:
		take_damage(1)
	EventBus.hunger_changed.emit(belly, max_belly)


func restore_belly(amount: int):
	belly = mini(belly + amount, max_belly)
	EventBus.hunger_changed.emit(belly, max_belly)
