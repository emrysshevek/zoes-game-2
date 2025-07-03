extends Node2D

var spots_n_objects_in_autosell_area:Dictionary
var spots_n_ships_in_facility_area:Dictionary

var currently_clicked_object = null

@export var ship_scene:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spots_n_objects_in_autosell_area = {$AutoSellArea2D/AutoSellAreaPoint1:null, $AutoSellArea2D/AutoSellAreaPoint2:null,
	$AutoSellArea2D/AutoSellAreaPoint3:null, $AutoSellArea2D/AutoSellAreaPoint4:null, $AutoSellArea2D/AutoSellAreaPoint5:null,
	$AutoSellArea2D/AutoSellAreaCollision6:null, $AutoSellArea2D/AutoSellAreaCollision7:null, $AutoSellArea2D/AutoSellAreaCollision8:null,
	$AutoSellArea2D/AutoSellAreaCollision9:null, $AutoSellArea2D/AutoSellAreaCollision10:null}
	spots_n_ships_in_facility_area = {$FacilityArea2D/FacilityAreaPoint1:null, $FacilityArea2D/FacilityAreaPoint2:null,
	$FacilityArea2D/FacilityAreaPoint3:null, $FacilityArea2D/FacilityAreaPoint4:null, $FacilityArea2D/FacilityAreaPoint5:null, 
	$FacilityArea2D/FacilityAreaPoint6:null, $FacilityArea2D/FacilityAreaPoint7:null, $FacilityArea2D/FacilityAreaPoint8:null,
	$FacilityArea2D/FacilityAreaPoint9:null, $FacilityArea2D/FacilityAreaPoint10:null}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currently_clicked_object != null:
		draw_placement_ghost(currently_clicked_object)
	else:
		$PlacementGhost.visible = false

func draw_placement_ghost(moving_object:Node2D):
	if $WaitingArea2D.overlaps_area(moving_object.get_my_collision_area()) == true:
		if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_objects_in_autosell_area):
		#above is to check that there is an available open waiting spot
			$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_objects_in_autosell_area).global_position
			$PlacementGhost.texture = moving_object.get_my_sprite()
			$PlacementGhost.visible = true
		else:
			if moving_object.has_docked == false:
			#if it hasn't docked then all zones are still available for it to move to
				if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_ships_in_facility_area):
					$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_ships_in_facility_area).global_position
					$PlacementGhost.texture = moving_object.get_my_sprite()
					$PlacementGhost.visible = true
	elif $DockedArea2D.overlaps_area(moving_object.get_my_collision_area()) == true:
		if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_ships_in_facility_area):
			$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_ships_in_facility_area).global_position
			$PlacementGhost.texture = moving_object.get_my_sprite()
			$PlacementGhost.visible = true
		else:
			if moving_object.has_docked == false:
			#if it hasn't docked then all zones are still available for it to move to
				if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_objects_in_autosell_area):
					$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_objects_in_autosell_area).global_position
					$PlacementGhost.texture = moving_object.get_my_sprite()
					$PlacementGhost.visible = true
	else:
		if moving_object.global_position.distance_to($DockedArea2D.global_position) < moving_object.global_position.distance_to($WaitingArea2D.global_position):
			if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_ships_in_facility_area):
				$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_ships_in_facility_area).global_position
				$PlacementGhost.texture = moving_object.get_my_sprite()
				$PlacementGhost.visible = true
		else:
			if $PlacementGhost != get_closest_open_spot_for_object($PlacementGhost, spots_n_objects_in_autosell_area):
				$PlacementGhost.global_position = get_closest_open_spot_for_object(moving_object, spots_n_objects_in_autosell_area).global_position
				$PlacementGhost.texture = moving_object.get_my_sprite()
				$PlacementGhost.visible = true

func get_closest_open_spot_for_object(object_looking_for_spot:Node2D, area_to_look_in_first:Dictionary):
	var possible_spots = []
	for each_spot in area_to_look_in_first.keys():
		if area_to_look_in_first[each_spot] != null:
			pass
		else:
			possible_spots.append(each_spot)
	if possible_spots.is_empty() == true:
		return object_looking_for_spot
	else:
		var closest_spot = possible_spots[0]
		for each_spot in possible_spots:
			if each_spot.global_position.distance_to(object_looking_for_spot.global_position) < closest_spot.global_position.distance_to(object_looking_for_spot.global_position):
				closest_spot = each_spot
		return closest_spot
		
func place_object_in_autosell_area(object_to_place:Node2D):
	var spot_to_move_to = get_closest_open_spot_for_object(object_to_place, spots_n_objects_in_autosell_area)
	if object_to_place.global_position != spot_to_move_to.global_position:
		object_to_place.global_position = spot_to_move_to.global_position
		spots_n_objects_in_autosell_area[spot_to_move_to] = object_to_place
	else:
		print("object can't move, no spots found")
		object_to_place.deconstruct()

func get_spot_by_vector(vector_input:Vector2):
	for each_spot in spots_n_ships_in_facility_area:
		if each_spot.global_position == vector_input:
			return [each_spot, spots_n_ships_in_facility_area]
	for each_spot in spots_n_objects_in_autosell_area:
		if each_spot.global_position == vector_input:
			return [each_spot, spots_n_objects_in_autosell_area]
	return [Vector2(0,0), null]

func _on_waiting_area_2d_area_entered(area: Area2D) -> void:
	pass

func _on_child_entered_tree(node: Node) -> void:
	if node.get_parent() == self:
		if "ship_name" in node:
			node.ship_clicked.connect(_on_ship_clicked)
			node.ship_released.connect(_on_ship_released)
			place_object_in_autosell_area(node)
 
func _on_button_pressed() -> void:
	var new_ship = ship_scene.instantiate()
	add_child(new_ship)

func _on_ship_clicked(clicked_ship:Node2D):
	for each_spot in spots_n_objects_in_autosell_area.keys():
		if spots_n_objects_in_autosell_area[each_spot] == clicked_ship:
			spots_n_objects_in_autosell_area[each_spot] = null
	currently_clicked_object = clicked_ship

func _on_ship_released(released_ship:Node2D):
	currently_clicked_object = null
	#need some logic below to avoid some weird interactions if the ghost moves during placement or smth
	released_ship.global_position = $PlacementGhost.global_position #place it in the right spot
	var spot_to_add_ship_to = get_spot_by_vector(released_ship.global_position)
	if spot_to_add_ship_to[1] != null:
		spot_to_add_ship_to[1][spot_to_add_ship_to[0]] = released_ship
		
		
