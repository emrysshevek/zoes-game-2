extends card_object

var arrive_effects:Array #array of the effects
var docked_effects:Array
var depart_effects:Array

var has_docked : bool :
	get:
		return has_docked
	set(new_value):
		has_docked = new_value
		if has_docked == true && docking_status == GlobalReference.ship_docking_statuses.arrived:
			set_docking_status(GlobalReference.ship_docking_statuses.docked)
			
var dock_duration:int:
	set(new_value):
		dock_duration = new_value
		if dock_duration < 1:
			set_docking_status(GlobalReference.ship_docking_statuses.depart)
		elif docking_status == GlobalReference.ship_docking_statuses.docked:
			set_docking_status(GlobalReference.ship_docking_statuses.docked)
		else:
			pass
		
var docking_status:int = GlobalReference.ship_docking_statuses.waiting

var inspection_haul:int = 2

signal upgrade_button_pressed(card_upgrading:card_object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currently_clicked == true && locked == false:
		self.global_position = get_global_mouse_position() - Vector2(my_sprite_object.position.x, my_sprite_object.position.y)


func first_time_setup(ship_type_input:int):
	supertype = GlobalReference.card_supertypes.ship
	my_sprite_object = $ShipSprite
	my_collision_area = $ShipSprite/ShipCollisionArea
	my_info_panel = $ShipInfo
	my_info_panel.panel_first_time_setup(self)
	my_button = $ShipSprite/ShipButton
	my_upgrade_button = $UpgradeButton
	type = ship_type_input
	object_name = GlobalReference.ship_info[type][GlobalReference.ship_stats.ship_name]
	var num_arrive_effects = GlobalReference.ship_info[type][GlobalReference.ship_stats.arrive_effect].size()
	for each_num in num_arrive_effects:
		var new_arrive_effect = Effect.new()
		new_arrive_effect.first_time_effect_setup(GlobalReference.ship_info[type][GlobalReference.ship_stats.arrive_effect][each_num], self)
		arrive_effects.append(new_arrive_effect)
	var num_docked_effects = GlobalReference.ship_info[type][GlobalReference.ship_stats.docked_effect].size()
	for each_num in num_docked_effects:
		var new_docked_effect = Effect.new()
		new_docked_effect.first_time_effect_setup(GlobalReference.ship_info[type][GlobalReference.ship_stats.docked_effect][each_num], self)
		docked_effects.append(new_docked_effect)
	var num_depart_effects = GlobalReference.ship_info[type][GlobalReference.ship_stats.depart_effect].size()
	for each_num in num_depart_effects:
		var new_depart_effect = Effect.new()
		new_depart_effect.first_time_effect_setup(GlobalReference.ship_info[type][GlobalReference.ship_stats.depart_effect][each_num], self)
		depart_effects.append(new_depart_effect)
		
	#doing size and related tags earlier so that tag appears at the front of tag list	
	size = GlobalReference.ship_info[type][GlobalReference.ship_stats.ship_size]
	if size == 1:
		tags.append(GlobalReference.tags.small)
	elif size == 2:
		tags.append(GlobalReference.tags.medium)
	elif size == 3:
		tags.append(GlobalReference.tags.large)
	else:
		print("invalid size:" + str(size))
	#
	#doing first time setup here so the card has the ship size and button ref to use for setup
	card_first_time_setup()
	
	tags.append_array(GlobalReference.ship_info[type][GlobalReference.ship_stats.tags])
	sprite_texture = GlobalReference.ship_info[type][GlobalReference.ship_stats.sprite_texture]
	dock_duration = GlobalReference.ship_info[type][GlobalReference.ship_stats.dock_time]
	var ship_collision_shape = RectangleShape2D.new()
	ship_collision_shape.size = Vector2(128 * size, 128)
	$ShipSprite/ShipCollisionArea/CollisionShape2D.position.x += (size - 1) * 64
	$ShipSprite/ShipCollisionArea/CollisionShape2D.set_shape(ship_collision_shape)
	$ShipSprite/ShipButton.size.x += 128 * (size - 1)
	$ShipSprite/DockingStatusLabel.position = (Vector2(-35 + ((size - 1) * 50), 48))
	set_sprite_texture(sprite_texture)

func set_docking_status(new_status:int):
	if new_status == GlobalReference.ship_docking_statuses.waiting:
		set_color(Color("ffadff"))
		$ShipSprite/DockingStatusLabel.text = "Waiting (Dock time: " + str(dock_duration) + ")"
	elif new_status == GlobalReference.ship_docking_statuses.arrived:
		set_color(Color("d187ce"))
		$ShipSprite/DockingStatusLabel.text = "Arrived"
	elif new_status == GlobalReference.ship_docking_statuses.docked:
		set_color(Color("66e6f5"))
		if dock_duration != 99:
			$ShipSprite/DockingStatusLabel.text = "Docked (" + str(dock_duration) + ")"
		else:
			$ShipSprite/DockingStatusLabel.text = "Docked, waiting for unexplored planet"
	elif new_status == GlobalReference.ship_docking_statuses.depart:
		set_color(Color("806eff"))
		$ShipSprite/DockingStatusLabel.text = "Depart"
	elif new_status == GlobalReference.ship_docking_statuses.draft:
		set_color(Color("ffffffff"))
		$ShipSprite/DockingStatusLabel.text = "Docks for " + str(dock_duration) + " shifts"
	else:
		print("unexpected new docking status: " + str(new_status))
		assert(false)
	docking_status = new_status

func get_resource_buy_effect(resource_type:int):
	var resource_buy_effect = null
	if docking_status == GlobalReference.ship_docking_statuses.docked:
		for each_effect in docked_effects:
			if each_effect.effect_type == GlobalReference.effect_types.buy_resource:
				for each_resource_type in each_effect.resolver_values[0]:
					if each_resource_type == resource_type:
						resource_buy_effect = each_effect
						return resource_buy_effect
	return resource_buy_effect

func adjust_dock_duration(adjust_amt:int):
	if dock_duration != 99: #dock duration 99 indicates an explorer waiting for new planet
		dock_duration += adjust_amt
	elif adjust_amt == -99:
		dock_duration = 0
	else:
		pass
		#print("invalid dock duration change attempt")
	if dock_duration <= 0:
		set_docking_status(GlobalReference.ship_docking_statuses.depart)

func get_my_effects():
	var return_array = []
	for each_effect in arrive_effects:
		return_array.append(each_effect)
	for each_effect in docked_effects:
		return_array.append(each_effect)
	for each_effect in depart_effects:
		return_array.append(each_effect)
	return return_array

func toggle_depart_visuals(departing:bool):
	if departing == true:
		modulate.a = 0.3
	else:
		modulate.a = 1

func adjust_inspection_haul(adjust_amt:int):
	inspection_haul += adjust_amt

func _on_upgrade_button_pressed() -> void:
	upgrade_button_pressed.emit(self)
	toggle_upgrade_button_visibility(false)
