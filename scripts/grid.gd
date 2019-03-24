extends Node2D

# State Machine. To control the function calls timing (no refill before collapse for example)
enum {wait, move, wait_autocheck}
var state
var pieces_destroyed = 0
var combo = 0

# Grid variables
export (int) var width = 8
export (int) var height = 10
export (int) var x_start = 64
export (int) var y_start = 800
export (int) var offset =  64
export (int) var y_offset = -2

# Obstacle Stuff FIXME
var empty_spaces #= PoolVector2Array([Vector2(0,0),Vector2(7,0),Vector2(0,9),Vector2(7,9),Vector2(3,4),Vector2(4,4),Vector2(3,5),Vector2(4,5)])
var ice_spaces = PoolVector2Array([Vector2(3,0),Vector2(4,0),Vector2(3,9),Vector2(4,9)])
var lock_spaces = PoolVector2Array([Vector2(3,2),Vector2(4,2),Vector2(3,7),Vector2(4,7)])

# Obstacle Signals
signal damage_ice
signal make_ice
signal make_lock
signal damage_lock

# The piece array
var possible_pieces = [
	preload("res://scenes/piece/piece_blue.tscn"),
	preload("res://scenes/piece/piece_green.tscn"),
	preload("res://scenes/piece/piece_light_green.tscn"),
	preload("res://scenes/piece/piece_orange.tscn"),
	preload("res://scenes/piece/piece_yellow.tscn"),
	preload("res://scenes/piece/piece_pink.tscn")
]
# Current pieces in the screen
var all_pieces

# Swap Back Variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Touch Variables
var first_touch= Vector2(0,0)
var final_touch= Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = move
	all_pieces = utils.get_matrix(width,height)
	get_parent().get_node("main_theme_audio").play()
	get_parent().get_node("ready_timer").start()
	empty_spaces = utils.get_random_empty_spaces()

# TODO
func game_loop():
	if state == move:
		#state = wait
		touch_imput() #swap_pieces
		sound_acording_combo()
		reset_combo()
		#swap_pieces()
		#matchs = check_matchs()
		#if matchs:
		#	state = wait_autocheck
		#	print(state)
		#destroy_and_refill()
		#ia_auto_checking()
		#else:			
		#	#swap_back()
		#	state = move

func reset_combo():
	combo = 0

func sound_acording_combo():
	print("Combo de "+String(combo)+" total de piezas destruidas "+String(pieces_destroyed))
	pass


# TODO: Destroy matches pieces, collapse and refill columns
func destroy_and_refill():
	destroy_matches()
	collapse_columns()
	refill_columns()

# TODO: Find matches, destroy them, collapse and refill columns
func ia_auto_checking():
	while state == wait_autocheck:
		var matchs = false #check_matchs()
		if matchs:
			destroy_and_refill()
		else:
			state = move

#####################################################################################
#####################################################################################
#####################################################################################
#####################################################################################

# Return true if the place is into spaces array
func restricted_move(place,spaces):
	if place in spaces:
		return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	#if state == move:
		#touch_imput()
	game_loop()

# Set all pieces into the grid
func spawn_piece():
	randomize()
	for i in width:
		for j in height:
			set_random_piece_on_grid(i,j)

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func spawn_lock():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])

# Returns true is find at less 3 pieces with same color
func match_at(column, row, color):
	if column > 1:
		if all_pieces[column - 1][row] != null && all_pieces[column - 2][row] != null:
			if all_pieces[column - 1][row].color == color && all_pieces[column - 2][row].color == color:
				return true
	if row > 1:
		if all_pieces[column][row-1] != null && all_pieces[column][row-2] != null:
			if all_pieces[column][row-1].color == color && all_pieces[column][row-2].color == color:
				return true
	return false

# Returns the position in pixel according column and row
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x,new_y)

# Check if grid_position is in grid
func is_in_grid(grid_position):
	if grid_position.x>=0 &&grid_position.x<width:
		if grid_position.y>= 0&& grid_position.y<height:
			return true
		return false

# Returns the position in a column and row according to a pixel
func pixel_to_grid(pixel):
	var new_x = round((pixel.x -x_start)/offset)
	var new_y = round((pixel.y -y_start)/-offset)
	return Vector2(new_x,new_y)

# Check if some input is executed by the player
func touch_imput():	
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			first_touch = pixel_to_grid(get_global_mouse_position())
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position())
			touch_difference(first_touch, final_touch)
	return controlling

# Swap a piece in column and row (i,j) to the "direction"
func swap_pieces(column, row,direction):
	var first_piece =all_pieces[column][row]
	var other_piece =all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece != null:
		if not restricted_move(Vector2(column,row), lock_spaces) and not restricted_move(Vector2(column,row) + direction, lock_spaces):
			store_info(first_piece, other_piece, Vector2(column,row), direction)
			state = wait
			all_pieces[column][row] = other_piece
			all_pieces[column+direction.x][row+direction.y]= first_piece;
			first_piece.move(grid_to_pixel(column+direction.x,row+direction.y))
			other_piece.move(grid_to_pixel(column,row))
			if !move_checked:
				find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	# Move the prevously swapped pieces back to the previous place
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false

# Swap the pieces considering the max distance (1) to move
func touch_difference(grid_1,grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x)>abs(difference.y):
		if difference.x>0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(1,0))
		elif difference.x<0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(-1,0))
	elif abs(difference.y)>abs(difference.x):
		if difference.y>0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,1))
		elif difference.y<0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,-1))

# Find the pieces matches
func find_matches():	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1:
					if not all_pieces[i-1][j]==null && not all_pieces[i+1][j]==null:
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							var pieces = [all_pieces[i-1][j], all_pieces[i][j], all_pieces[i+1][j]]
							var visibility_pieces_changed = change_pieces_visibility(pieces, true)
							combo = visibility_pieces_changed
							

				if j > 0 && j < height - 1:
					if not all_pieces[i][j-1]==null && not all_pieces[i][j+1]==null:
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							var pieces = [all_pieces[i][j-1], all_pieces[i][j], all_pieces[i][j+1]]
							var visibility_pieces_changed = change_pieces_visibility(pieces, true)
							combo += visibility_pieces_changed
	pieces_destroyed += combo	
	get_parent().get_node('destroy_timer').start()

# This method is main: Change the visibility of pieces array according matched value]
func change_pieces_visibility(pieces, matched):
	var visibility_pieces_changed = 0
	for piece in pieces:
		if not piece.matched:
			piece.matched = matched
			visibility_pieces_changed += 1
		piece.dim()
	return visibility_pieces_changed
	#print("Combo de "+String(pieces.size())+" total de piezas destruidas "+String(pieces_destroyed))

# Destroy the pieces matched
func destroy_matches():
	var was_matches = false
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				damage_special(i,j)
				was_matches = true
				piece.queue_free()
				all_pieces[i][j] = null
	move_checked = true
	if was_matches:
		get_parent().get_node("destroy_audio").play()
		get_parent().get_node('collapse_timer').start()
	else:
		swap_back()

func damage_special(column,row):
	emit_signal("damage_ice", Vector2(column,row))
	emit_signal("damage_lock", Vector2(column,row))

# Collapse the pieces into a column
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_move(Vector2(i,j), empty_spaces):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node('refill_timer').start()

# Refill with pieces a column
func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				set_random_piece_on_grid(i,j)
	recheck_matchs()

# FIXME[This method is mine. Set a random piece into the grid]
func set_random_piece_on_grid(i,j):
	if not restricted_move(Vector2(i,j), empty_spaces):
		# choose a random number and store it
		var rand = randi() % possible_pieces.size()
		# Instance that piece from the array
		var piece = possible_pieces[rand].instance()
		var loops = 0
		# Check will be different colors in closer pieces
		while (match_at(i,j,piece.color) && loops < 100):
			rand = randi() % possible_pieces.size()
			loops += 1
			piece = possible_pieces[rand].instance()
		add_child(piece)
		# Simulates the piece fallen. Sliding piece
		piece.position = grid_to_pixel(i,j - y_offset)
		piece.move(grid_to_pixel(i,j))
		all_pieces[i][j] = piece

# Check the matches after refill
func recheck_matchs():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i,j,all_pieces[i][j].color):
				find_matches()				
				get_parent().get_node("combo_audio").play()
				get_parent().get_node("destroy_timer").start()
				return
	state = move
	move_checked = false

##################################################################################################################################
##################################################################################################################################
##################################################################################################################################
# SIGNAL: Destroy the pieces mached after a timing expecified. It is called when start function on timer node is executed
func _on_destroy_timer_timeout():
	destroy_matches()	

# SIGNAL: Collapse the pieces
func _on_collapse_timer_timeout():
	collapse_columns()

# SIGNAL: Refill the grid with pieces
func _on_refill_timer_timeout():
	refill_columns()

# SIGNAL: Unlock the locked piece in place
func _on_lock_holder_remove_lock(place):
	for i in range (lock_spaces.size() -1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)

# SIGNAL: Spawn the pieces
func _on_ready_timer_timeout():
	spawn_piece()
	spawn_ice()
	spawn_lock()
