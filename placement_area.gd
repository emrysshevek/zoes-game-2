extends Area2D

var area_type:int

var spots_n_objects_in_area:Dictionary
var spots_in_x_order = []

var cards_locked:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up_new_placement_area(new_area_type:int, number_of_points:int, points_jumbled:bool, draw_position:Vector2, collision_area_size:Vector2):
	#make sure to only call this after the node has been added as a child to scene
	area_type = new_area_type
	self.position = draw_position
	var collision_area_shape = RectangleShape2D.new()
	collision_area_shape.set_size(collision_area_size)
	$PlacementAreaCollision.set_shape(collision_area_shape)
	$ColorRect.size = collision_area_shape.size
	$ColorRect.position.y -= collision_area_shape.size.y / 2
	$ColorRect.position.x -= collision_area_shape.size.x / 2
	$PlacementAreaCollision.position = Vector2(0,0)
	for each_point in number_of_points:
		var new_point = Node2D.new()
		spots_n_objects_in_area[new_point] = null
		add_child(new_point)
		new_point.position = Vector2(((collision_area_size.x / (number_of_points)) * each_point) - (collision_area_size.x / 2), 0 - (collision_area_size.y / 4))
	spots_in_x_order = get_spots_in_x_order()

func check_if_enough_open_space(ship_to_check_for:Node2D):
	#need to update this to actually consider ship size
	for each_spot_number in range(0, spots_in_x_order.size()):
		if each_spot_number + (ship_to_check_for.get_size() - 1) > spots_in_x_order.size() - 1:
			break
		else:
			var spot_viable:bool = true
			for each_spot_needed in ship_to_check_for.get_size():
				if spots_n_objects_in_area[spots_in_x_order[each_spot_number + each_spot_needed]] != null:
					spot_viable = false
			if spot_viable == true:
				return true
	return false #if no spots found
	
		#var possible_spots = []
	#for each_spot_number in range(0, spots_in_x_order.size()):
		#if each_spot_number + (ship_looking_for_spot.get_size() - 1) > spots_in_x_order.size() - 1:
			##if the spot we're checking + the ships size would go off the edge of the available spots then we're done here
			#break
		#else:
			#var spot_viable:bool = true
			#for each_spot_needed in ship_looking_for_spot.get_size():
				#if spots_n_objects_in_area[spots_in_x_order[each_spot_number + each_spot_needed]] != null:
					#spot_viable = false
			#if spot_viable == true:
				#possible_spots.append(spots_in_x_order[each_spot_number])

func get_spots_in_x_order():
	#gets all spots in those placement areas spots n objects array sorted from smallest to largest x position value
	var return_array = []
	for each_spot in spots_n_objects_in_area.keys():
		if return_array.is_empty() == true:
			return_array.append(each_spot)
		else:
			var index_to_add_to = 0
			for each_return_spot in return_array:
				if each_spot.position.x > each_return_spot.position.x:
					index_to_add_to += 1
			return_array.insert(index_to_add_to, each_spot)
	#for each_return_spot in return_array:
		#print(str(each_return_spot.position.x))
	return return_array

func get_adjacents_for(card_to_get_for:card_object, adjacency_req_type:int):
	#adjacency_req_type is the enum of the requirement
	var adjacent_left
	var adjacent_right
	var return_spots:Array = []
	for each_spot in spots_in_x_order:
		if spots_n_objects_in_area[each_spot] == card_to_get_for:
			var ship_left_spot_index = spots_in_x_order.find(each_spot)
			if ship_left_spot_index > 0:
				adjacent_left = spots_n_objects_in_area[spots_in_x_order[ship_left_spot_index - 1]]
			else:
				adjacent_left = null
			if ship_left_spot_index + card_to_get_for.get_size() < spots_in_x_order.size():
				adjacent_right = spots_n_objects_in_area[spots_in_x_order[ship_left_spot_index + card_to_get_for.get_size()]]
			else:
				adjacent_right = null
			break #so it doesn't continue checking the spots after its found the object to check adjacency for
	if adjacency_req_type == GlobalReference.requirement_types.adjacent_both || adjacency_req_type == GlobalReference.requirement_types.adjacent_none:
		return_spots.append(adjacent_left)
		return_spots.append(adjacent_right)
	elif adjacency_req_type == GlobalReference.requirement_types.adjacent_left:
		return_spots.append(adjacent_left)
	elif adjacency_req_type == GlobalReference.requirement_types.adjacent_right:
		return_spots.append(adjacent_right)
	else:
		print("unexpected adjacency req type: " + str(adjacency_req_type))
		assert(false)
	return return_spots

func check_if_vector_is_a_spot_here(vector_to_check:Vector2):
	for each_spot in spots_n_objects_in_area:
		if each_spot.global_position == vector_to_check:
			return true
	return false

func get_spot_by_vector(vector_to_check:Vector2):
	#run check_if_vector_is_a_spot_here before this to avoid invalid output
	for each_spot in spots_n_objects_in_area:
		if each_spot.global_position == vector_to_check:
			return each_spot
	print("get_spot_by_vector failed, invalid vecotr input, make sure you called check_if_vector_is_a_spot_here first")
	assert(false)

func check_for_selected_object_overlap(object_to_check:Node2D):
	if self.overlaps_area(object_to_check.get_my_collision_area()) == true:
		return true
	else:
		return false
	#
		#for each_spot_number in range(0, spots_in_order.size()):
		#if each_spot_number + (ship_to_check_for.ship_size - 1) > spots_in_order.size() - 1:
			#break
		#if spots_n_objects_in_area[spots_in_order[each_spot_number]] == null && spots_n_objects_in_area[spots_in_order[each_spot_number + (ship_to_check_for.ship_size - 1)]] == null:
			#return true
		
func get_closest_open_spot_for_ship(ship_looking_for_spot:Node2D):
	var possible_spots = []
	for each_spot_number in range(0, spots_in_x_order.size()):
		if each_spot_number + (ship_looking_for_spot.get_size() - 1) > spots_in_x_order.size() - 1:
			#if the spot we're checking + the ships size would go off the edge of the available spots then we're done here
			break
		else:
			var spot_viable:bool = true
			for each_spot_needed in ship_looking_for_spot.get_size():
				if spots_n_objects_in_area[spots_in_x_order[each_spot_number + each_spot_needed]] != null:
					spot_viable = false
			if spot_viable == true:
				possible_spots.append(spots_in_x_order[each_spot_number])
		#if ship_looking_for_spot.get_size() < 3:
			#if each_spot_number + (ship_looking_for_spot.get_size() - 1) > spots_in_x_order.size() - 1:
				#break
			#elif spots_n_objects_in_area[spots_in_x_order[each_spot_number]] == null && spots_n_objects_in_area[spots_in_x_order[each_spot_number + (ship_looking_for_spot.get_size() - 1)]] == null:
				#possible_spots.append(spots_in_x_order[each_spot_number])
			#else:
				#pass
		#else:
			#if each_spot_number + (ship_looking_for_spot.get_size() - 1) > spots_in_x_order.size() - 1:
				#break
			#elif spots_n_objects_in_area[spots_in_x_order[each_spot_number]] == null && spots_n_objects_in_area[spots_in_x_order[each_spot_number + (ship_looking_for_spot.get_size() - 1)]] == null && spots_n_objects_in_area[spots_in_x_order[each_spot_number + (ship_looking_for_spot.get_size() - 2)]] == null:
				#possible_spots.append(spots_in_x_order[each_spot_number])
			#else:
				#pass
	if possible_spots.is_empty() == true:
		print("ship looking for spot in a placement area that is full, should be caught earlier")
		assert(false)
	else:
		var closest_spot = possible_spots[0]
		for each_spot in possible_spots:
			if each_spot.global_position.distance_to(ship_looking_for_spot.global_position) < closest_spot.global_position.distance_to(ship_looking_for_spot.global_position):
				closest_spot = each_spot
		return closest_spot
		
func add_object_to_spot(object_to_add:Node2D, spot_to_add_to:Node2D):
	var starting_spot_number = spots_in_x_order.find(spot_to_add_to)
	for each_ship_size in range(0,(object_to_add.get_size())):
		spots_n_objects_in_area[spots_in_x_order[starting_spot_number + each_ship_size]] = object_to_add
	object_to_add.locked = cards_locked

func attempt_remove_object(object_to_remove:Node2D):
	#print("attempting to remove object " + object_to_remove.object_name)
	for each_spot in spots_n_objects_in_area.keys():
		if spots_n_objects_in_area[each_spot] == object_to_remove:
			#print("object " + object_to_remove.object_name + " removed from a spot")
			spots_n_objects_in_area[each_spot] = null
	object_to_remove.locked = false

func get_all_cards_here():
	var cards_to_return = []
	for each_spot in spots_n_objects_in_area.keys():
		if spots_n_objects_in_area[each_spot] != null:
			if cards_to_return.find(spots_n_objects_in_area[each_spot]) == -1:
				cards_to_return.append(spots_n_objects_in_area[each_spot])
	return cards_to_return

func get_remaining_space():
	var used_size:int = 0
	for each_card in get_all_cards_here():
		used_size += each_card.get_size()
	return spots_n_objects_in_area.size() - used_size

func get_spot_of_object(object_to_get_spot_for:card_object):
	for each_spot in spots_in_x_order:
		if spots_n_objects_in_area[each_spot] == object_to_get_spot_for:
			return each_spot
	
func lock_cards(lock:bool):
	if lock == true:
		cards_locked = true
		for each_card in get_all_cards_here():
			each_card.locked = true
	else:
		cards_locked = false
		for each_card in get_all_cards_here():
			each_card.locked = false

func darken(make_dark:bool):
	if make_dark == true:
		$ColorRect.visible = true
	else:
		$ColorRect.visible = false
