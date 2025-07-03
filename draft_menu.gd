extends Node2D

var currently_clicked_object = null

var rand_num = RandomNumberGenerator.new()

var current_player:player_entity

var current_info_panel = null

var draft_placement_areas:Array

var present_opponent_draft_areas = []

var opponents_who_took_their_turn_draft_areas = []

var player_drafted_ships_to_send = []

var all_tweens_to_labels:Dictionary

@export var ship_scene:PackedScene
@export var facility_object_scene:PackedScene
@export var placement_area_scene:PackedScene
@export var card_info_panel:PackedScene

signal proceed_out_of_draft_button_pressed(cards_drafted:Array, opponent_drafted_ships:Array)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draft_placement_areas = [$DraftPackArea1, $DraftPackArea2, $DraftPackArea3, $DraftPackArea4]
	present_opponent_draft_areas = [$OppLeftCardArea, $OppTopCardArea, $OppRightCardArea]
	for each_area in present_opponent_draft_areas:
		each_area.lock_cards(true)
	setup_draft_menu([])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func receive_player_ref(player_reference:player_entity):
	current_player = player_reference

func set_visibility(set_to:bool):
	if set_to == true:
		self.visible = true
	else:
		self.visible = false

func setup_draft_menu(packs:Array):
	$PlayerCardArea.set_up_new_placement_area(GlobalReference.placement_area_types.draft_hand, 6, false, Vector2(DisplayServer.window_get_size().x / 2, DisplayServer.window_get_size().y - 120), Vector2(800,200))
	$PlayerHandCollisionarea.global_position = $PlayerCardArea.global_position
	$OppLeftCardArea.set_up_new_placement_area(GlobalReference.placement_area_types.draft_hand, 6, false, Vector2(120, DisplayServer.window_get_size().y / 2), Vector2(800,200))
	$OppTopCardArea.set_up_new_placement_area(GlobalReference.placement_area_types.draft_hand, 6, false, Vector2(DisplayServer.window_get_size().x / 2, 120), Vector2(800,200))
	$OppRightCardArea.set_up_new_placement_area(GlobalReference.placement_area_types.draft_hand, 6, false, Vector2(DisplayServer.window_get_size().x - 120, DisplayServer.window_get_size().y / 2), Vector2(800,200))
	$DraftPackArea1.set_up_new_placement_area(GlobalReference.placement_area_types.draft_pack, 6, false, Vector2((DisplayServer.window_get_size().x / 2) - 355, (DisplayServer.window_get_size().y / 2) - 120), Vector2(700,200))
	$DraftPackArea2.set_up_new_placement_area(GlobalReference.placement_area_types.draft_pack, 6, false, Vector2((DisplayServer.window_get_size().x / 2) + 355, (DisplayServer.window_get_size().y / 2) - 120), Vector2(700,200))
	$DraftPackArea3.set_up_new_placement_area(GlobalReference.placement_area_types.draft_pack, 6, false, Vector2((DisplayServer.window_get_size().x / 2) - 355, (DisplayServer.window_get_size().y / 2) + 150), Vector2(700,200))
	$DraftPackArea4.set_up_new_placement_area(GlobalReference.placement_area_types.draft_pack, 6, false, Vector2((DisplayServer.window_get_size().x / 2) + 355, (DisplayServer.window_get_size().y / 2) + 150), Vector2(700,200))

func add_objects_to_draft_areas_first_time(objects:Array):
	var current_objects_array_index = 0
	for each_placement_area in draft_placement_areas:
		for each_object in objects[current_objects_array_index]:
			each_object.reparent(self)
			each_object.visible = true
			each_object.rotation_degrees = 0
			each_object.draw_source_ghost = false
			each_object.set_color("ffffffff")
			if each_object.supertype == GlobalReference.card_supertypes.ship:
				each_object.has_docked = false
				each_object.toggle_depart_visuals(false)
				each_object.set_docking_status(GlobalReference.ship_docking_statuses.draft)
			if each_object.object_released.is_connected(_on_object_released) == false:
				each_object.object_released.connect(_on_object_released)
				each_object.object_clicked.connect(_on_object_clicked)
				each_object.object_hovered.connect(_on_object_hovered)
			if each_placement_area.check_if_enough_open_space(each_object) == true:
				each_object.global_position = Vector2(0,0)
				var spot_to_add_to = each_placement_area.get_closest_open_spot_for_ship(each_object)
				each_placement_area.add_object_to_spot(each_object, spot_to_add_to)
				each_object.global_position = spot_to_add_to.global_position
		current_objects_array_index += 1

func add_individual_object_to_any_draft_area(object:card_object):
	for each_area in draft_placement_areas:
		if each_area.check_if_enough_open_space(object) == true:
			object.global_position = Vector2(0,0)
			var spot_to_add_to = each_area.get_closest_open_spot_for_ship(object)
			each_area.add_object_to_spot(object, spot_to_add_to)
			object.global_position = spot_to_add_to.global_position
			object.rotation_degrees = 0
			return
	print("no open spots found in any draft areas,somehow")
	assert(false)

func set_lock_areas(lock:bool):
	for each_area in draft_placement_areas:
		each_area.lock_cards(lock)
	$PlayerCardArea.lock_cards(lock)

func add_object_to_opponent_hand(object:card_object, hand_to_add_to:Area2D):
	object.global_position = Vector2(0,0)
	if hand_to_add_to.check_if_enough_open_space(object) == true:
		var spot_to_add_to = hand_to_add_to.get_closest_open_spot_for_ship(object)
		hand_to_add_to.add_object_to_spot(object, spot_to_add_to)
		object.global_position = spot_to_add_to.global_position
		if hand_to_add_to == $OppLeftCardArea:
			object.rotation_degrees = 90
		if hand_to_add_to == $OppRightCardArea:
			object.rotation_degrees = 270
	else:
		print("attempting to add object to opponent hand but opponent hand doesn't have room")
	
func remove_object_from_draft_areas(object_to_remove:card_object):
	for each_draft_area in draft_placement_areas:
		each_draft_area.attempt_remove_object(object_to_remove)

func get_all_ships_in_draft_areas():
	var options_to_return = []
	options_to_return.append_array($DraftPackArea1.get_all_cards_here())
	options_to_return.append_array($DraftPackArea2.get_all_cards_here())
	options_to_return.append_array($DraftPackArea3.get_all_cards_here())
	options_to_return.append_array($DraftPackArea4.get_all_cards_here())
	return options_to_return

func start_of_player_turn():
	var opponents_who_are_done = []
	for each_opponent_draft_area in present_opponent_draft_areas:
		if each_opponent_draft_area.get_remaining_space() <= 0:
			opponents_who_are_done.append(each_opponent_draft_area)
	for each_opponent_who_is_done in opponents_who_are_done:
		present_opponent_draft_areas.erase(each_opponent_who_is_done)
		each_opponent_who_is_done.darken(true)
		draft_text_label_popup(" Free!", each_opponent_who_is_done)
	##^checks each opponent to see if their hand is correctly filled, then removes them from the rotation
	if $PlayerCardArea.get_remaining_space() == 0:
		bring_up_proceed_menu()
		return
	check_for_player_hand_space_failure()
	set_lock_areas(false)
	
func opponents_turns():
	set_lock_areas(true)
	var draftable_options = get_all_ships_in_draft_areas()
	for each_opponent_draft_area in present_opponent_draft_areas:
		if opponents_who_took_their_turn_draft_areas.find(each_opponent_draft_area) == -1:
		#if opponents draft areas isn't in this array then they haven't taken their turn yet
			var remaining_space = each_opponent_draft_area.get_remaining_space()
			var filtered_options = []
			for each_object in draftable_options:
				#filter all options to only include those of the correct sizes
				if each_object.get_size() <= remaining_space:
					filtered_options.append(each_object)
			if filtered_options.is_empty():
				#indicating there aren't any viable picks...hand space failure!
				hand_space_failure(each_opponent_draft_area)
				opponents_turns()
				return
			var random_pick = filtered_options[rand_num.randi_range(0, filtered_options.size() - 1)]
			remove_object_from_draft_areas(random_pick)
			add_object_to_opponent_hand(random_pick, each_opponent_draft_area)
			draftable_options.erase(random_pick)
			opponents_who_took_their_turn_draft_areas.append(each_opponent_draft_area)
			#^this ensures they don't take their turn again until player has
	start_of_player_turn()
	
func hand_space_failure(area_of_failure:Area2D):
	draft_text_label_popup(" BUST!!", area_of_failure)
	var cards_to_remove = area_of_failure.get_all_cards_here()
	for each_object in cards_to_remove:
		area_of_failure.attempt_remove_object(each_object)
		add_individual_object_to_any_draft_area(each_object)
		
func check_for_player_hand_space_failure():
	var remaining_space = $PlayerCardArea.get_remaining_space()
	var draftable_options = get_all_ships_in_draft_areas()
	var filtered_options = []
	for each_object in draftable_options:
		#filter all options to only include those of the correct sizes
		if each_object.get_size() <= remaining_space:
			filtered_options.append(each_object)
	if filtered_options.is_empty():
		set_lock_areas(true)
		hand_space_failure($PlayerCardArea)
		set_lock_areas(false)
		return true
	else:
		return false
		
func bring_up_proceed_menu():
	#move players drafted ships to spot for export to main
	var player_drafts = $PlayerCardArea.get_all_cards_here()
	for each_card in player_drafts:
		$PlayerCardArea.attempt_remove_object(each_card) #doing this for cleanup purposes
		each_card.object_released.disconnect(_on_object_released)
		each_card.object_clicked.disconnect(_on_object_clicked)
		each_card.object_hovered.disconnect(_on_object_hovered)
		player_drafted_ships_to_send.append(each_card)
	$ProceedPieces/ProceedOverlay.size = Vector2(DisplayServer.window_get_size())
	$ProceedPieces/ProceedButton.global_position = Vector2((DisplayServer.window_get_size().x / 2) - ($ProceedPieces/ProceedButton.size.x / 2),(DisplayServer.window_get_size().y / 2) - ($ProceedPieces/ProceedButton.size.y / 2))
	$ProceedPieces.visible = true

func create_card_info_panel(card_for_panel:card_object):
	if current_info_panel != null:
		current_info_panel.info_panel_visible(false)
		current_info_panel.deconstruct()
	var new_info_panel = card_info_panel.instantiate()
	current_info_panel = new_info_panel
	add_child(new_info_panel)
	new_info_panel.panel_first_time_setup(card_for_panel)
	new_info_panel.info_panel_visible(true)
	new_info_panel.update_panel_display(card_for_panel)
	current_info_panel.position = card_for_panel.position
	
func draft_text_label_popup(text_to_display:String, player_draft_area:Area2D):
	var pop_up_text_label = Label.new()
	pop_up_text_label.visible = false
	pop_up_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop_up_text_label.set_theme(load("res://Huge_text_size.tres"))
	pop_up_text_label.position = Vector2(670,325)
	add_child(pop_up_text_label)
	var player:String
	if player_draft_area == $OppLeftCardArea:
		player = "Left Opponent"
	elif player_draft_area == $OppTopCardArea:
		player = "Top Opponent"
	elif player_draft_area == $OppRightCardArea:
		player = "Right Opponent"
	else:
		player = "You"
	var pop_up_tween = get_tree().create_tween()
	pop_up_tween.finished.connect(_on_pop_up_tween_finish.bind(pop_up_tween))
	all_tweens_to_labels[pop_up_tween] = pop_up_text_label
	var label_starting_position = Vector2(670,325)
	pop_up_text_label.text = player + text_to_display
	pop_up_tween.tween_property(pop_up_text_label, "visible", true, 0)
	pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(label_starting_position.x, label_starting_position.y - 100 * all_tweens_to_labels.size()), 1)
	pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", Color("#dec523"), 1)
	pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(label_starting_position.x, label_starting_position.y - 200 * all_tweens_to_labels.size()), 1)
	pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", Color("ffffff00"), 1)
	pop_up_tween.tween_property(pop_up_text_label, "visible", false, 1)
	pop_up_tween.parallel().tween_property(pop_up_text_label, "position", Vector2(label_starting_position.x, label_starting_position.y), 1)

func _on_pop_up_tween_finish(finished_tween:Tween):
	all_tweens_to_labels[finished_tween].set_deferred("disabled", true)	
	all_tweens_to_labels[finished_tween].queue_free()
	all_tweens_to_labels.erase(finished_tween)
	finished_tween.kill()
	
func _on_object_clicked(clicked_object:card_object):
	remove_object_from_draft_areas(clicked_object)

func _on_object_released(released_object:card_object):
	if $PlayerCardArea.get_all_cards_here().find(released_object) != -1:
		#if the object is already in the players hand, already been picked. just ignore it
		#later we can figure out how to bring it back to its origin point
		pass
	elif $PlayerHandCollisionarea.overlaps_area(released_object.get_my_collision_area()) == true && $PlayerCardArea.check_if_enough_open_space(released_object) == true:
		released_object.global_position = Vector2(0,0)
		if $PlayerCardArea.check_if_enough_open_space(released_object) == true:
			var spot_to_add_to = $PlayerCardArea.get_closest_open_spot_for_ship(released_object)
			remove_object_from_draft_areas(released_object)
			$PlayerCardArea.add_object_to_spot(released_object, spot_to_add_to)
			released_object.global_position = spot_to_add_to.global_position
			currently_clicked_object = null
			opponents_who_took_their_turn_draft_areas.clear()
			opponents_turns()
		else:
			print("attempting to add released object to player picks but player picks doesn't have room")
			assert(false)
	else:
		add_individual_object_to_any_draft_area(released_object)

func _on_proceed_button_pressed() -> void:
	var opponent_drafted_ships = []
	var areas_to_clear = [$OppLeftCardArea,$OppTopCardArea,$OppRightCardArea]
	areas_to_clear.append_array(draft_placement_areas)
	for each_area in areas_to_clear:
		opponent_drafted_ships.append_array(each_area.get_all_cards_here())
		for each_card in each_area.get_all_cards_here():
			each_area.attempt_remove_object(each_card)
	proceed_out_of_draft_button_pressed.emit(player_drafted_ships_to_send, opponent_drafted_ships)
	#remove all non-player picked ships (for now, later reintegrate them for later draftings)
	$ProceedPieces.visible=false

func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()

func _on_object_hovered(hovered_card:card_object):
	#this happens after card timer waiting to confirm a hover has gone off
	create_card_info_panel(hovered_card)
