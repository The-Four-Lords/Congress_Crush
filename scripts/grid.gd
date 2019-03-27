extends Node2D

# State Machine. To control the function calls timing (no refill before collapse for example)
enum {waiting_move, moving, autochecking}
var state = waiting_move
var pieces_destroyed = 0
var pieces_in_combo = 0
var combos_in_move = 0
var combos_done = 0

# Grid variables
var width = 8
var height = 10
var y_offset = -2
var x_start = 64
var offset =  64
var y_start = 800

# Current pieces in the screen
var all_pieces = utils.get_matrix(width,height)

# Obstacle Stuff
var empty_spaces = utils.get_random_empty_spaces()

# The piece array
var possible_pieces = utils.get_preloaded_pieces()

# Touch Variables
var first_touch= Vector2(0,0)
var final_touch= Vector2(0,0)

# Swap Back Variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

##################################################################################################################################
##################################################    FUNCTIONS    ###############################################################
##################################################################################################################################
# Called when the node enters the scene tree for the first time.
func _ready():
	load_board()

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	game_loop()

# Basic game loop
func game_loop():
	if state == waiting_move:
		var touch_input = get_touch_input()
		if touch_input:
			state = moving			
			move_pieces(touch_input[0],touch_input[1])
			var matchs = find_matches()
			if matchs:				
				destroy_and_refill(matchs)
				#ia_auto_checking()
			else:
				print("swap_back()")
				swap_back()


func swap_back():
	# Move the prevously swapped pieces back to the previous place
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = waiting_move
	move_checked = false

func load_board():
	get_parent().get_node("ready_timer").start()# spawn_piece()

# Set all pieces into the grid
func spawn_piece():
	randomize()
	for i in width:
		for j in height:
			set_random_piece_on_grid(i,j)

# Set a random piece into the grid
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

# Return true if the place is into spaces array
func restricted_move(place,spaces):
	if place in spaces:
		return true
	return false

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

# Return the positions if some input is executed by the player
func get_touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			first_touch = pixel_to_grid(get_global_mouse_position())			
			#controlling = true
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			#controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position())
			#touch_difference(first_touch, final_touch)
			return PoolVector2Array([first_touch,final_touch])

	return false

# Return true is touch_input is not null
func exist_touch_input(touch_input):
	#print('exist_touch_input touch_input.size:'+String(touch_input.size()))
	return touch_input.size() == 2

# Swap the pieces considering the max distance (1) to move
func move_pieces(first_touch,final_touch):		
	var difference = final_touch - first_touch	
	if abs(difference.x)>abs(difference.y):
		if difference.x>0:
			swap_pieces(first_touch.x,first_touch.y,Vector2(1,0))
		elif difference.x<0:
			swap_pieces(first_touch.x,first_touch.y,Vector2(-1,0))
	elif abs(difference.y)>abs(difference.x):
		if difference.y>0:
			swap_pieces(first_touch.x,first_touch.y,Vector2(0,1))
		elif difference.y<0:
			swap_pieces(first_touch.x,first_touch.y,Vector2(0,-1))

# Swap a piece in column and row (i,j) to the "direction"
func swap_pieces(column, row,direction):
	var first_piece =all_pieces[column][row]
	var other_piece =all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece != null:
		store_info(first_piece, other_piece, Vector2(column,row), direction)
		all_pieces[column][row] = other_piece
		all_pieces[column+direction.x][row+direction.y]= first_piece;
		first_piece.move(grid_to_pixel(column+direction.x,row+direction.y))
		other_piece.move(grid_to_pixel(column,row))

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

# Find the pieces matches and return them
func find_matches():
	var total_matchs = []
	if !move_checked:
		for i in width:
			for j in height:
				if all_pieces[i][j] != null:
					var current_color = all_pieces[i][j].color
					if i > 0 && i < width - 1:
						if not all_pieces[i-1][j]==null && not all_pieces[i+1][j]==null:
							if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
								total_matchs.append(all_pieces[i-1][j])
								total_matchs.append(all_pieces[i][j])
								total_matchs.append(all_pieces[i+1][j])
	
					if j > 0 && j < height - 1:
						if not all_pieces[i][j-1]==null && not all_pieces[i][j+1]==null:
							if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
								total_matchs.append(all_pieces[i][j-1])
								total_matchs.append(all_pieces[i][j])
								total_matchs.append(all_pieces[i][j+1])	
	return total_matchs

# This method is main: Change the visibility of pieces array according matched value]
func change_pieces_visibility(pieces):
	var visibility_pieces_changed = 0
	for piece in pieces:
		if not piece.matched:
			piece.matched = true
			visibility_pieces_changed += 1
		piece.dim()
	return visibility_pieces_changed

# Returns the position in a column and row according to a pixel
func pixel_to_grid(pixel):
	var new_x = round((pixel.x -x_start)/offset)
	var new_y = round((pixel.y -y_start)/-offset)
	return Vector2(new_x,new_y)

# Check if grid_position is in grid
func is_in_grid(grid_position):
	if grid_position.x>=0 &&grid_position.x<width:
		if grid_position.y>= 0&& grid_position.y<height:
			return true
		return false

# Destroy matches pieces, collapse and refill columns
func destroy_and_refill(matchs):
	change_pieces_visibility(matchs)
	get_parent().get_node('destroy_timer').start()# destroy_matches()
	get_parent().get_node('collapse_timer').start()#collapse_columns()
	get_parent().get_node('refill_timer').start()# refill_columns()

# Destroy the pieces matched
func destroy_matches():
	var was_matches = false
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				#damage_special(i,j) Fase 2
				was_matches = true
				piece.queue_free()
				all_pieces[i][j] = null
	move_checked = true
	if was_matches:
		get_parent().get_node("destroy_audio").play()
		#get_parent().get_node('collapse_timer').start()
	#else:
		#swap_back()
		#swap_pieces(last_place.x, last_place.y, last_direction)

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

# Check the matches after refill
func recheck_matchs():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i,j,all_pieces[i][j].color):
				print("recheck!")
				var matchs = find_matches()
				destroy_and_refill(matchs)
				#get_parent().get_node("combo_audio").play()
				#get_parent().get_node("destroy_timer").start()
	state = waiting_move
	move_checked = false

# TODO: Find matches, destroy them, collapse and refill columns (causa error)
func ia_auto_checking():
	print("ia_auto_checking")
	#state = autochecking
	#state = waiting_move
	var matchs = find_matches()
	while matchs :		
		matchs = find_matches()
		if matchs:
			print("ia_auto_checking: matchs!")
			destroy_and_refill(matchs)
		else:
			state = waiting_move
			move_checked = false
##################################################################################################################################
##################################################     SIGNALS     ###############################################################
##################################################################################################################################
# SIGNAL: Spawn the pieces
func _on_ready_timer_timeout():
	spawn_piece()

# SIGNAL: Destroy the pieces mached after a timing expecified. It is called when start function on timer node is executed
func _on_destroy_timer_timeout():
	destroy_matches()

# SIGNAL: Collapse the pieces
func _on_collapse_timer_timeout():
	collapse_columns()

# SIGNAL: Refill the grid with pieces
func _on_refill_timer_timeout():
	refill_columns()