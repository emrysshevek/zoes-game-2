extends Node2D

var rand_num = RandomNumberGenerator.new()

var current_player:player_entity
var current_draft_menu:Node2D

var config = ConfigFile.new()

var ships_elsewhere = [] #ships that are not in the draft menu or on player station

enum pick_of_three_menu_types{upgrade, planet}

var active_pick_of_three_menu

var my_sound_effects:AudioStreamPlayer2D
var songs_to_play:Array

var draft_tutorial_done_skipped:bool
var station_tutorial_done_skipped:bool
var menu_tutorial_done_skipped:bool

var menu_tutorial_text = ["Your goal is to collect enough GCr (Guild Credits) to pay the station guild for your new position. \n\nSurvive past payment #3 on Day 7 to win!"]
var draft_tutorial_text = ["Once per shift you will be required to pick new ships and/or facilities to add to your station. You and other competing stations will each pick one at a time.",
"To pick an item, left click and drag it down to your pick area then let it go.\n\n\nPICK AREA-->",
"Hover over a ship or facility to bring up the information menu, which will explain its effects. Facilities can be upgraded from the info panel later on. Right click or move your mouse away to close the menu.",
"You must fill up the 6 slots of your pick area exactly to be FREE (to proceed). If you have open space in your pick area but there is nothing to pick of the right size, you BUST.",
"When you BUST, all the items you've picked are returned to the shared area to be picked from again. You then get first pick of these items before picking continues around to each player as normal.",
"Opponents can also BUST and will be forced to drop their picks the same way. Pick carefully!"]
var station_tutorial_text = ["The ships and facilities you just picked will appear in the waiting area at the top right.\nDrag ships to the 'Docking' row to place them and gain their benefits",
"Ships will remain in the docking area for a set number of shifts, at which point they will depart. Ships cannot be moved to another spot after they have docked",
"Drag facilities down to the 'Facilities' row to 'Install' them and gain their benefits. The 'Storage' row is for storing facilities and resources. Facilities stored here have no effect.",
"Most facilities will need to 'Install' when first placed somewhere before they have any effect. Facilities count as installed once the docking phase starts",
"Some ships and facilities have abilities that activate when you drag something onto them. You'll see an indicator for this when you click a compatible ship/resource",
"Click 'Begin Docking' once you have placed all your ships and facilities to activate their effects. Click 'end shift' to proceed to the next shift and pick new ships/facilities.",
"Check the information display in the top right to see how much time you have until your first Guild Payment is due. Failure to pay is game over"]

@export var ship_scene:PackedScene
@export var facility_object_scene:PackedScene
@export var resource_scene:PackedScene
@export var draft_menu:PackedScene
@export var pick_of_three_menu_scene:PackedScene
@export var payment_menu_scene:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	config.load("res://config.ini")
	draft_tutorial_done_skipped = config.get_value("main", "draft_tutorial_done_skipped", null)
	station_tutorial_done_skipped = config.get_value("main", "station_tutorial_done_skipped", null)
	menu_tutorial_done_skipped = config.get_value("main", "menu_tutorial_done_skipped", null)
	#^config load
	my_sound_effects = AudioStreamPlayer2D.new()
	add_child(my_sound_effects)
	my_sound_effects.finished.connect(_on_song_end)
	songs_to_play = ["res://sounds/song1.wav", "res://sounds/song2.wav", "res://sounds/song3.wav"]
	my_sound_effects.stream = load(songs_to_play.pick_random())
	my_sound_effects.play(0)
	if menu_tutorial_done_skipped == false:
		$TutorialOrgNode.visible = true
		$TutorialOrgNode/Text.text = menu_tutorial_text[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generate_all_ships(number_to_generate:int):
	var possible_picks = []
	for each_ship_type in GlobalReference.ship_types:
		possible_picks.append(each_ship_type)
	for each_num in number_to_generate:
		ships_elsewhere.append(setup_new_ship(GlobalReference.ship_types[possible_picks.pick_random()]))

func setup_new_ship(ship_type:int):
	var new_ship = ship_scene.instantiate()
	new_ship.first_time_setup(ship_type)
	new_ship.visible = false
	add_child(new_ship)
	return new_ship
	
func setup_new_facility_object(object_type:int):
	var new_object = facility_object_scene.instantiate()
	new_object.first_time_setup(object_type)
	add_child(new_object)
	return new_object
	
func setup_new_resource_object(resource_type:int):
	var new_resource = resource_scene.instantiate()
	new_resource.first_time_setup(resource_type)
	add_child(new_resource)
	return new_resource
	
func new_draft_menu():
	#print(str(ships_elsewhere.size()))
	current_draft_menu = draft_menu.instantiate()
	add_child(current_draft_menu)
	current_draft_menu.receive_player_ref(current_player)
	var pack_array = []
	#set up the 4 draft packs
	pack_array.append(set_up_draft_pack(GlobalReference.planet_to_pack_type[current_player.current_planet]))
	pack_array.append(set_up_draft_pack(GlobalReference.pack_types.ship_all))
	pack_array.append(set_up_draft_pack(GlobalReference.pack_types.ship_all))
	pack_array.append(set_up_draft_pack(GlobalReference.pack_types.facility_all))
	current_draft_menu.add_objects_to_draft_areas_first_time(pack_array)
	current_draft_menu.set_visibility(true)
	current_draft_menu.proceed_out_of_draft_button_pressed.connect(_on_proceed_out_of_draft_button_pressed)
	if draft_tutorial_done_skipped == false || draft_tutorial_done_skipped == null:
		$TutorialOrgNode.visible = true
		$TutorialOrgNode/Text.text = draft_tutorial_text[0]
	$ViewStationButton.visible = true
	
func set_up_draft_pack(pack_type:int):
	var remaining_size = 6
	var possible_picks = []
	var picks_to_return = []
	var pack_type_to_tag:Dictionary = {GlobalReference.pack_types.explorer:GlobalReference.tags.explorer,
									GlobalReference.pack_types.science:GlobalReference.tags.science,
									GlobalReference.pack_types.tourist:GlobalReference.tags.tourist,
									GlobalReference.pack_types.inspector:GlobalReference.tags.inspector,
									GlobalReference.pack_types.tinker:GlobalReference.tags.tinker,
									GlobalReference.pack_types.merchant:GlobalReference.tags.merchant,
									GlobalReference.pack_types.small:GlobalReference.tags.small,
									GlobalReference.pack_types.medium:GlobalReference.tags.medium,
									GlobalReference.pack_types.large:GlobalReference.tags.large}
	##get all possible cards of the right type - later replace this with a more fine-grained filter
	if pack_type == GlobalReference.pack_types.ship_all:
		for each_ship in ships_elsewhere:
			possible_picks.append(each_ship)
	elif pack_type == GlobalReference.pack_types.facility_all:
		for each_object_type in GlobalReference.object_types:
			possible_picks.append(each_object_type)
	else:
		for each_ship in ships_elsewhere:
			if each_ship.tags.find(pack_type_to_tag[pack_type]) != -1:
				possible_picks.append(each_ship)
		for each_facility in GlobalReference.object_types:
			if GlobalReference.object_info[GlobalReference.object_types[each_facility]][GlobalReference.object_stats.tags].find(pack_type_to_tag[pack_type]) != -1:
				#adding each three times so that no matter what there will be enough items of each type to fill a draft spot
				possible_picks.append(each_facility)
				possible_picks.append(each_facility)
				possible_picks.append(each_facility)
	for num in 6: #run through generation process up to 6 times to find valid objects
		var random_roll = rand_num.randi_range(0, possible_picks.size() - 1)
		var object_to_return
		if pack_type == GlobalReference.pack_types.ship_all:
			object_to_return = possible_picks.pick_random()
			picks_to_return.append(object_to_return)
			possible_picks.erase(object_to_return)
			ships_elsewhere.erase(object_to_return)
		elif pack_type == GlobalReference.pack_types.facility_all:
			object_to_return = setup_new_facility_object(GlobalReference.object_types[possible_picks[random_roll]])
			picks_to_return.append(object_to_return)
		else:
			if possible_picks.is_empty() == true:
				object_to_return = GlobalReference.object_types.keys()[GlobalReference.object_types.inspector_small]
			else:
				object_to_return = possible_picks.pick_random()
			if object_to_return is card_object:
				picks_to_return.append(object_to_return)
				possible_picks.erase(object_to_return)
				ships_elsewhere.erase(object_to_return)
			else:
				var new_facility = setup_new_facility_object(GlobalReference.object_types[object_to_return])
				picks_to_return.append(new_facility)
				object_to_return = new_facility
		remaining_size -= object_to_return.get_size()
		#remove oversize objects
		var picks_to_remove_due_to_size = []
		if remaining_size == 2:
			for each_item in possible_picks:
				if "supertype" in each_item:
					if each_item.size > 2:
						#index 6 should be the size for ships
						picks_to_remove_due_to_size.append(each_item)
				elif GlobalReference.object_types.find_key(each_item) != -1:
					if GlobalReference.object_info[GlobalReference.object_types[each_item]][4] > 2:
						#index 4 should be the size for facility objects
						picks_to_remove_due_to_size.append(each_item)
				else:
					assert(false)
		if remaining_size == 1:
			for each_item in possible_picks:
				if "supertype" in each_item:
					if each_item.size > 1:
						picks_to_remove_due_to_size.append(each_item)
				elif GlobalReference.object_types.find_key(each_item) != -1:
					if GlobalReference.object_info[GlobalReference.object_types[each_item]][4] > 1:
						#index 4 should be the size for facility objects
						picks_to_remove_due_to_size.append(each_item)
				else:
					assert(false)
		if remaining_size <= 0:
			break
		for each_item in picks_to_remove_due_to_size:
			possible_picks.erase(each_item)
		#^remove oversize objects
	return picks_to_return

func new_pick_of_three_menu(type:int):
	var pick_of_three_menu = pick_of_three_menu_scene.instantiate()
	add_child(pick_of_three_menu)
	active_pick_of_three_menu = pick_of_three_menu
	pick_of_three_menu.upgrade_selected.connect(_on_pick_of_three_menu_upgrade_selected)
	pick_of_three_menu.planet_selected.connect(_on_pick_of_three_planet_selected)

func new_payment_menu():
	var payment_menu = payment_menu_scene.instantiate()
	add_child(payment_menu)
	payment_menu.game_over.connect(_on_game_over)
	payment_menu.proceed_out_of_payment_screen.connect(_on_proceed_out_of_payment_screen)
	payment_menu.set_up_payment_screen(GlobalReference.guild_payment_deadlines_cost[current_player.day], current_player.credits)

func post_station_menu_decision():
	if current_player.day == current_player.next_guild_payment_day && current_player.shift == 1:
		my_sound_effects.stop()
		new_payment_menu()
	elif current_player.shifts_until_new_planet <= 0:
		if my_sound_effects.playing == false:
			my_sound_effects.play(0)
		new_pick_of_three_menu(pick_of_three_menu_types.planet)
		active_pick_of_three_menu.set_up_planet_cards(current_player.planet_picks_max)
		active_pick_of_three_menu.toggle_visible(true)
		current_player.random_shifts_till_new_planet()
	else:
		if my_sound_effects.playing == false:
			my_sound_effects.play(0)
		new_draft_menu()

func reset_temp_card_values(card_to_reset:card_object):
	card_to_reset.tags.erase(GlobalReference.tags.pleased)
	card_to_reset.tags.erase(GlobalReference.tags.inspected)
	card_to_reset.currently_clicked = false
	card_to_reset.draw_source_ghost = false
	card_to_reset.per_shift_effect_uses_left = card_to_reset.per_shift_effect_uses_max
	card_to_reset.locked = false
	if card_to_reset.supertype == GlobalReference.card_supertypes.ship:
		card_to_reset.has_docked = false
		card_to_reset.dock_duration = GlobalReference.ship_info[card_to_reset.type][GlobalReference.ship_stats.dock_time]
		card_to_reset.docking_status = GlobalReference.ship_docking_statuses.waiting
		card_to_reset.inspection_haul = 2

func _on_proceed_out_of_draft_button_pressed(drafted_cards:Array, opponent_drafted_cards:Array):
	for each_card in opponent_drafted_cards:
		if each_card.supertype == GlobalReference.card_supertypes.ship:
			ships_elsewhere.append(each_card)
			each_card.visible = false
			each_card.reparent(self)
	current_draft_menu.set_visibility(false)
	$StationMenu.set_visibility(true)
	$ViewStationButton.visible = false
	$StationMenu.receive_drafted_cards(drafted_cards)
	#are_any_of_these_cards_dupes(drafted_cards, opponent_drafted_cards)
	if station_tutorial_done_skipped == false || station_tutorial_done_skipped == null:
		$TutorialOrgNode.visible = true
		$TutorialOrgNode/Text.text = station_tutorial_text[0]
	current_draft_menu.deconstruct()
	
func are_any_of_these_cards_dupes(cards_to_check_from:Array, cards_to_check_against:Array):
	for each_card in cards_to_check_from:
		if cards_to_check_against.find(each_card) != -1:
			print("yup")
			return true
	print("nope")
	
func _on_station_menu_end_phase(leaving_ships:Array):
	$StationMenu.set_visibility(false)
	$ViewStationButton.visible = true
	for each_ship in leaving_ships:
		ships_elsewhere.append(each_ship)
		each_ship.visible = false
		reset_temp_card_values(each_ship)
		add_child(each_ship)
	current_player.next_shift()
	post_station_menu_decision()

func _on_upgrade_screen_request(upgrading_card:card_object):
	new_pick_of_three_menu(pick_of_three_menu_types.upgrade)
	active_pick_of_three_menu.set_up_upgrade_cards(upgrading_card, current_player.card_upgrades_max)
	$StationMenu.set_visibility(false)
	$ViewStationButton.visible = true
	active_pick_of_three_menu.toggle_visible(true)
	$ViewStationButton.visible = true

func _on_pick_of_three_menu_upgrade_selected(card_upgrading:card_object, upgrade_type:int):
	$StationMenu.apply_upgrade(card_upgrading, upgrade_type)
	$StationMenu.set_visibility(true)
	$ViewStationButton.visible = false
	active_pick_of_three_menu.toggle_visible(false)
	active_pick_of_three_menu.deconstruct()
	active_pick_of_three_menu = null

func _on_pick_of_three_planet_selected(planet_type:int):
	current_player.current_planet = planet_type
	active_pick_of_three_menu.toggle_visible(false)
	active_pick_of_three_menu.deconstruct()
	active_pick_of_three_menu = null
	post_station_menu_decision()
	
func _on_proceed_out_of_payment_screen(player_new_credits:int):
	var guild_payment_days = GlobalReference.guild_payment_deadlines_cost.keys()
	current_player.credits = player_new_credits
	var current_payment_index = guild_payment_days.find(current_player.next_guild_payment_day)
	if current_payment_index == 2:
		$VictoryScreenOrganizer.visible = true
		my_sound_effects.stream = load("res://sounds/victory.wav")
		my_sound_effects.play(0)
		$ViewStationButton.visible = false
	else:
		current_player.next_guild_payment_day = guild_payment_days[current_payment_index + 1]
		post_station_menu_decision()
	
func _on_game_over():
	config.set_value("main", "draft_tutorial_done_skipped", draft_tutorial_done_skipped)
	config.set_value("main", "station_tutorial_done_skipped", station_tutorial_done_skipped)
	config.set_value("main", "menu_tutorial_done_skipped", menu_tutorial_done_skipped)
	config.save("res://config.ini")
	get_tree().reload_current_scene()


func _on_view_station_button_pressed() -> void:
	if $StationMenu.visible == false:
		if current_draft_menu != null:
			current_draft_menu.visible = false
		if active_pick_of_three_menu != null:
			active_pick_of_three_menu.visible = false
		$StationMenu.set_visibility(true)
		$ViewStationButton.text = "(Back)"
		$ViewStationBG.visible = true
	else:
		$StationMenu.set_visibility(false)
		$ViewStationButton.text = "(View Station)"
		if current_draft_menu != null:
			current_draft_menu.visible = true
		if active_pick_of_three_menu != null:
			active_pick_of_three_menu.visible = true
		$ViewStationBG.visible = false
		
func _on_song_end():
	my_sound_effects.stream = load(songs_to_play.pick_random())
	my_sound_effects.play(0)


func _on__start_button_pressed() -> void:
	generate_all_ships(70)
	current_player = player_entity.new()
	new_draft_menu()
	$StationMenu.receive_player_ref(current_player)
	$StationMenu.end_phase.connect(_on_station_menu_end_phase)
	$StationMenu.upgrade_screen_request.connect(_on_upgrade_screen_request)
	$StartMenuOrganizer.visible = false

func _on_next_button_pressed() -> void:
	if current_draft_menu == null && current_player == null:
		$TutorialOrgNode.visible = false
	elif current_draft_menu == null && current_player != null:
		station_tutorial_text.remove_at(0)
		if station_tutorial_text.is_empty() == false:
			$TutorialOrgNode/Text.text = station_tutorial_text[0]
		else:
			$TutorialOrgNode.visible = false
	else:
		draft_tutorial_text.remove_at(0)
		if draft_tutorial_text.is_empty() == false:
			$TutorialOrgNode/Text.text = draft_tutorial_text[0]
		else:
			$TutorialOrgNode.visible = false

func _on_skip_button_pressed() -> void:
	if current_draft_menu == null && current_player == null:
		menu_tutorial_done_skipped = true
		$TutorialOrgNode.visible = false
	elif current_draft_menu == null && current_player != null:
		station_tutorial_done_skipped = true
		$TutorialOrgNode.visible = false
	else:
		draft_tutorial_done_skipped = true
		$TutorialOrgNode.visible = false
