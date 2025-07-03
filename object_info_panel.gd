extends Control

var my_parent_object:card_object

var time_to_live:Timer

signal upgrade_attempt(using_science:bool, resource_type:int, amount_needed:int, facility_attempting_upgrade:card_object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_to_live = Timer.new()
	add_child(time_to_live)
	time_to_live.timeout.connect(_on_time_to_live_loop_finish)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func panel_first_time_setup(parent_object:card_object):
	my_parent_object = parent_object
	if parent_object.supertype != GlobalReference.card_supertypes.facility:
		$Panel/InfoContainer/UpgradeButton.visible = false
	else:
		$Panel/InfoContainer/UpgradeButton.visible = true
	$Panel/InfoContainer.reset_size()
	$Panel.reset_size()

func info_panel_visible(visibility:bool):
	if visibility == true:
		self.visible = true
		var parent_object_size = my_parent_object.size
		if parent_object_size < 2:
			set_panel_width(256)
			adjust_panel_position(Vector2(-64,0))
		else:
			set_panel_width(my_parent_object.size * 128)
			adjust_panel_position(Vector2(0,0))
		time_to_live.start(3)
	else:
		self.visible = false
		
func get_info_panel_visibility():
	return self.visible
	
func update_panel_display(parent_object:card_object):
	#hide the upgrade menu and unhide the info menu
	$Panel/InfoContainer.visible = true
	$Panel/UpgradeContainer.visible = false
	$Panel/InfoContainer/Name.text = parent_object.object_name
	$Panel/InfoContainer/Effects.text = ""
	var tags:String = "- "
	for each_tag in parent_object.tags:
		tags += str(GlobalReference.tags.keys()[each_tag]) + " - "
	$Panel/InfoContainer/Tags.text = tags
	if parent_object.supertype == GlobalReference.card_supertypes.ship:
		var arrive_text:String = ""
		if parent_object.arrive_effects.size() > 1 || parent_object.arrive_effects[0].effect_type != GlobalReference.effect_types.none:
			arrive_text = "On Arrival: "
			for each_arrive_effect in parent_object.arrive_effects:
				arrive_text += each_arrive_effect.get_description() + "\n"
			$Panel/InfoContainer/Effects.text += arrive_text + "\n"
		var docked_text:String = ""
		if parent_object.docked_effects.size() > 1 || parent_object.docked_effects[0].effect_type != GlobalReference.effect_types.none:
			docked_text = "Each turn while Docked (" + str(parent_object.dock_duration) + "): "
			for each_docked_effect in parent_object.docked_effects:
				docked_text += each_docked_effect.get_description() + "\n"
			$Panel/InfoContainer/Effects.text += docked_text + "\n"
		var depart_text:String = ""
		if parent_object.depart_effects.size() > 1 || parent_object.depart_effects[0].effect_type != GlobalReference.effect_types.none:
			depart_text = "On Departure: "
			for each_depart_effect in parent_object.depart_effects:
				depart_text += each_depart_effect.get_description() + "\n"
			$Panel/InfoContainer/Effects.text += depart_text
	elif parent_object.supertype == GlobalReference.card_supertypes.facility:
		var effect_text:String = ""
		for each_effect in parent_object.effects:
			effect_text += each_effect.get_description() + " - "
		$Panel/InfoContainer/Effects.text += effect_text
		if parent_object.upgrade_level >= 5:
			$Panel/InfoContainer/UpgradeButton.visible = false
	elif parent_object.supertype == GlobalReference.card_supertypes.resource:
		pass
	else:
		print("unrecognized parent card supertype")
		assert(false)
	#var upgrades = parent_object.get_my_upgrades()
	#for each_upgrade in upgrades:
		#var new_texture_rect = TextureRect.new()
		#new_texture_rect.custom_minimum_size = Vector2(40,40)
		#new_texture_rect.texture = load(GlobalReference.upgrade_info[each_upgrade][2])
		#$Panel/InfoContainer/UpgradeIconContainer.add_child(new_texture_rect)
	
	
func get_panel_bounds():
	return $Panel.size
	
func set_panel_width(set_width:int):
	$Panel.size.x = set_width
	$Panel/InfoContainer/Name.custom_minimum_size.x = set_width - 27
	$Panel/InfoContainer/Tags.custom_minimum_size.x = set_width - 27
	$Panel/InfoContainer/Effects.custom_minimum_size.x = set_width - 27

func adjust_panel_position(move_to:Vector2):
	$Panel.position = move_to

func update_upgrade_container_text():
	$Panel/UpgradeContainer/UpgradeCost.text = "Upgrade Progress " + str(my_parent_object.upgrade_progress) + "/" + str(my_parent_object.upgrade_level + 2)
	$Panel/UpgradeContainer/HBoxContainer/ResourceUpgradeButton.text = "1 Refined Metal"
	$Panel/UpgradeContainer/HBoxContainer/ScienceUpgradeButton.text = "5 Science"

func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()

#func _on_panel_right_click_button_gui_input(event: InputEvent) -> void:
	#if event.is_action_pressed("mouse_button_right_down"):
		#info_panel_visible(false)
		
func _on_upgrade_button_pressed() -> void:
	$Panel/InfoContainer.visible = !$Panel/InfoContainer.visible
	$Panel/UpgradeContainer.visible = !$Panel/UpgradeContainer.visible
		
func _on_upgrade_container_visibility_changed() -> void:
	update_upgrade_container_text()

func _on_resource_upgrade_button_pressed() -> void:
	upgrade_attempt.emit(my_parent_object, false, GlobalReference.resource_types.refined_metals, 1)
	update_upgrade_container_text()

func _on_science_upgrade_button_pressed() -> void:
	upgrade_attempt.emit(my_parent_object, true, null, 5)
	update_upgrade_container_text()

func _on_panel_mouse_exited() -> void:
	if $Panel/UpgradeContainer.visible == false:
		info_panel_visible(false)
		deconstruct()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_button_right_down"):
		info_panel_visible(false)
		deconstruct()

func _on_time_to_live_loop_finish():
	var panel_rect = Rect2(Vector2($Panel.global_position), $Panel.size)
	if panel_rect.has_point(get_global_mouse_position()) == false:
		info_panel_visible(false)
		deconstruct()
