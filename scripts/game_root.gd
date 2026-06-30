extends Node2D

## Root scene script - kicks off dungeon generation on start

@onready var floor_manager: FloorManager = $FloorManager


func _ready():
	floor_manager.generate_floor()
