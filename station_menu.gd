extends Node2D

var effect_queue:Array = []

var placement_areas:Dictionary

var currently_clicked_object = null

var current_info_panel = null

var departing_ships = []

var pop_up_queue = []

var my_sound_effects:AudioStreamPlayer2D

var rand_num = RandomNumberGenerator.new()

var current_player:player_entity

var all_tweens_to_labels:Dictionary

@export var ship_scene:PackedScene
@export var facility_object_scene:PackedScene
@export var resource_scene:PackedScene
@export var drag_interact_scene:PackedScene
@export var card_info_panel:PackedScene

var drag_interact_areas = []

signal end_phase(leaving_ships:Array)
signal upgrade_screen_request(card_upgrading:card_object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_sound_effects = AudioStreamPlayer2D.new()
	add_child(my_sound_effects)
	placement_areas[GlobalReference.placement_area_types.waiting] = $WaitingArea
	placement_areas[GlobalReference.placement_area_types.docked] = $DockedArea
	placement_areas[GlobalReference.placement_area_types.autosell] = $AutoSellArea
	placement_areas[GlobalReference.placement_area_types.facility] = $FacilityArea
	$AutoSellArea.set_up_new_placement_area(GlobalReference.placement_area_types.autosell, 10, false, Vector2(650,670), Vector2(1500,200))
	$FacilityArea.set_up_new_placement_area(GlobalReference.placement_area_types.facility, 10, false, Vector2(650,900), Vector2(1500, 250))
	$WaitingArea.set_up_new_placement_area(GlobalReference.placement_area_types.waiting, 6, false, Vector2(1000,150), Vector2(800,300))
	$DockedArea.set_up_new_placement_area(GlobalReference.placement_area_types.docked, 10, false, Vector2(650,450), Vector2(1500,250))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currently_clicked_object != null && self.visible == true:
		draw_placement_ghost(currently_clicked_object)
	else:
		$PlacementGhost.visible = false
	
func start_of_shift():
	#reset per shift abilities
	for each_ship in $DockedArea.get_all_cards_here():
		each_ship.per_shift_effect_uses_left = each_ship.per_shift_effect_uses_max
		if each_ship.dock_duration == 99 && current_player.current_planet == GlobalReference.planets.explorer_test:
			each_ship.adjust_dock_duration(-99)
	for each_facility in $FacilityArea.get_all_cards_here():
		each_facility.per_shift_effect_uses_left = each_facility.per_shift_effect_uses_max
	$WaitingArea.lock_cards(false)
	$FacilityArea.lock_cards(false)
	$AutoSellArea.lock_cards(false)
	$DockedArea.lock_cards(false)
	$EndPhaseButton.text = "Begin docking"
	$GuildPayLabel.text = "Next Guild Payment due at start of day " + str(current_player.next_guild_payment_day) + "\nAmount due: " + str(GlobalReference.guild_payment_deadlines_cost[current_player.next_guild_payment_day]) + "GCr"
	set_planet_info()
	set_portal_shift_display()
	
func set_planet_info():
	$DirectLinkPlanetContainer/DirectLinkPlanetButton.text = ""
	if current_player.current_planet != GlobalReference.planets.none:
		$DirectLinkPlanetContainer/DirectLinkPlanetButton.text = GlobalReference.planet_info[current_player.current_planet][0]
		$DirectLinkPlanetCard/OptionContainer/Optionlabel.text = GlobalReference.planet_info[current_player.current_planet][0]
		$DirectLinkPlanetCard/OptionContainer/PlanetSprite.texture = load (GlobalReference.planet_info[current_player.current_planet][2])
		$DirectLinkPlanetCard/OptionContainer/PlanetSprite.position = $DirectLinkPlanetCard/OptionContainer/SpriteBackground.position + Vector2(100,150)
		$DirectLinkPlanetCard/OptionContainer/OptionDescription.text = GlobalReference.planet_info[current_player.current_planet][1]
		
func set_portal_shift_display():
	$DirectLinkPlanetContainer/GeneratePortalTelemetryButton.visible = true
	$DirectLinkPlanetContainer/NextPlanetChangeLabel.text = "Portal shift in: " + str(current_player.shifts_until_new_planet)
	if current_player.has_portal_telemetry == false:
		if current_player.shifts_until_new_planet == 1:
			$DirectLinkPlanetContainer/NextPlanetChangeLabel.visible = true
			$DirectLinkPlanetContainer/GeneratePortalTelemetryButton.visible = false
	else:
		$DirectLinkPlanetContainer/NextPlanetChangeLabel.visible = true
		$DirectLinkPlanetContainer/GeneratePortalTelemetryButton.visible = false
	$DirectLinkPlanetCard/OptionContainer.reset_size()
		
		
#func show_card_effect_previews():
	#for each_ship in $DockedArea.get_all_cards_here():
		#var docking_statuses_to_effect_lists:Dictionary = {GlobalReference.ship_docking_statuses.arrived:each_ship.arrive_effects, GlobalReference.ship_docking_statuses.docked:each_ship.docked_effects, GlobalReference.ship_docking_statuses.depart:each_ship.depart_effects}
		#for each_effect in docking_statuses_to_effect_lists[each_ship.docking_status]:
			#each_ship.play_effect_pop_up(0, each_effect, true)
	#for each_facility in $FacilityArea.get_all_cards_here():
		#for each_effect in each_facility.effects:
			#each_facility.play_effect_pop_up(0, each_effect, true)
	
func receive_player_ref(player_reference:player_entity):
	current_player = player_reference

func apply_upgrade(card_being_upgraded:card_object, upgrade:int):
	#upgrades possible should be pre-checked to ensure they can only apply to the correct card
	card_being_upgraded.add_upgrade(upgrade)
	var card_effects = card_being_upgraded.get_my_effects()
	if upgrade == GlobalReference.upgrades.increased_uses:
		card_being_upgraded.per_shift_effect_uses_max += 1
		card_being_upgraded.per_shift_effect_uses_left += 1
	elif upgrade == GlobalReference.upgrades.increased_credits:
		var candidate_effects = []
		for each_effect in card_effects:
			if each_effect.effect_type == GlobalReference.effect_types.adjust_credits && each_effect.x_value_type != GlobalReference.x_value_types.percent_10_science:
				candidate_effects.append(each_effect)
		candidate_effects.pick_random().resolver_values[0] += 2
	elif upgrade == GlobalReference.upgrades.increased_science:
		var candidate_effects = []
		for each_effect in card_effects:
			if each_effect.effect_type == GlobalReference.effect_types.adjust_science:
				candidate_effects.append(each_effect)
		candidate_effects.pick_random().resolver_values[0] += 2
	elif upgrade == GlobalReference.upgrades.increased_sell_price:
		card_being_upgraded.sell_value += 5
	elif upgrade == GlobalReference.upgrades.rush_up:
		var candidate_effects = []
		for each_effect in card_effects:
			if each_effect.effect_type == GlobalReference.effect_types.rush:
				candidate_effects.append(each_effect)
		candidate_effects.pick_random().resolver_values[0] -= 1
	elif upgrade == GlobalReference.upgrades.more_produced:
		var candidate_effects = []
		for each_effect in card_effects:
			if each_effect.effect_type == GlobalReference.effect_types.give_resource:
				candidate_effects.append(each_effect)
		candidate_effects.pick_random().resolver_values[1][0] += 1
	elif upgrade == GlobalReference.upgrades.mobile:
		card_being_upgraded.mobile = true
	elif upgrade == GlobalReference.upgrades.add_credit_effect || upgrade == GlobalReference.upgrades.add_science_effect || upgrade == GlobalReference.upgrades.repair:
		var new_effect = Effect.new()
		var new_effect_type:int
		if upgrade == GlobalReference.upgrades.add_credit_effect:
			new_effect_type = GlobalReference.effect_types.adjust_credits
			new_effect.first_time_effect_setup([new_effect_type, GlobalReference.requirement_types.none, GlobalReference.effect_targetting_types.none, [1], GlobalReference.x_value_types.none, []], card_being_upgraded)
		elif upgrade == GlobalReference.upgrades.add_science_effect:
			new_effect_type = GlobalReference.effect_types.adjust_science
			new_effect.first_time_effect_setup([new_effect_type, GlobalReference.requirement_types.none, GlobalReference.effect_targetting_types.none, [1], GlobalReference.x_value_types.none, []], card_being_upgraded)
		elif upgrade == GlobalReference.upgrades.repair:
			new_effect_type = GlobalReference.effect_types.remove_tag
			new_effect.first_time_effect_setup([new_effect_type, GlobalReference.requirement_types.none, GlobalReference.effect_targetting_types.all_adjacent, [GlobalReference.tags.damaged], GlobalReference.x_value_types.none, []], card_being_upgraded)
		if card_being_upgraded.supertype == GlobalReference.card_supertypes.ship:
			var ship_effect_spots = ["Arrive", "Docked", "Depart"]
			var random_effect_spot = ship_effect_spots.pick_random()
			if random_effect_spot == "Arrive":
				card_being_upgraded.arrive_effects.append(new_effect)
			elif random_effect_spot == "Docked":
				card_being_upgraded.docked_effects.append(new_effect)
			elif random_effect_spot == "Depart":
				card_being_upgraded.depart_effects.append(new_effect)
			else:
				print("invalid type of ship effect: " + str(random_effect_spot))
				assert(false)
		else:
			card_being_upgraded.effects.append(new_effect)
		
func process_effect(effect_to_process:Effect):
	#print("processing effect from:" + effect_to_process.source.object_name)
	var requirement_passed = check_effect_requirements(effect_to_process)
	if requirement_passed == false:
		return false
	else:
		#get targets for effect
		var effect_targets = []
		if effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.all_adjacent:
			var targets_found = $DockedArea.get_adjacents_for(effect_to_process.source, GlobalReference.requirement_types.adjacent_both)
			var targets = []
			for each_target in targets_found:
				if each_target != null:
					targets.append(each_target)
			effect_targets.append_array(targets)
		elif effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_left:
			var target_found = $DockedArea.get_adjacents_for(effect_to_process.source, GlobalReference.requirement_types.adjacent_left)
			if target_found != null:
				effect_targets.append_array(target_found)
		elif effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_right:
			var target_found = $DockedArea.get_adjacents_for(effect_to_process.source, GlobalReference.requirement_types.adjacent_right)
			if target_found != null:
				effect_targets.append_array(target_found)
		elif effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.random_ship_inspect:
			var ships = $DockedArea.get_all_cards_here()
			var possible_targets = []
			for each_ship in ships:
				if each_ship.get_my_tags().find(GlobalReference.tags.inspected) == -1:
					possible_targets.append(each_ship)
			if possible_targets.is_empty() == false:
				effect_targets.append(possible_targets.pick_random())
		#process effect based on type
		if effect_to_process.effect_type == GlobalReference.effect_types.none:
			pass
		elif effect_to_process.effect_type == GlobalReference.effect_types.adjust_credits:
			var value_to_add
			if effect_to_process.x_value_type == GlobalReference.x_value_types.none:
				value_to_add = effect_to_process.resolver_values[0]
			elif effect_to_process.x_value_type == GlobalReference.x_value_types.each_ship:
				value_to_add = effect_to_process.resolver_values[0] * $DockedArea.get_all_cards_here().size()
			elif effect_to_process.x_value_type == GlobalReference.x_value_types.each_facility:
				var possible_facilities = $FacilityArea.get_all_cards_here()
				var facilities = []
				for each_possible_facility in possible_facilities:
					if each_possible_facility.supertype == GlobalReference.card_supertypes.facility:
						facilities.append(each_possible_facility)
				value_to_add = effect_to_process.resolver_values[0] * facilities.size()
			elif effect_to_process.x_value_type == GlobalReference.x_value_types.ships_with_tag:
				var ships = $DockedArea.get_all_cards_here()
				var running_total = 0
				for each_ship in ships:
					if each_ship.get_my_tags().find(effect_to_process.requirement_values[0]) != -1:
						running_total += 1
				value_to_add = running_total * effect_to_process.resolver_values[0]
			elif effect_to_process.x_value_type == GlobalReference.x_value_types.percent_10_science:
				value_to_add = int(current_player.science * 0.10)
			else:
				print("unexpected x_value_type: " + str(effect_to_process.x_value_type))
				assert(false)
			adjust_player_credits(value_to_add)
		elif effect_to_process.effect_type == GlobalReference.effect_types.add_tag:
			var tags_to_add = effect_to_process.resolver_values[0]
			if effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.self_target:
				effect_to_process.source.add_tags([tags_to_add])
			else:
				for each_target in effect_targets:
					each_target.add_tags([tags_to_add])
		elif effect_to_process.effect_type == GlobalReference.effect_types.remove_tag:
			var tags_to_remove = effect_to_process.resolver_values[0]
			if effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.self_target:
				effect_to_process.source.remove_tags([tags_to_remove])
			else:
				for each_target in effect_targets:
					each_target.remove_tags([tags_to_remove])
		elif effect_to_process.effect_type == GlobalReference.effect_types.give_resource:
			var type_to_make = effect_to_process.resolver_values[0][0]
			var number_to_spawn = effect_to_process.resolver_values[1][0]
			attempt_spawn_resource(effect_to_process.source, [type_to_make, number_to_spawn])
		elif effect_to_process.effect_type == GlobalReference.effect_types.refine_resource:
			pass
		elif effect_to_process.effect_type == GlobalReference.effect_types.buy_resource:
			pass
		elif effect_to_process.effect_type == GlobalReference.effect_types.rush:
			if effect_to_process.effect_targetting_type != GlobalReference.effect_targetting_types.none:
				for each_target in effect_targets:
					if each_target != null:
						if each_target.get_my_tags().find(GlobalReference.tags.damaged) == -1 && each_target.has_docked == true:
							each_target.adjust_dock_duration(effect_to_process.resolver_values[0])
							add_pop_up_to_queue("Rushed " + str(effect_to_process.resolver_values[0]), Color("#3ce8ba"), each_target.get_my_pop_up_location(), null)
						else:
							add_pop_up_to_queue("Can't be rushed, damaged or hasn't docked yet" , Color("#3ce8ba"), each_target.get_my_pop_up_location(), null)
		elif effect_to_process.effect_type == GlobalReference.effect_types.adjust_science:
			var value_to_add
			if effect_to_process.x_value_type == GlobalReference.x_value_types.none:
				value_to_add = effect_to_process.resolver_values[0]
			elif effect_to_process.x_value_type == GlobalReference.x_value_types.each_ship:
				value_to_add = effect_to_process.resolver_values[0] * $DockedArea.get_all_cards_here().size()
				print("value_to_add: " + str(value_to_add))
			else:
				print("unexpected x_value_type: " + str(effect_to_process.x_value_type))
				assert(false)
			adjust_player_science(value_to_add)
		elif effect_to_process.effect_type == GlobalReference.effect_types.delay:
			if effect_to_process.effect_targetting_type != GlobalReference.effect_targetting_types.none:
				for each_target in effect_targets:
					if each_target != null:
						each_target.adjust_dock_duration(effect_to_process.resolver_values[0])
						add_pop_up_to_queue("Delayed " + str(effect_to_process.resolver_values[0]), Color("#419ab5"), each_target.get_my_pop_up_location(), null)
						#each_target.play_non_effect_pop_up(1, "Delayed " + str(effect_to_process.resolver_values[0]), Color("#419ab5"))
		elif effect_to_process.effect_type == GlobalReference.effect_types.inspect:
			if effect_to_process.effect_targetting_type != GlobalReference.effect_targetting_types.none:
				for each_target in effect_targets:
					if each_target != null:
						if each_target.supertype == GlobalReference.card_supertypes.ship && each_target.get_my_tags().find(GlobalReference.tags.inspected) == -1:
						#if the target is a ship and it doesn't have the inspected tag
							each_target.add_tags([GlobalReference.tags.inspected])
							#var targets_effects:Array = each_target.get_my_effects()
							#var viable_inspection_effect_targets = []
							#for each_effect in targets_effects:
								#if each_effect.get_type() == GlobalReference.effect_types.adjust_credits && each_effect.resolver_values[0] > 0:
									#viable_inspection_effect_targets.append(each_effect)
							#if viable_inspection_effect_targets.is_empty() == false:
								#var effect_to_inspect = viable_inspection_effect_targets.pick_random()
								#effect_to_inspect.resolver_values[0] -= 0
							if effect_to_process.source.supertype == GlobalReference.card_supertypes.ship:
								effect_to_process.source.adjust_inspection_haul(effect_to_process.source.inspection_haul) #to double it
							add_pop_up_to_queue("Inspected", Color("#7741b5"), each_target.get_my_pop_up_location(), null)
								#each_target.play_non_effect_pop_up(1, "Inspected", Color("#7741b5"))
						else:
							add_pop_up_to_queue("Couldn't Inspect", Color("#7741b5"), each_target.get_my_pop_up_location(), null)
		elif effect_to_process.effect_type == GlobalReference.effect_types.inspection_payout:
			adjust_player_credits(effect_to_process.source.inspection_haul)
			effect_to_process.source.inspection_haul = 2
		elif effect_to_process.effect_type == GlobalReference.effect_types.upgrade_random:
			if effect_to_process.effect_targetting_type != GlobalReference.effect_targetting_types.none:
				for each_target in effect_targets:
					if each_target != null:
						if each_target.supertype == GlobalReference.card_supertypes.ship && each_target.upgrade_level < 5:
							var random_upgrade = GlobalReference.get_possible_upgrades(each_target).pick_random()
							apply_upgrade(each_target, random_upgrade)
							add_pop_up_to_queue("Upgrade: " + str(GlobalReference.upgrade_info[random_upgrade][0]), Color("66e6f5"), each_target.get_my_pop_up_location(), null)
							#each_target.play_non_effect_pop_up(1, "Upgrade: " + str(GlobalReference.upgrade_info[random_upgrade][0]), Color("66e6f5"))
		elif effect_to_process.effect_type == GlobalReference.effect_types.upgrade_point:
				for each_target in effect_targets:
					if each_target != null:
						if each_target.supertype == GlobalReference.card_supertypes.ship && each_target.upgrade_level < 5:
							each_target.add_upgrade_level(effect_to_process.resolver_values[0])
							add_pop_up_to_queue("Ready to upgrade", Color("66e6f5"), each_target.get_my_pop_up_location(), null)
							#each_target.play_non_effect_pop_up(1, "Ready to upgrade", Color("66e6f5"))
		elif effect_to_process.effect_type == GlobalReference.effect_types.get_telemetry:
			if current_player.has_portal_telemetry == false:
				current_player.has_portal_telemetry = true
				$DirectLinkPlanetContainer/NextPlanetChangeLabel.visible = true
		else:
			print("unhandled effect type process: " + str(effect_to_process.effect_type))
			assert(false)
	if effect_to_process.requirement != GlobalReference.requirement_types.drag_to:
		add_pop_up_to_queue("", 0, effect_to_process.source.get_my_pop_up_location(), effect_to_process)
		#effect_to_process.source.play_effect_pop_up(1,effect_to_process, false)

func add_pop_up_to_queue(pop_up_text:String, text_color:Color, pop_up_location:Vector2, optional_linked_effect:Effect):
	var text_to_set:String = pop_up_text
	var color_to_set:Color = text_color
	var location_for_text:Vector2 = pop_up_location
	if optional_linked_effect != null:
		if optional_linked_effect.effect_type == GlobalReference.effect_types.adjust_credits:
			if optional_linked_effect.x_value_type == GlobalReference.x_value_types.percent_10_science:
				text_to_set = str(int(current_player.science * 0.10)) + "GCr"
			elif optional_linked_effect.x_value_type == GlobalReference.x_value_types.each_ship:
				text_to_set = str($DockedArea.get_all_cards_here().size() * optional_linked_effect.resolver_values[0]) + "GCr"
			elif optional_linked_effect.x_value_type == GlobalReference.x_value_types.each_facility:
				text_to_set = str($FacilityArea.get_all_cards_here().size() * optional_linked_effect.resolver_values[0]) + "GCr"
			else:
				text_to_set = str(optional_linked_effect.resolver_values[0]) + "GCr"
			color_to_set = Color("#dec523")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.add_tag:
			text_to_set = str(GlobalReference.tags.keys()[optional_linked_effect.resolver_values[0]]) + " tag added"
			color_to_set = Color("#3ce8ba")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.remove_tag:
			text_to_set = str(GlobalReference.tags.keys()[optional_linked_effect.resolver_values[0]]) + " tag removed"
			color_to_set = Color("#e04a90")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.rush:
			text_to_set = "Ship rushed " + str(abs(optional_linked_effect.resolver_values[0]))
			color_to_set = Color("#3ce8ba")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.give_resource:
			text_to_set = str(GlobalReference.resource_types.keys()[optional_linked_effect.resolver_values[0][0]]) + " added to storage"
			color_to_set = Color("#b59b5b")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.buy_resource:
			text_to_set = "Bought " + str(GlobalReference.resource_types.keys()[optional_linked_effect.resolver_values[0][0]]) + " for " + str(optional_linked_effect.resolver_values[1][0])
			color_to_set = Color("#dec523")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.refine_resource:
			text_to_set = "Resource refined"
			color_to_set = Color("#b59b5b")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.adjust_science:
			text_to_set = str(optional_linked_effect.resolver_values[0]) + " Science"
			color_to_set = Color("#3769bf")
		elif optional_linked_effect.effect_type == GlobalReference.effect_types.inspection_payout:
			text_to_set = str(optional_linked_effect.source.inspection_haul) + "GCr"
			color_to_set = Color("#dec523")
	pop_up_queue.append([text_to_set, color_to_set, location_for_text])

func play_next_pop_up():
	if pop_up_queue.is_empty():
		return
	else:
		play_pop_up(0.6, pop_up_queue[0][0], pop_up_queue[0][1], pop_up_queue[0][2])

func play_pop_up(play_speed:float, pop_up_text:String, text_color:Color, pop_up_location:Vector2):
	var pop_up_tween = get_tree().create_tween()
	var pop_up_text_label = Label.new()
	pop_up_text_label.visible = false
	pop_up_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop_up_text_label.set_theme(load("res://pop_up_text_theme.tres"))
	add_child(pop_up_text_label)
	all_tweens_to_labels[pop_up_tween] = pop_up_text_label
	pop_up_tween.finished.connect(_on_pop_up_tween_finish.bind(pop_up_tween))
	pop_up_tween.step_finished.connect(_on_pop_up_tween_step_complete)
	#set text position to upper center middle of sprite
	pop_up_text_label.position = pop_up_location
	var text_to_set:String = pop_up_text
	var color_to_set:Color = text_color
	pop_up_text_label.text = text_to_set
	pop_up_text_label.visible = true
	pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(pop_up_location.x, pop_up_location.y - 100), (play_speed * 0.7))
	pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", color_to_set, (play_speed * 0.7))
	pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(pop_up_location.x, pop_up_location.y - 200), play_speed)
	pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", Color("ffffff00"), play_speed)
	if text_color == Color("#dec523"):
		my_sound_effects.stream = load("res://sounds/coin.wav")
		my_sound_effects.play(0)
	elif text_color == Color("#3769bf"):
		my_sound_effects.stream = load("res://sounds/science.wav")
		my_sound_effects.play(0)
	elif text_color == Color("#3ce8ba"):
		my_sound_effects.stream = load("res://sounds/fast.wav")
		my_sound_effects.play(0)
	elif text_color == Color("#b59b5b"):
		my_sound_effects.stream = load("res://sounds/resource.wav")
		my_sound_effects.play(0)
	elif text_color == Color("#ab3357"):
		my_sound_effects.stream = load("res://sounds/bad.wav")
		my_sound_effects.play(0)
	else:
		my_sound_effects.stream = load("res://sounds/other.wav")
		my_sound_effects.play(0)

func _on_pop_up_tween_step_complete(step_index:int):
	if step_index == 0 && pop_up_queue.is_empty() == false:
		pop_up_queue.remove_at(0)
		play_next_pop_up()

func _on_pop_up_tween_finish(tween_finished:Tween):
	all_tweens_to_labels[tween_finished].set_deferred("disabled", true)	
	all_tweens_to_labels[tween_finished].queue_free()
	all_tweens_to_labels.erase(tween_finished)
	tween_finished.kill()

func process_drag_to_effects(effect_to_process:Effect, dragged_object:card_object):
	if effect_to_process.effect_type == GlobalReference.effect_types.buy_resource:
		adjust_player_credits(effect_to_process.resolver_values[1][0])
		dragged_object.deconstruct()
	elif effect_to_process.effect_type == GlobalReference.effect_types.refine_resource:
		var refine_to_type = GlobalReference.resource_refinements[effect_to_process.resolver_values[0]]
		attempt_spawn_resource(effect_to_process.source, [refine_to_type, 1])
		dragged_object.deconstruct()
		effect_to_process.source.per_shift_effect_uses_left -= 1
	elif effect_to_process.effect_type == GlobalReference.effect_types.rush:
		if dragged_object.get_my_tags().find(GlobalReference.tags.damaged) == -1:
			dragged_object.adjust_dock_duration(effect_to_process.resolver_values[0])
			effect_to_process.source.per_shift_effect_uses_left -= 1
		else:
			add_pop_up_to_queue("Can't rush damaged ships", Color("66e6f5"), dragged_object.get_my_pop_up_location(), null)
	elif effect_to_process.effect_type == GlobalReference.effect_types.delay:
		dragged_object.adjust_dock_duration(effect_to_process.resolver_values[0])
		effect_to_process.source.per_shift_effect_uses_left -= 1
	elif effect_to_process.effect_type == GlobalReference.effect_types.add_tag:
		dragged_object.add_tags([effect_to_process.resolver_values[0]])
		#add_pop_up_to_queue("Added tag: " + str(GlobalReference.tags.keys()[effect_to_process.resolver_values[0]]) , Color("66e6f5"), dragged_object.get_my_pop_up_location(), null)
		#dragged_object.play_non_effect_pop_up(1, "Pleased", Color("66e6f5"))
		effect_to_process.source.per_shift_effect_uses_left -= 1
	elif effect_to_process.effect_type == GlobalReference.effect_types.remove_tag:
		dragged_object.remove_tags([effect_to_process.resolver_values[0]])
		#add_pop_up_to_queue("Removed tag: " + str(GlobalReference.tags.keys()[effect_to_process.resolver_values[0]]) , Color("66e6f5"), dragged_object.get_my_pop_up_location(), null)
		effect_to_process.source.per_shift_effect_uses_left -= 1
	else:
		print("unexpected drag to effect type")
		assert(false)
	clear_ship_drag_interact_areas()
	add_pop_up_to_queue("", 0, effect_to_process.source.get_my_pop_up_location(), effect_to_process)
	#effect_to_process.source.play_effect_pop_up(1,effect_to_process, false)
	play_next_pop_up()
		
func check_effect_requirements(effect_to_process:Effect):
	var requirement = effect_to_process.get_requirement()
	var is_ship = false
	var is_facility = false
	var is_other = false
	if effect_to_process.source.supertype == GlobalReference.card_supertypes.ship:
		is_ship = true
	if requirement == GlobalReference.requirement_types.none:
		return true
	elif requirement == GlobalReference.requirement_types.drag_to:
		return false
	elif requirement == GlobalReference.requirement_types.adjacent_both || requirement == GlobalReference.requirement_types.adjacent_left || requirement == GlobalReference.requirement_types.adjacent_right || requirement == GlobalReference.requirement_types.adjacent_none:
		if $DockedArea.get_all_cards_here().find(effect_to_process.source) != -1:
			#if the ship is found in the docked row...
			#print(str($DockedArea.get_adjacents_for(effect_to_process.source, requirement)))
			var adjacents = $DockedArea.get_adjacents_for(effect_to_process.source, requirement)
			if requirement == GlobalReference.requirement_types.adjacent_left || requirement == GlobalReference.requirement_types.adjacent_right:
				if adjacents != null:
					if adjacents[0] != null:
						return true
					else:
						return false
				elif requirement == GlobalReference.requirement_types.adjacent_both:
					if adjacents[0] != null && adjacents[1] != null:
						return true
					else:
						return false
				elif requirement == GlobalReference.requirement_types.adjacent_none:
					if adjacents[0] == null && adjacents [1] == null:
						return true
					else:
						return false
				else:
					return false
		else:
			print("ship not found in docked area, but an attempt to play its effects happened")
			assert(false)
	elif requirement == GlobalReference.requirement_types.has_tag_self:
		if effect_to_process.source.tags.find(effect_to_process.requirement_values[0]) == -1:
			return false
		else:
			return true
	elif requirement == GlobalReference.requirement_types.has_tag_target:
		var requirement_to_use:int
		if effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.all_adjacent:
			requirement_to_use = GlobalReference.requirement_types.adjacent_both
		elif effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_left:
			requirement_to_use = GlobalReference.requirement_types.adjacent_left
		elif effect_to_process.effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_right:
			requirement_to_use = GlobalReference.requirement_types.adjacent_right
		else:
			print("unexpected effect targetting type in 'has tag target' requirement check")
			assert(false)
		var adjacent_ships = $DockedArea.get_adjacents_for(effect_to_process.source, requirement_to_use)
		var return_value = false
		for each_adjacent_ship in adjacent_ships:
			if each_adjacent_ship == null:
				break
			if each_adjacent_ship.get_my_tags().find(effect_to_process.requirement_values[0]) == -1:
				return_value = false
			else:
				return_value = true
		return return_value
	elif requirement == GlobalReference.requirement_types.portal_unexplored:
		if current_player.current_planet == GlobalReference.planets.explorer_test:
			return true
		else:
			return false
	else:
		print("unhandled requirement type: " + str(requirement))
		assert(false)

func set_visibility(set_to:bool):
	if set_to == true:
		self.visible = true
	else:
		self.visible = false

func receive_drafted_cards(drafted_cards:Array):
	for each_card in drafted_cards:
		each_card.reparent(self)
		hook_up_new_card(each_card)
		#var new_card
		#if each_card.supertype == GlobalReference.card_supertypes.ship:
			#new_card = ship_scene.instantiate()
		#elif each_card.supertype == GlobalReference.card_supertypes.facility:
			#new_card = facility_object_scene.instantiate()
		#elif each_card.supertype == GlobalReference.card_supertypes.resource:
			#pass
		#else:
			#print("card with unknown supertype in received draft cards")
			#assert(false)
		#new_card.first_time_setup(each_card.type)
		#add_child(new_card)
		#each_card.deconstruct()
	change_phase(GlobalReference.turn_phases.planning)
	start_of_shift()
	

func change_phase(new_phase:int):
	current_player.change_phase(new_phase)
	$TimeLabel.text = "Day " + str(current_player.day) + ", Shift " + str(current_player.shift)

func draw_placement_ghost(clicked_object:card_object):
	var is_ship:bool
	var areas_types_to_check = []
	if clicked_object.supertype == GlobalReference.card_supertypes.ship:
		is_ship = true
		areas_types_to_check.append(GlobalReference.placement_area_types.waiting)
		areas_types_to_check.append(GlobalReference.placement_area_types.docked)
	elif clicked_object.supertype == GlobalReference.card_supertypes.facility:
		is_ship = false
		areas_types_to_check.append(GlobalReference.placement_area_types.autosell)
		areas_types_to_check.append(GlobalReference.placement_area_types.facility)
	elif clicked_object.supertype == GlobalReference.card_supertypes.resource:
		is_ship = false
		areas_types_to_check.append(GlobalReference.placement_area_types.autosell)
		areas_types_to_check.append(GlobalReference.placement_area_types.facility)
	else:
		print("card with unrecognized supertype in draw placement ghost")
		assert(false)
	if clicked_object.draw_source_ghost == false:
		for each_area in areas_types_to_check:
			if placement_areas[each_area].check_for_selected_object_overlap(clicked_object) == true && placement_areas[each_area].check_if_enough_open_space(clicked_object) == true:
				$PlacementGhost.global_position = placement_areas[each_area].get_closest_open_spot_for_ship(clicked_object).global_position
				$PlacementGhost.texture = clicked_object.get_my_sprite_texture()
				$PlacementGhost.modulate = clicked_object.get_my_sprite_modulate()
				$PlacementGhost.visible = true
				break
		if $PlacementGhost.visible == false: #this occurs if no overlap was found
			if clicked_object.global_position.distance_to(placement_areas[areas_types_to_check[0]].global_position) <= clicked_object.global_position.distance_to(placement_areas[areas_types_to_check[1]].global_position) && placement_areas[areas_types_to_check[0]].check_if_enough_open_space(clicked_object) == true:
				$PlacementGhost.global_position = placement_areas[areas_types_to_check[0]].get_closest_open_spot_for_ship(clicked_object).global_position
				$PlacementGhost.texture = clicked_object.get_my_sprite_texture()
				$PlacementGhost.modulate = clicked_object.get_my_sprite_modulate()
				$PlacementGhost.visible = true
			elif clicked_object.global_position.distance_to(placement_areas[areas_types_to_check[1]].global_position) < clicked_object.global_position.distance_to(placement_areas[areas_types_to_check[0]].global_position) && placement_areas[areas_types_to_check[1]].check_if_enough_open_space(clicked_object) == true:
				$PlacementGhost.global_position = placement_areas[areas_types_to_check[1]].get_closest_open_spot_for_ship(clicked_object).global_position
				$PlacementGhost.texture = clicked_object.get_my_sprite_texture()
				$PlacementGhost.modulate = clicked_object.get_my_sprite_modulate()
				$PlacementGhost.visible = true
			else:
				print("no spots open anywhere, placement ghost cannot be placed")
	else:
		#only need to check the docked area here cuz you can't be docked in the waiting area
		var ship_spot = placement_areas[GlobalReference.placement_area_types.docked].get_spot_of_object(clicked_object)
		if ship_spot == null:
			print("couldn't find ships current spot??")
			print(str(clicked_object.get_parent()))
			search_all_areas_for_ship(clicked_object)
			assert(false)
		$PlacementGhost.global_position = ship_spot.global_position
		$PlacementGhost.texture = clicked_object.get_my_sprite_texture()
		$PlacementGhost.modulate = clicked_object.get_my_sprite_modulate()
		$PlacementGhost.visible = true

func search_all_areas_for_ship(ship_to_search_for:card_object):
	var all_cards_everywhere = []
	all_cards_everywhere.append_array($WaitingArea.get_all_cards_here())
	all_cards_everywhere.append_array($DockedArea.get_all_cards_here())
	all_cards_everywhere.append_array($AutoSellArea.get_all_cards_here())
	all_cards_everywhere.append_array($FacilityArea.get_all_cards_here())
	if all_cards_everywhere.find(ship_to_search_for) != -1:
		print("found in another area")
	else:
		print("not in another area")

func get_placement_area_spot_by_vector(vector_input:Vector2):
	var placement_spot
	for each_placement_area in placement_areas:
		if placement_areas[each_placement_area].check_if_vector_is_a_spot_here(vector_input) == true:
			placement_spot = placement_areas[each_placement_area].get_spot_by_vector(vector_input)
			return [placement_spot, placement_areas[each_placement_area]]
	print("spot not found on any placement areas, likely invalid:" + str(vector_input))
	assert(false)
	
func place_object_in_area(object_to_place:card_object, area_to_place:Area2D):
	if area_to_place.check_if_enough_open_space(object_to_place) == true:
		var spot_to_move_to = area_to_place.get_closest_open_spot_for_ship(object_to_place)
		area_to_place.add_object_to_spot(object_to_place, spot_to_move_to)
		object_to_place.global_position = spot_to_move_to.global_position
		if area_to_place == $DockedArea && object_to_place.has_docked == false:
			object_to_place.set_docking_status(GlobalReference.ship_docking_statuses.arrived)
	else:
		print("not enough space in " + str(area_to_place) + " object can't be placed")
		object_to_place.deconstruct()

func adjust_player_credits(adjust_amount:int):
	current_player.adjust_credits(adjust_amount)
	$TestingMoneyLabel.text = str(current_player.credits) + "GCr"

func adjust_player_science(adjust_amount:int):
	current_player.adjust_science(adjust_amount)
	$TestingScienceLabel.text = str(current_player.science) + " Science"

#func sell_auto_sell_area_cards():
	#var cards_to_remove = []
	#for each_card in $AutoSellArea.get_all_cards_here():
		#adjust_player_credits(each_card.sell_value / 2)
		#$TestingMoneyLabel.text = str(current_player.credits) + "cr"
		#cards_to_remove.append(each_card)
	#for each_card in cards_to_remove:
		#$AutoSellArea.attempt_remove_object(each_card)
		#each_card.deconstruct()

#func show_force_depart_area(clicked_ship:card_object):
	#$ForceDepartArea.visible = true
	#$ForceDepartArea.global_position = placement_areas[GlobalReference.placement_area_types.docked].get_spot_of_object(clicked_ship).global_position - Vector2(128,150)

func ship_departing(departing_ship:card_object):
	departing_ship.toggle_depart_visuals(true)
	departing_ships.append(departing_ship)

func _on_end_phase_button_pressed() -> void:
	for each_tween in all_tweens_to_labels:
		all_tweens_to_labels[each_tween].set_deferred("disabled", true)	
		all_tweens_to_labels[each_tween].queue_free()
		all_tweens_to_labels.erase(each_tween)
		each_tween.kill()
	if current_player.phase == GlobalReference.turn_phases.planning:
	#when you click the end phase button while its the planning phase...
		#locking all cards while everything is processed
		$WaitingArea.lock_cards(true)
		$FacilityArea.lock_cards(true)
		$AutoSellArea.lock_cards(true)
		$DockedArea.lock_cards(true)
		#penalty for ships left in waiting area
		for each_ship in $WaitingArea.get_all_cards_here():
			var penalty = each_ship.get_size() * -2
			adjust_player_credits(penalty)
			add_pop_up_to_queue("Leaving, Penalty " + str(penalty) + "GCr", Color("9e1e3e"), each_ship.get_my_pop_up_location(), null)
			if each_ship.supertype == GlobalReference.card_supertypes.ship:
				ship_departing(each_ship)
			else:
				each_ship.deconstruct()
		var ships_to_play_effects_of = $DockedArea.get_all_cards_here()
		for each_ship in ships_to_play_effects_of:
			if each_ship.has_docked == false:
				#if ship hasn't docked yet but is in the docked area then it must be just now docking
				for each_effect in each_ship.arrive_effects:
					process_effect(each_effect)
				each_ship.has_docked = true
			if each_ship.has_docked == true && each_ship.dock_duration > 0:
				#if the ship has docked but isn't set to depart...
				for each_effect in each_ship.docked_effects:
					process_effect(each_effect)
				each_ship.adjust_dock_duration(-1)
				if each_ship.dock_duration == 99 && current_player.current_planet == GlobalReference.planets.explorer_test:
					each_ship.adjust_dock_duration(-99)
			if each_ship.has_docked == true && each_ship.dock_duration <= 0:
				#if the ship is set to depart...
				for each_effect in each_ship.depart_effects:
					process_effect(each_effect)
				ship_departing(each_ship)
		for each_facility in $FacilityArea.get_all_cards_here():
			if each_facility.supertype == GlobalReference.card_supertypes.facility:
				if each_facility.has_been_installed == false:
					each_facility.install_in_facility_zone()
				for each_effect in each_facility.effects:
					process_effect(each_effect)
		#unlocking cards after processing
		$WaitingArea.lock_cards(true) #these can't be placed now
		$FacilityArea.lock_cards(false)
		$AutoSellArea.lock_cards(false)
		$DockedArea.lock_cards(false)
		$EndPhaseButton.text = "End shift"
		change_phase(GlobalReference.turn_phases.docking)
		play_next_pop_up()
	elif current_player.phase == GlobalReference.turn_phases.docking:
	#when you click the end phase button while its the docking phase...
		#unlock cards
		$WaitingArea.lock_cards(false)
		$FacilityArea.lock_cards(false)
		$AutoSellArea.lock_cards(false)
		$DockedArea.lock_cards(false)
		#sell_auto_sell_area_cards()
		change_phase(GlobalReference.turn_phases.end)
		var leaving_ships = []
		for each_ship in departing_ships:
			$WaitingArea.attempt_remove_object(each_ship)
			$DockedArea.attempt_remove_object(each_ship)
			each_ship.object_released.disconnect(_on_object_released)
			each_ship.object_clicked.disconnect(_on_object_clicked)
			each_ship.object_hovered.disconnect(_on_card_hovered)
			each_ship.upgrade_button_pressed.disconnect(_on_card_upgrade_button_pressed)
			remove_child(each_ship)
			leaving_ships.append(each_ship)
		departing_ships.clear()
		end_phase.emit(leaving_ships)
	else:
		pass
		
func hook_up_new_card(new_card:card_object):
	if new_card.supertype == GlobalReference.card_supertypes.ship:
		if new_card.object_released.is_connected(_on_object_released) == false:
			new_card.object_clicked.connect(_on_object_clicked)
			new_card.object_released.connect(_on_object_released)
			new_card.object_hovered.connect(_on_card_hovered)
			new_card.upgrade_button_pressed.connect(_on_card_upgrade_button_pressed)
		new_card.set_docking_status(GlobalReference.ship_docking_statuses.waiting)
		place_object_in_area(new_card, $WaitingArea)
	elif new_card.supertype == GlobalReference.card_supertypes.facility:
		if new_card.object_released.is_connected(_on_object_released) == false:
			new_card.object_clicked.connect(_on_object_clicked)
			new_card.object_released.connect(_on_object_released)
			new_card.object_hovered.connect(_on_card_hovered)
			new_card.upgrade_button_pressed.connect(_on_card_upgrade_button_pressed)
		place_object_in_area(new_card, $WaitingArea)
	elif new_card.supertype == GlobalReference.card_supertypes.resource:
		if new_card.object_released.is_connected(_on_object_released) == false:
			new_card.object_clicked.connect(_on_object_clicked)
			new_card.object_released.connect(_on_object_released)
			new_card.object_hovered.connect(_on_card_hovered)
		if $AutoSellArea.get_remaining_space() > 0:
			place_object_in_area(new_card, $AutoSellArea)
		elif $FacilityArea.get_remaining_space() > 0:
			place_object_in_area(new_card, $FacilityArea)
		else:
			print("no space for new resource trying to be created")
			new_card.deconstruct()
	else:
		print("attempting to hook up new card with undefined/invalid supertype")
		assert(false)
		

func attempt_spawn_resource(spawner:card_object, resources_to_spawn:Array):
	for number_to_spawn in resources_to_spawn[1]:
		##need to verify there is space before we do all this
		if $AutoSellArea.get_remaining_space() > 0 || $FacilityArea.get_remaining_space() > 0:
			var new_resource = resource_scene.instantiate()
			new_resource.first_time_setup(resources_to_spawn[0])
			add_child(new_resource)
			new_resource.position = Vector2(0,0)
			hook_up_new_card(new_resource)
			
func toggle_show_sell_area(visibility:bool, object_in_hand:card_object):
	if visibility == true:
		$SellArea.visible = true
		$SellArea/SellAreaText.text = "SELL: " + str(object_in_hand.sell_value)
	else:
		$SellArea.visible = false
			
func check_if_docked_ships_are_buying(resource_type:int):
	for each_ship in $DockedArea.get_all_cards_here():
		var resource_buy_effect = each_ship.get_resource_buy_effect(resource_type)
		if resource_buy_effect != null:
			create_ship_drag_interact_areas(each_ship, resource_buy_effect)
		##if they are, make a 'buy' area appear over them

func create_ship_drag_interact_areas(ship_to_create_for:card_object, related_effect:Effect):
	var new_sell_area = drag_interact_scene.instantiate()
	add_child(new_sell_area)
	drag_interact_areas.append(new_sell_area)
	new_sell_area.link_to_effect(related_effect)
	new_sell_area.sell_value = related_effect.resolver_values[1][0]
	new_sell_area.set_bounds(Vector2((ship_to_create_for.get_size() * 128) + 64, 128))
	new_sell_area.global_position = ship_to_create_for.global_position
	new_sell_area.set_text(related_effect.get_description())

func clear_ship_drag_interact_areas():
	for each_area in drag_interact_areas:
		each_area.deconstruct()
	drag_interact_areas.clear()
	
func check_for_facility_interactions(clicked_object:card_object):
	if clicked_object.supertype == GlobalReference.card_supertypes.resource || clicked_object.supertype == GlobalReference.card_supertypes.ship:
		for each_card in $FacilityArea.get_all_cards_here():
			if each_card.supertype == GlobalReference.card_supertypes.facility && each_card.per_shift_effect_uses_left > 0 && (each_card.has_been_installed == true || each_card.mobile == true):
				for each_effect in each_card.effects:
					if each_effect.get_requirement() == GlobalReference.requirement_types.drag_to:
						if each_effect.effect_type == GlobalReference.effect_types.refine_resource:
							if each_effect.resolver_values[0] == clicked_object.type && clicked_object.supertype == GlobalReference.card_supertypes.resource || clicked_object.get_my_tags().find(GlobalReference.tags.refinable) != -1:
								create_facility_drag_interact_area(each_card, each_effect)
						if each_effect.effect_type == GlobalReference.effect_types.rush:
							if clicked_object.supertype == GlobalReference.card_supertypes.ship && clicked_object.get_my_tags().find(GlobalReference.tags.damaged) == -1:
								create_facility_drag_interact_area(each_card, each_effect)
						if each_effect.effect_type == GlobalReference.effect_types.add_tag:
							if clicked_object.supertype == GlobalReference.card_supertypes.ship:
								create_facility_drag_interact_area(each_card, each_effect)
						if each_effect.effect_type == GlobalReference.effect_types.delay:
							if clicked_object.supertype == GlobalReference.card_supertypes.ship:
								create_facility_drag_interact_area(each_card, each_effect)
						if each_effect.effect_type == GlobalReference.effect_types.remove_tag && clicked_object.get_my_tags().find(each_effect.resolver_values[0]) != -1:
								create_facility_drag_interact_area(each_card, each_effect)
								
func create_facility_drag_interact_area(facility:card_object, related_effect:Effect):
	var new_drag_interact_area = drag_interact_scene.instantiate()
	add_child(new_drag_interact_area)
	drag_interact_areas.append(new_drag_interact_area)
	new_drag_interact_area.link_to_effect(related_effect)
	new_drag_interact_area.set_bounds(Vector2((facility.get_size() * 128), 128))
	new_drag_interact_area.global_position = facility.global_position
	new_drag_interact_area.set_text(related_effect.get_description())

func check_player_for_adequate_science(amount_needed:int):
	if current_player.science >= amount_needed:
		return true
	else:
		return false
		
func spawn_upgrade_menu(card_upgrading:card_object):
	upgrade_screen_request.emit(card_upgrading)

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
	new_info_panel.upgrade_attempt.connect(_on_facility_upgrade_attempt)
	current_info_panel.position = card_for_panel.position
		
func check_for_available_resources(resource_type_needed:int, number_needed:int):
	var resource_count = 0
	var resource_references_to_return = []
	for each_card in $AutoSellArea.get_all_cards_here():
		if each_card.supertype == GlobalReference.card_supertypes.resource:
			if each_card.type == resource_type_needed:
				resource_count += 1
				resource_references_to_return.append(each_card)
				if resource_count >= number_needed:
					return resource_references_to_return
	for each_card in $FacilityArea.get_all_cards_here():
		if each_card.supertype == GlobalReference.card_supertypes.resource:
			if each_card.type == resource_type_needed:
				resource_count += 1
				if resource_count >= number_needed:
					resource_references_to_return.append(each_card)
					return resource_references_to_return
	return null
				
#func _on_child_entered_tree(node: Node) -> void:
	#if node.get_parent() == self:
		#if "supertype" in node:
			#hook_up_new_card(node)
		#else:
			#pass

func _on_object_clicked(clicked_object:card_object):
	if clicked_object.supertype == GlobalReference.card_supertypes.ship:
		if clicked_object.has_docked == false: 
			$WaitingArea.attempt_remove_object(clicked_object)
			$DockedArea.attempt_remove_object(clicked_object)
		else: #if the ship has docked then we don't remove it from spot, create ghost in its spot
			if departing_ships.find(clicked_object) == -1:
				clicked_object.draw_source_ghost = true
				check_for_facility_interactions(clicked_object)
			else:
				clicked_object.draw_source_ghost = true
			#show_force_depart_area(clicked_object)
	else:
		$WaitingArea.attempt_remove_object(clicked_object)
		$AutoSellArea.attempt_remove_object(clicked_object)
		$FacilityArea.attempt_remove_object(clicked_object)
		toggle_show_sell_area(true, clicked_object)
		if clicked_object.supertype == GlobalReference.card_supertypes.resource:
			check_if_docked_ships_are_buying(clicked_object.type)
		check_for_facility_interactions(clicked_object)
	currently_clicked_object = clicked_object
	

func _on_object_released(released_object:card_object):
	currently_clicked_object = null
	if released_object.supertype == GlobalReference.card_supertypes.ship: #this is to prevent docked ships from moving spots
		#if $ForceDepartArea.overlaps_area(released_object.get_my_collision_area()) == true && $ForceDepartArea.visible == true:
			##if its a ship and is released in the force depart area...
			#$DockedArea.attempt_remove_object(released_object)
			#released_object.deconstruct()
			#$ForceDepartArea.visible = false
		#else:
		for each_drag_interact_area in drag_interact_areas:
			if each_drag_interact_area.overlaps_area(released_object.get_my_collision_area()) == true:
				process_drag_to_effects(each_drag_interact_area.linked_effect, released_object)
		if released_object.has_docked == true:
			released_object.draw_source_ghost = false
			released_object.global_position = $PlacementGhost.global_position #needed despite below because of return
			$ForceDepartArea.visible = false
			clear_ship_drag_interact_areas()
			return 
		clear_ship_drag_interact_areas()
	elif released_object.supertype == GlobalReference.card_supertypes.facility || released_object.supertype == GlobalReference.card_supertypes.resource:
		if $SellArea.overlaps_area(released_object.get_my_collision_area()) == true:
			#released facility or resource is over sell area, so sell it
			adjust_player_credits(released_object.sell_value)
			#the below is redundant with this happening on object clicked, but signals may be racing
			$WaitingArea.attempt_remove_object(released_object)
			$AutoSellArea.attempt_remove_object(released_object)
			$FacilityArea.attempt_remove_object(released_object)
			released_object.deconstruct()
		else:
			for each_drag_interact_area in drag_interact_areas:
				if each_drag_interact_area.overlaps_area(released_object.get_my_collision_area()) == true:
					process_drag_to_effects(each_drag_interact_area.linked_effect, released_object)
		clear_ship_drag_interact_areas()
	else:
		print("unrecognized super type for card in object released")
		assert(false)
	$ForceDepartArea.visible = false
	toggle_show_sell_area(false, null)
	#need some logic below to avoid some weird interactions if the ghost moves during placement or smth
	released_object.global_position = $PlacementGhost.global_position #place it in the right spot
	var spot_to_add_object_to = get_placement_area_spot_by_vector(released_object.global_position)
	if spot_to_add_object_to[1] != null:
		place_object_in_area(released_object, spot_to_add_object_to[1])

func _on_spawn_ship_button_pressed() -> void:
	var new_ship = ship_scene.instantiate()
	var possible_ships = []
	for each_ship in GlobalReference.ship_types:
		possible_ships.append(each_ship)
	var ship_type_roll = rand_num.randi_range(0,possible_ships.size() - 1)
	new_ship.first_time_setup(GlobalReference.ship_types[possible_ships[ship_type_roll]])
	add_child(new_ship)

func _on_spawn_facility_button_pressed() -> void:
	var new_object = facility_object_scene.instantiate()
	var possible_objects = []
	for each_object in GlobalReference.object_types:
		possible_objects.append(each_object)
	var object_type_roll = rand_num.randi_range(0, possible_objects.size() - 1)
	new_object.first_time_setup(GlobalReference.object_types[possible_objects[object_type_roll]])
	add_child(new_object)

func _on_facility_upgrade_attempt(facility, using_science, resource_type, amount_needed):
	var facility_starting_level = facility.upgrade_level
	if using_science == true:
		if check_player_for_adequate_science(amount_needed) == true:
			adjust_player_science(amount_needed * -1)
			facility.adjust_upgrade_progress(1)
		else:
			add_pop_up_to_queue("Not enough science", Color("d187ce"), facility.get_my_pop_up_location(), null)
			play_next_pop_up()
			#facility.play_non_effect_pop_up(1, "Not enough science", Color("d187ce"))
	else:
		var possible_objects = check_for_available_resources(resource_type, amount_needed)
		if possible_objects != null:
			for each_object in possible_objects:
				$AutoSellArea.attempt_remove_object(each_object)
				$FacilityArea.attempt_remove_object(each_object)
				each_object.deconstruct()
			facility.adjust_upgrade_progress(1)
		else:
			add_pop_up_to_queue("Not enough " + str(GlobalReference.resource_types.keys()[resource_type]), Color("d187ce"), facility.get_my_pop_up_location(), null)
			play_next_pop_up()
			#facility.play_non_effect_pop_up(1, "Not enough " + str(GlobalReference.resource_types.keys()[resource_type]), Color("d187ce"))
	#if facility.upgrade_level > facility_starting_level:
		#spawn_upgrade_menu(facility)

func _on_card_upgrade_button_pressed(ship_upgrading:card_object):
	spawn_upgrade_menu(ship_upgrading)

func _on_direct_link_planet_button_pressed() -> void:
	if current_player.current_planet != GlobalReference.planets.none:
		$DirectLinkPlanetContainer.visible = false
		$DirectLinkPlanetCard.visible = true

func _on_direct_link_planet_card_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_button_left_down"):
		$DirectLinkPlanetContainer.visible = true
		$DirectLinkPlanetCard.visible = false

func _on_card_hovered(hovered_card:card_object):
	#this happens after card timer waiting to confirm a hover has gone off
	create_card_info_panel(hovered_card)

func _on_generate_portal_telemetry_button_pressed() -> void:
	if check_player_for_adequate_science(20) == true:
		adjust_player_science(-20)
		current_player.set_has_telemetry(true)
		set_portal_shift_display()
		$DirectLinkPlanetContainer/GeneratePortalTelemetryButton.visible = false
	else:
		#insufficient science
		pass
