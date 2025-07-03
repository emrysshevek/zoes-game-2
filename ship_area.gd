extends Area

var currently_clicked_ship = null

@export var ship_scene:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#$WaitingArea2D.set_up_new_placement_area(GlobalReference.placement_area_types.waiting, 6, false, Vector2(1300,150), Vector2(800,300))
	#$DockedArea2D.set_up_new_placement_area(GlobalReference.placement_area_types.docked, 10, false, Vector2(960,450), Vector2(1800,300))
	#placement_areas.append($WaitingArea2D)
	#placement_areas.append($DockedArea2D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if currently_clicked_ship != null:
		#draw_placement_ghost(currently_clicked_ship)
	#else:
		#$PlacementGhost.visible = false

#func draw_placement_ghost(moving_ship:Node2D):
	#if $WaitingArea2D.check_for_selected_ship_overlap(moving_ship) == true && $WaitingArea2D.check_if_enough_open_space(moving_ship) == true:
		#$PlacementGhost.global_position = $WaitingArea2D.get_closest_open_spot_for_ship(moving_ship).global_position
		#$PlacementGhost.texture = moving_ship.get_my_sprite_texture()
		#$PlacementGhost.visible = true
	#elif $DockedArea2D.check_for_selected_ship_overlap(moving_ship) == true && $DockedArea2D.check_if_enough_open_space(moving_ship) == true:
		#$PlacementGhost.global_position = $DockedArea2D.get_closest_open_spot_for_ship(moving_ship).global_position
		#$PlacementGhost.texture = moving_ship.get_my_sprite_texture()
		#$PlacementGhost.visible = true
	#else:
		#if moving_ship.global_position.distance_to($DockedArea2D.global_position) <= moving_ship.global_position.distance_to($WaitingArea2D.global_position) && $DockedArea2D.check_if_enough_open_space(moving_ship) == true:
			#$PlacementGhost.global_position = $DockedArea2D.get_closest_open_spot_for_ship(moving_ship).global_position
			#$PlacementGhost.texture = moving_ship.get_my_sprite_texture()
			#$PlacementGhost.visible = true
		#elif moving_ship.global_position.distance_to($WaitingArea2D.global_position) < moving_ship.global_position.distance_to($DockedArea2D.global_position) && $WaitingArea2D.check_if_enough_open_space(moving_ship) == true:
			#$PlacementGhost.global_position = $WaitingArea2D.get_closest_open_spot_for_ship(moving_ship).global_position
			#$PlacementGhost.texture = moving_ship.get_my_sprite_texture()
			#$PlacementGhost.visible = true
		#else:
			#print("no spots open anywhere, placement ghost cannot be placed")

#func get_closest_open_spot_for_ship(ship_looking_for_spot:Node2D, area_to_look_in_first:Dictionary):
	#var possible_spots = []
	#for each_spot in area_to_look_in_first.keys():
		#if area_to_look_in_first[each_spot] != null:
			#pass
		#else:
			#possible_spots.append(each_spot)
	#if possible_spots.is_empty() == true:
		#return ship_looking_for_spot
	#else:
		#var closest_spot = possible_spots[0]
		#for each_spot in possible_spots:
			#if each_spot.global_position.distance_to(ship_looking_for_spot.global_position) < closest_spot.global_position.distance_to(ship_looking_for_spot.global_position):
				#closest_spot = each_spot
		#return closest_spot
		
#func place_ship_in_waiting_area(ship:Node2D):
	#if $WaitingArea2D.check_if_enough_open_space(ship) == true:
		#var spot_to_move_to = $WaitingArea2D.get_closest_open_spot_for_ship(ship)
		#$WaitingArea2D.add_object_to_spot(ship, spot_to_move_to)
		#ship.global_position = spot_to_move_to.global_position
	#else:
		#print("not enough space in waiting area, ship cannot be placed")
		#ship.deconstruct()

#func get_placement_area_spot_by_vector(vector_input:Vector2):
	#var placement_spot
	#if $DockedArea2D.check_if_vector_is_a_spot_here(vector_input) == true:
		#placement_spot = $DockedArea2D.get_spot_by_vector(vector_input)
		#return [placement_spot, $DockedArea2D]
	#elif $WaitingArea2D.check_if_vector_is_a_spot_here(vector_input) == true:
		#placement_spot = $WaitingArea2D.get_spot_by_vector(vector_input)
		#return [placement_spot, $WaitingArea2D]
	#print("spot not found on any placement areas, likely invalid:" + str(vector_input))
	#assert(false)
	
#func get_ships(area:int):
	#var return_ships = []
	#if area == GlobalReference.placement_area_types.waiting || area == GlobalReference.placement_area_types.any:
		#return_ships.append_array($WaitingArea2D.get_all_ships_here())
	#if area == GlobalReference.placement_area_types.docked || area == GlobalReference.placement_area_types.any:
		#return_ships.append_array($DockedArea2D.get_all_ships_here())
	#return return_ships

func _on_waiting_area_2d_area_entered(area: Area2D) -> void:
	pass

#func _on_child_entered_tree(node: Node) -> void:
	#if node.get_parent() == self:
		#if "has_docked" in node:
			#node.ship_clicked.connect(_on_ship_clicked)
			#node.ship_released.connect(_on_ship_released)
			#place_ship_in_waiting_area(node)
 #
func _on_button_pressed() -> void:
	var new_ship = ship_scene.instantiate()
	var ship_type_roll = rand_num.randi_range(0,1)
	var ship_type
	if ship_type_roll == 0:
		ship_type = GlobalReference.ship_types.test_explorer
	else:
		ship_type = GlobalReference.ship_types.test_medium
	new_ship.first_time_setup(ship_type)
	add_child(new_ship)

func _on_ship_clicked(clicked_ship:Node2D):
	$WaitingArea2D.attempt_remove_ship(clicked_ship)
	$DockedArea2D.attempt_remove_ship(clicked_ship)
	currently_clicked_ship = clicked_ship
#
#func _on_ship_released(released_ship:Node2D):
	#currently_clicked_ship = null
	##need some logic below to avoid some weird interactions if the ghost moves during placement or smth
	#released_ship.global_position = $PlacementGhost.global_position #place it in the right spot
	#var spot_to_add_ship_to = get_placement_area_spot_by_vector(released_ship.global_position)
	#if spot_to_add_ship_to[1] != null:
		#spot_to_add_ship_to[1].add_object_to_spot(released_ship, spot_to_add_ship_to[0])
		
		
