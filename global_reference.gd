extends Node

const tinker_small = "res://sprites/practiceship1.png"
const tourist_medium = "res://sprites/practiceship_medium.png"
const tourist_small = "res://sprites/wireframetest.png"
const practiceship_large = "res://sprites/practiceship_large.png"
const medium_cargo_ship = "res://sprites/mediun_cargo_ship.png"
const science_small = "res://sprites/science_small.png"
const explorer_homesteader = "res://sprites/explorer_homesteader.png"
const inspector_alien = "res://sprites/inspector_alien.png"
const science_disease_research = "res://sprites/science_disease_research.png"
const tinker_carrier = "res://sprites/tinker_carrier.png"
const inspector_incompetent = "res://sprites/inspector_incompetent.png"
const explorer_colony_organizer = "res://sprites/explorer_colony_organizer.png"
const meteor_ship = "res://sprites/meteor_ship.png"

const practice_facility_small = "res://sprites/practice_facility_small.png"
const practice_facility_medium = "res://sprites/practice_facility_medium.png"
const practice_facility_large = "res://sprites/practice_facility_large.png"
const forge = "res://sprites/facility_forge.png"
const rush_facility_medium = "res://sprites/rush_facility_medium.png"
const restaurant_medium = "res://sprites/restaurant_medium.png"
const inspector_facility_small = "res://sprites/inspector_facility.png"
const science_facility_large = "res://sprites/science_facility_large.png"
const explorer_facility_medium = "res://sprites/explorer_facility.png"
const repair_bay = "res://sprites/repair_bay.png"

const resource_unrefined_metals = "res://sprites/resource_unrefined_metals.png"
const resource_refined_metals = "res://sprites/resource_refined_metals.png"

const planet_temperate = "res://sprites/planet_temperate.png"

var ship_info:Dictionary
var object_info:Dictionary
var resource_info:Dictionary
var planet_info:Dictionary

var resource_refinements:Dictionary

var guild_payment_deadlines_cost:Dictionary

var upgrade_info:Dictionary

enum pack_types{facility_all, ship_all, explorer, science, tourist, inspector, tinker, merchant, small, medium, large}

var planet_to_pack_type:Dictionary

enum card_supertypes{ship, facility, resource}

enum placement_area_types{waiting, docked, facility, autosell, any, draft_pack, draft_hand}
enum ship_stats{ship_name, arrive_effect, docked_effect, depart_effect, tags, sprite_texture, ship_size, dock_time}
enum ship_types{tourist_medium, snooty_traveller, metal_hauler, cargo_medium, science_small, 
	explorer_homesteader, inspector_alien, tinker_small, science_disease_research, tinker_carrier,
	inspector_incompetent, explorer_colony_organizer, meteor_ship}

enum ship_docking_statuses{waiting, arrived, docked, depart, draft}
enum turn_phases{drafting, docking, planning, end}

enum object_stats{object_name, effects, tags, sprite_texture, object_size, sell_value}
enum object_types{restaurant_medium, science_large, forge, rush_medium, inspector_small, explorer_medium, repair_bay}

enum upgrades{increased_uses, increased_credits, increased_science, increased_sell_price, rush_up, 
	more_produced, mobile, add_credit_effect, add_science_effect, repair}

enum resource_stats{resource_name, sprite_texture, sell_value}
enum resource_types{unrefined_metals, refined_metals}

enum effect_types{none, adjust_credits, add_tag, remove_tag, give_resource, buy_resource, refine_resource, rush, 
	adjust_science, delay, inspect, inspection_payout, upgrade_random, upgrade_point, get_telemetry}
enum requirement_types{none, adjacent_both, adjacent_left, adjacent_right, adjacent_none, has_tag_self, drag_to, has_tag_target, portal_unexplored}
enum effect_targetting_types{none, self_target, all_adjacent, adjacent_left, adjacent_right, random_ship_inspect}
enum x_value_types{none, each_ship, each_facility, ships_with_tag, percent_10_science}
enum tags{explorer, science, tourist, inspector, tinker, merchant, small, medium, large, pleased, inspected, damaged, refinable}
	#note small medium and large will be auto-tagged on ship first setup based on size

enum planets{none, explorer_test, science_test, money_test, inspector, tinker, merchant, small_cards, medium_cards, large_cards}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		#ship_types.<<null>>:{ship_stats.ship_name:"<<null>>",
			#ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			#ship_stats.docked_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			#ship_stats.depart_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				#ship_stats.tags:[], ship_stats.sprite_texture:<<null>>, ship_stats.ship_size:<<null>>, ship_stats.dock_time:<<null>>
	ship_info = {
		ship_types.tourist_medium:{ship_stats.ship_name:"Tour Cruiser", 
			ship_stats.arrive_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.self_target, [3], x_value_types.none, []]], 
			ship_stats.docked_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.self_target, [1], x_value_types.each_facility, []]], 
			ship_stats.depart_effect:[[effect_types.adjust_credits, requirement_types.has_tag_self, effect_targetting_types.self_target, [6], x_value_types.none, [tags.pleased]]], 
				ship_stats.tags:[tags.tourist], ship_stats.sprite_texture:tourist_medium, ship_stats.ship_size:2, ship_stats.dock_time:3
			},
		ship_types.snooty_traveller:{ship_stats.ship_name:"Snooty Tourist",
			ship_stats.arrive_effect:[[effect_types.add_tag, requirement_types.adjacent_none, effect_targetting_types.self_target, [tags.pleased], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.adjust_credits, requirement_types.adjacent_none, effect_targetting_types.self_target, [4], x_value_types.none, []],
										[effect_types.remove_tag, requirement_types.adjacent_left, effect_targetting_types.self_target, [tags.pleased], x_value_types.none, []],
										[effect_types.remove_tag, requirement_types.adjacent_right, effect_targetting_types.self_target, [tags.pleased], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.adjust_credits, requirement_types.has_tag_self, effect_targetting_types.self_target, [5], x_value_types.none, [tags.pleased]]],
				ship_stats.tags:[tags.tourist], ship_stats.sprite_texture:tourist_small, ship_stats.ship_size:1, ship_stats.dock_time:2
			},
		ship_types.metal_hauler:{ship_stats.ship_name:"Metal Hauler",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.give_resource, requirement_types.none, effect_targetting_types.none, [[resource_types.unrefined_metals],[1]], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.give_resource, requirement_types.none, effect_targetting_types.none, [[resource_types.refined_metals],[3]], x_value_types.none, []]],
				ship_stats.tags:[tags.merchant], ship_stats.sprite_texture:practiceship_large, ship_stats.ship_size:3, ship_stats.dock_time:3
			},
		ship_types.cargo_medium:{ship_stats.ship_name:"Metal Merchant",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.give_resource, requirement_types.none, effect_targetting_types.none, [[resource_types.unrefined_metals],[1]], x_value_types.none, []],
										[effect_types.buy_resource, requirement_types.drag_to, effect_targetting_types.none, [[resource_types.refined_metals],[6]], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				ship_stats.tags:[tags.merchant], ship_stats.sprite_texture:medium_cargo_ship, ship_stats.ship_size:2, ship_stats.dock_time:2
			},
		ship_types.science_small:{ship_stats.ship_name:"Piloted Probe",
			ship_stats.arrive_effect:[[effect_types.adjust_science, requirement_types.none, effect_targetting_types.none, [2], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.adjust_science, requirement_types.none, effect_targetting_types.none, [2], x_value_types.none, []]],
				ship_stats.tags:[tags.science], ship_stats.sprite_texture:science_small, ship_stats.ship_size:1, ship_stats.dock_time:2
			},
		ship_types.explorer_homesteader:{ship_stats.ship_name:"Hopeful Homesteader",
			ship_stats.arrive_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [1], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [6], x_value_types.none, []]],
				ship_stats.tags:[tags.explorer], ship_stats.sprite_texture:explorer_homesteader, ship_stats.ship_size:2, ship_stats.dock_time:99
			},
		ship_types.inspector_alien:{ship_stats.ship_name:"Alien Inspector",
			ship_stats.arrive_effect:[[effect_types.delay, requirement_types.none, effect_targetting_types.all_adjacent, [1], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.inspect, requirement_types.none, effect_targetting_types.all_adjacent, [], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.inspection_payout, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				ship_stats.tags:[tags.inspector], ship_stats.sprite_texture:inspector_alien, ship_stats.ship_size:1, ship_stats.dock_time:3
			},
		ship_types.tinker_small:{ship_stats.ship_name:"Tinker Shuttle",
			ship_stats.arrive_effect:[[effect_types.upgrade_random, requirement_types.adjacent_left, effect_targetting_types.adjacent_left, [1], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.adjust_credits, requirement_types.adjacent_left, effect_targetting_types.none, [2], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				ship_stats.tags:[tags.tinker], ship_stats.sprite_texture:tinker_small, ship_stats.ship_size:1, ship_stats.dock_time:2
			},
		ship_types.science_disease_research:{ship_stats.ship_name:"Disease Research Lab",
			ship_stats.arrive_effect:[[effect_types.rush, requirement_types.none, effect_targetting_types.all_adjacent, [-3], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [1], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.adjust_science, requirement_types.none, effect_targetting_types.none, [10], x_value_types.none, []]],
				ship_stats.tags:[tags.science], ship_stats.sprite_texture:science_disease_research, ship_stats.ship_size:2, ship_stats.dock_time:3
			},
		ship_types.tinker_carrier:{ship_stats.ship_name:"Mobile Repair Pavilion",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.upgrade_point, requirement_types.none, effect_targetting_types.adjacent_right, [1], x_value_types.none, []],
										[effect_types.remove_tag, requirement_types.none, effect_targetting_types.all_adjacent, [tags.damaged], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				ship_stats.tags:[tags.tinker], ship_stats.sprite_texture:tinker_carrier, ship_stats.ship_size:3, ship_stats.dock_time:4
			},
		ship_types.inspector_incompetent:{ship_stats.ship_name:"Incompetent Engine Inspector",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.inspect, requirement_types.none, effect_targetting_types.all_adjacent, [], x_value_types.none, []],
										[effect_types.add_tag, requirement_types.has_tag_target, effect_targetting_types.adjacent_left, [tags.damaged], x_value_types.none, [tags.inspected]],
										[effect_types.add_tag, requirement_types.has_tag_target, effect_targetting_types.adjacent_right, [tags.damaged], x_value_types.none, [tags.inspected]]],
			ship_stats.depart_effect:[[effect_types.inspection_payout, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []],
										[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [6], x_value_types.none, []]],
				ship_stats.tags:[tags.inspector], ship_stats.sprite_texture:inspector_incompetent, ship_stats.ship_size:1, ship_stats.dock_time:3
			},
		ship_types.explorer_colony_organizer:{ship_stats.ship_name:"Colony Organizer",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [3], x_value_types.ships_with_tag, [tags.explorer]]],
				ship_stats.tags:[tags.explorer], ship_stats.sprite_texture:explorer_colony_organizer, ship_stats.ship_size:2, ship_stats.dock_time:99
			},
		ship_types.meteor_ship:{ship_stats.ship_name:"Meteor Prospector",
			ship_stats.arrive_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
			ship_stats.docked_effect:[[effect_types.give_resource, requirement_types.none, effect_targetting_types.none, [[resource_types.unrefined_metals],[2]], x_value_types.none, []]],
			ship_stats.depart_effect:[[effect_types.none, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []]],
				ship_stats.tags:[tags.explorer, tags.merchant, tags.refinable], ship_stats.sprite_texture:meteor_ship, ship_stats.ship_size:1, ship_stats.dock_time:3
			},
	}
	object_info = {
		object_types.inspector_small:{object_stats.object_name:"Inspection Office", 
			object_stats.effects:[[effect_types.delay, requirement_types.drag_to, effect_targetting_types.none, [1], x_value_types.none, []],
									[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [1], x_value_types.none, []]], 
				object_stats.tags:[tags.inspector], object_stats.sprite_texture:inspector_facility_small, object_stats.object_size:1, object_stats.sell_value:2
				},
		object_types.restaurant_medium:{object_stats.object_name:"Restaurant", 
			object_stats.effects:[[effect_types.add_tag, requirement_types.drag_to, effect_targetting_types.none, [tags.pleased], x_value_types.none, []],
									[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.self_target, [2], x_value_types.each_ship, []]], 
				object_stats.tags:[tags.tourist], object_stats.sprite_texture:restaurant_medium, object_stats.object_size:2, object_stats.sell_value:4
				},
		object_types.science_large:{object_stats.object_name:"Testing Facility",
			object_stats.effects:[[effect_types.adjust_science, requirement_types.none, effect_targetting_types.none, [5], x_value_types.none, []],
									[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [], x_value_types.percent_10_science, []]],
				object_stats.tags:[tags.tourist], object_stats.sprite_texture:science_facility_large, object_stats.object_size:3, object_stats.sell_value:6
				},
		object_types.forge:{object_stats.object_name:"Forge",
			object_stats.effects:[[effect_types.refine_resource, requirement_types.drag_to, effect_targetting_types.none, [resource_types.unrefined_metals], x_value_types.none, []]],
				object_stats.tags:[tags.merchant], object_stats.sprite_texture:forge, object_stats.object_size:2, object_stats.sell_value:4			
				},
		object_types.rush_medium:{object_stats.object_name:"Boost Fueler",
			object_stats.effects:[[effect_types.rush, requirement_types.drag_to, effect_targetting_types.none, [-1], x_value_types.none, []]],
				object_stats.tags:[tags.tinker], object_stats.sprite_texture:rush_facility_medium, object_stats.object_size:2, object_stats.sell_value:4
				},
		object_types.explorer_medium:{object_stats.object_name:"Temporary Homestead",
			object_stats.effects:[[effect_types.get_telemetry, requirement_types.none, effect_targetting_types.none, [], x_value_types.none, []],
									[effect_types.adjust_credits, requirement_types.portal_unexplored, effect_targetting_types.none, [10], x_value_types.none, []]],
				object_stats.tags:[tags.explorer], object_stats.sprite_texture:explorer_facility_medium, object_stats.object_size:2, object_stats.sell_value:4
				},
		object_types.repair_bay:{object_stats.object_name:"Repair Bay",
			object_stats.effects:[[effect_types.remove_tag, requirement_types.drag_to, effect_targetting_types.none, [tags.damaged], x_value_types.none, []],
									[effect_types.adjust_credits, requirement_types.none, effect_targetting_types.none, [2], x_value_types.none, []]],
				object_stats.tags:[tags.tinker], object_stats.sprite_texture:repair_bay, object_stats.object_size:2, object_stats.sell_value:4
				},
	}
	planet_info = {
		planets.explorer_test:["?", "unexplored planet - ships and facilities with 'explorer' tag more common in draft", planet_temperate],
		planets.science_test:["Curiousity", "known planet - ships and facilities with 'science' tag more common in draft", planet_temperate],
		planets.money_test:["Exphor", "known planet - ships and facilities with 'tourist' tag more common in draft", planet_temperate],
		planets.inspector:["Oki", "known planet - ships and facilities with 'inspector' tag more common in draft", planet_temperate],
		planets.tinker:["Kogia", "known planet - ships and facilities with 'tinker' tag more common in draft", planet_temperate],
		planets.merchant:["Vucca", "known planet - ships and facilities with 'merchant' tag more common in draft", planet_temperate],
		planets.small_cards:["Minoris", "known planet - ships and facilities with 'small' tag more common in draft", planet_temperate],
		planets.medium_cards:["Medius", "known planet - ships and facilities with 'medium' tag more common in draft", planet_temperate],
		planets.large_cards:["Maximus", "known planet - ships and facilities with 'large' tag more common in draft", planet_temperate],
	}
	planet_to_pack_type = {
		planets.none:pack_types.ship_all,
		planets.explorer_test:pack_types.explorer,
		planets.science_test:pack_types.science,
		planets.money_test:pack_types.tourist,
		planets.inspector:pack_types.inspector,
		planets.tinker:pack_types.tinker,
		planets.merchant:pack_types.merchant,
		planets.small_cards:pack_types.small,
		planets.medium_cards:pack_types.medium,
		planets.large_cards:pack_types.large,
	}
	resource_info = {
		resource_types.unrefined_metals:{resource_stats.resource_name:"Unrefined Metals", resource_stats.sprite_texture: resource_unrefined_metals, resource_stats.sell_value:1},
		resource_types.refined_metals:{resource_stats.resource_name:"Refined Metals", resource_stats.sprite_texture: resource_refined_metals, resource_stats.sell_value:4},
	}
	resource_refinements = {
		resource_types.unrefined_metals: resource_types.refined_metals
	}
	guild_payment_deadlines_cost = {
		#day #GCr
		2:30, 4:100, 7:400
	}
	upgrade_info = {
		#short name of upgrade, full description, icon
		upgrades.increased_uses:["More uses per shift", "Effects that are activated by dragging another object onto this can be used an additional time per shift", "res://sprites/upgrade_increased_uses.png"],
		upgrades.increased_credits:["More GCr", "Increases the numerical value of a random effect that gives GCr by 2", "res://sprites/upgrade_increased_credits.png"],
		upgrades.increased_science:["More Science", "Increases the numerical value of a random effect that gives Science by 2", "res://sprites/upgrade_increased_science.png"],
		upgrades.increased_sell_price:["Increased sell value", "Increases the sell value of this by 5 GCr", "res://sprites/upgrade_increased_sell_value.png"],
		upgrades.rush_up:["Increased Rush", "Reduces ship docking time by one more", "res://sprites/upgrade_rush_up.png"],
		#upgrades.more_refined:["Refinement Efficiency", "Produces one additional product when refining", "res://sprites/upgradeicon.png"],
		upgrades.more_produced:["Production Efficiency", "Produces one additional product", "res://sprites/upgrade_more_produced.png"],
		upgrades.mobile:["Mobile", "Doesn't need to install before it can be used", "res://sprites/upgrade_mobile.png"],
		upgrades.add_credit_effect:["Add Credit Effect", "Adds a new effect that gives 1 GCr per shift", "res://sprites/upgrade_add_credit_effect.png"],
		upgrades.add_science_effect:["Add Science Effect", "Adds a new effect that gives 1 Science per shift", "res://sprites/upgrade_add_science_effect.png"],
		upgrades.repair:["Add Repair Effect", "Adds a new effect that removes the 'Damaged' tag from adjacent ships", "res://sprites/upgrade_add_repair.png"],
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_random_planets(number_to_get:int):
	var possible_planets = []
	var picked_planets = []
	for each_planet in planets:
		if planets[each_planet] != planets.none:
			possible_planets.append(each_planet)
		if planets[each_planet] == planets.explorer_test:
			possible_planets.append(each_planet)
			possible_planets.append(each_planet)
			possible_planets.append(each_planet)
			possible_planets.append(each_planet)
			possible_planets.append(each_planet)
			possible_planets.append(each_planet)
	for each_num in number_to_get:
		var planet = possible_planets.pick_random()
		picked_planets.append(planet)
		possible_planets.erase(planet)
	return picked_planets
	
func get_possible_upgrades(card:card_object):
	var card_effects = card.get_my_effects()
	var upgrades_to_return = []
	#upgrades available to anyone
	upgrades_to_return.append(upgrades.add_credit_effect)
	upgrades_to_return.append(upgrades.add_science_effect)
	if card.supertype == card_supertypes.facility:
		upgrades_to_return.append(upgrades.increased_sell_price)
	if card.supertype == card_supertypes.ship:
		upgrades_to_return.append(upgrades.repair)
	for each_effect in card_effects:
		var effect_requirement = each_effect.get_requirement()
		var effect_type = each_effect.get_type()
		if effect_requirement == requirement_types.drag_to:
			upgrades_to_return.append(upgrades.increased_uses)
			if card.get_my_upgrades().find(upgrades.mobile) == -1 && card.supertype == card_supertypes.facility:
				#can't take mobile multiple times
				upgrades_to_return.append(upgrades.mobile)
		if effect_type == effect_types.adjust_credits && each_effect.x_value_type != GlobalReference.x_value_types.percent_10_science:
			upgrades_to_return.append(upgrades.increased_credits)
		if effect_type == effect_types.adjust_science:
			upgrades_to_return.append(upgrades.increased_science)
		if effect_type == effect_types.rush:
			upgrades_to_return.append(upgrades.rush_up)
		#if effect_type == effect_types.refine_resource:
			#upgrades_to_return.append(upgrades.more_refined)
		if effect_type == effect_types.give_resource:
			upgrades_to_return.append(upgrades.more_produced)
	return upgrades_to_return
