extends Node2D

var empty_spaces_dictionary = [
	{
		key = '0',
		value = PoolVector2Array([
			Vector2(0,3),
			Vector2(1,3),
			Vector2(0,4),
			Vector2(1,4),
			Vector2(0,5),
			Vector2(1,5),
			Vector2(0,6),
			Vector2(1,6),
			Vector2(6,3),
			Vector2(7,3),
			Vector2(6,4),
			Vector2(7,4),
			Vector2(6,5),
			Vector2(7,5),
			Vector2(6,6),
			Vector2(7,6)
			])
	},
	{
		key = '1',
		value = PoolVector2Array([
			Vector2(0,0),
			Vector2(7,0),
			Vector2(0,9),
			Vector2(7,9),
			Vector2(3,4),
			Vector2(4,4),
			Vector2(3,5),
			Vector2(4,5)
			])
	},
	{
		key = '2',
		value = PoolVector2Array([
			Vector2(0,9),
			Vector2(1,9),
			Vector2(0,8),
			Vector2(1,8),
			Vector2(6,9),
			Vector2(7,9),
			Vector2(6,8),
			Vector2(7,8),
			Vector2(1,0),
			Vector2(2,0),
			Vector2(3,0),
			Vector2(4,0),
			Vector2(5,0),
			Vector2(6,0),
			Vector2(3,1),
			Vector2(4,1)
			])
	}
]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Returns a matrix
func get_matrix(width,height):
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func get_random_empty_spaces():
	randomize()
	var rand = randi() % empty_spaces_dictionary.size()	
	return empty_spaces_dictionary[rand].value

func get_preloaded_pieces():
	var preloaded_pieces = [
	preload("res://scenes/piece/piece_blue.tscn"),
	preload("res://scenes/piece/piece_green.tscn"),
	preload("res://scenes/piece/piece_light_green.tscn"),
	preload("res://scenes/piece/piece_orange.tscn"),
	preload("res://scenes/piece/piece_yellow.tscn"),
	preload("res://scenes/piece/piece_pink.tscn")
	]
	return preloaded_pieces
