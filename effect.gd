class_name Effect extends Node

var resolver_values:Array #array of the values to be used in resolving the effect
var effect_type:int #enum identifying the effect, so the resolver knows what to do
var requirement:int #enum identifying the requirement to check before resolving the effect
var effect_targetting_type:int #enum identifying what targets should be added to 'targets' array when trying to resolve this effect
var targets:Array #the target(s) that will apply the effect IF the effect requirements are met.
				#targets each check that they meet the requirements independently before resolving effect
var x_value_type:int #enum identifying if there is an x value in this effect, and how to calculate it
var requirement_values:Array #used for numerical or string requirements to identify specific values for the req to look for
var source:card_object

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func first_time_effect_setup(setup_values:Array, source_object:card_object):
	effect_type = setup_values[0]
	requirement = setup_values[1]
	effect_targetting_type = setup_values[2]
	resolver_values.append_array(setup_values[3])
	x_value_type = setup_values[4]
	requirement_values.append_array(setup_values[5])
	source = source_object

func get_description():
	var source_object_type:String
	var description_text:String = ""
	if source.supertype == GlobalReference.card_supertypes.ship:
		source_object_type = "ship"
	else:
		source_object_type = "facility or storage"
		if requirement != GlobalReference.requirement_types.drag_to:
			description_text += "Each shift: "
	##requirements
	if requirement == GlobalReference.requirement_types.none:
		pass
	elif requirement == GlobalReference.requirement_types.adjacent_both:
		description_text += "If I am next to two " + source_object_type + "(s): "
	elif requirement == GlobalReference.requirement_types.adjacent_left:
		if source.type == GlobalReference.ship_types.snooty_traveller:
			description_text += "Otherwise, I will not be pleased"
		else:
			description_text += "If there is a " + source_object_type + " to my left: "
	elif requirement == GlobalReference.requirement_types.adjacent_right:
		if source.type == GlobalReference.ship_types.snooty_traveller:
			pass
		else:
			description_text += "If there is a " + source_object_type + " to my right: "
	elif requirement == GlobalReference.requirement_types.adjacent_none:
		description_text += "If there is nothing next to me: "
	elif requirement == GlobalReference.requirement_types.has_tag_self:
		if source.type == GlobalReference.ship_types.snooty_traveller:
			description_text += "If pleased: "
		else:
			description_text += "If I have tag " + str(GlobalReference.tags.keys()[requirement_values[0]]) + ": " 
	elif requirement == GlobalReference.requirement_types.drag_to:
		description_text += "(Click + Drag object here) "
	elif requirement == GlobalReference.requirement_types.has_tag_target:
		if source.type == GlobalReference.ship_types.inspector_incompetent && effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_left:
			description_text += "Then add 'damaged' tag (damaged ships can't be rushed) to both adjacent ships"
		elif source.type == GlobalReference.ship_types.inspector_incompetent && effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_right:
			pass
		else:
			description_text += "If my target(s) have tag " +  str(GlobalReference.tags.keys()[requirement_values[0]]) + ": "
	elif requirement == GlobalReference.requirement_types.portal_unexplored:
		description_text += "If the current portal planet is 'unexplored':"
	else:
		print("unexpected requirement type: " + str(requirement))
		assert(false)
	##effects
	if effect_type == GlobalReference.effect_types.adjust_credits:
		if x_value_type != GlobalReference.x_value_types.percent_10_science:
			description_text += "Gain " + str(resolver_values[0]) + " GCr"
		else:
			description_text += "Gain GCr"
	elif effect_type == GlobalReference.effect_types.add_tag:
		if source.type == GlobalReference.ship_types.inspector_incompetent == true:
			pass
		else:
			description_text += "Gain tag " + str(GlobalReference.tags.keys()[resolver_values[0]])
	elif effect_type == GlobalReference.effect_types.remove_tag:
		if source.type == GlobalReference.ship_types.snooty_traveller:
			pass
		else:
			description_text += "Remove tag " + str(GlobalReference.tags.keys()[resolver_values[0]])
	elif effect_type == GlobalReference.effect_types.give_resource:
		if source.type == GlobalReference.ship_types.meteor_ship:
			description_text += "This ship can be refined into 1 refined metal.\n"
		description_text += "Gain:"
		var resource_dictionary:Dictionary
		for each_resource_type in resolver_values[0]:
			var random_stack_value = resolver_values[1].pick_random()
			resource_dictionary[each_resource_type] = random_stack_value
			description_text += " " + str(random_stack_value) + " " + str(GlobalReference.resource_types.keys()[each_resource_type])
	elif effect_type == GlobalReference.effect_types.buy_resource:
		description_text += "Buying:"
		var resource_dictionary:Dictionary
		for each_resource_type in resolver_values[0]:
			description_text += " " + str(GlobalReference.resource_types.keys()[each_resource_type]) + " @" + str(resolver_values[1][0]) + " each"
	elif effect_type == GlobalReference.effect_types.refine_resource:
		description_text += "Refines " + str(GlobalReference.resource_types.keys()[resolver_values[0]]) + " into " + str(GlobalReference.resource_types.keys()[GlobalReference.resource_refinements[resolver_values[0]]])
	elif effect_type == GlobalReference.effect_types.rush:
		description_text += "Rush (decrease dock duration by " + str(abs(resolver_values[0])) + ")"
	elif effect_type == GlobalReference.effect_types.adjust_science:
		description_text += "Gain " + str(resolver_values[0]) + " Science"
	elif effect_type == GlobalReference.effect_types.delay:
		description_text += "Delay (increase dock duration by " + str(resolver_values[0]) + ")"
	elif effect_type == GlobalReference.effect_types.inspect:
		description_text += "Inspect (apply Inspected tag)"
	elif effect_type == GlobalReference.effect_types.inspection_payout:
		description_text += "Gain 2GCr. This number doubles for each successful inspection by this ship: " + str(source.inspection_haul) + "GCr currently"
	elif effect_type == GlobalReference.effect_types.upgrade_random:
		description_text += "Add " + str(resolver_values[0]) +" random upgrade"
	elif effect_type == GlobalReference.effect_types.upgrade_point:
		description_text += "Add " + str(resolver_values[0]) + " upgrade point(s)"
	elif effect_type == GlobalReference.effect_types.get_telemetry:
		description_text += "Get Telemetry (know number of turns until a new portal planet can be selected)"
	elif effect_type == GlobalReference.effect_types.none:
		description_text += ""
	else:
		print("unexpected effect type: " + str(effect_type))
		assert(false)
	#targetting types
	if effect_targetting_type == GlobalReference.effect_targetting_types.all_adjacent:
		description_text += " -> both adjacent " + source_object_type + "s. "
	elif effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_left:
		if source.type == GlobalReference.ship_types.inspector_incompetent:
			pass
		else:
			description_text += " -> " + source_object_type + " to the left. "
	elif effect_targetting_type == GlobalReference.effect_targetting_types.adjacent_right:
		if source.type == GlobalReference.ship_types.inspector_incompetent:
			pass
		else:
			description_text += " -> " + source_object_type + " to the right. "
	elif effect_targetting_type == GlobalReference.effect_targetting_types.self_target:
		pass
	elif effect_targetting_type == GlobalReference.effect_targetting_types.random_ship_inspect:
		description_text += " -> a random ship. "
	elif effect_targetting_type == GlobalReference.effect_targetting_types.none:
		pass
	else:
		print("unexpected effect targetting type: " + str(effect_targetting_type))
		assert(false)
	#x value types
	if x_value_type == GlobalReference.x_value_types.each_ship:
		description_text += " for each ship in port"
	elif x_value_type == GlobalReference.x_value_types.each_facility:
		description_text += " for each installed facility"
	elif x_value_type == GlobalReference.x_value_types.ships_with_tag:
		description_text += " for each ship with " + str(GlobalReference.tags.keys()[requirement_values[0]]) + " tag"
	elif x_value_type == GlobalReference.x_value_types.percent_10_science:
		description_text += " equal to 10% (rounded down) of your current Science"
	elif x_value_type == GlobalReference.x_value_types.none:
		pass
	else:
		print("unexpected x value type: " + str(x_value_type))
		assert(false)
	return description_text

func get_requirement():
	return requirement
	
func get_type():
	return effect_type
