extends card_object

var effects:Array #array of the effects o

var has_been_installed:bool = false

var mobile:bool = false

var sell_value:int

signal facility_upgrade_attempt(facility:card_object, using_science:bool, resource_type:int, amount_needed:int)
signal upgrade_button_pressed(card_upgrading:card_object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currently_clicked == true && locked == false:
		self.global_position = get_global_mouse_position() - Vector2(my_sprite_object.position.x, my_sprite_object.position.y)


func first_time_setup(facility_type_input:int):
	supertype = GlobalReference.card_supertypes.facility
	my_sprite_object = $FacilityObjectSprite
	my_collision_area = $FacilityObjectSprite/FacilityObjectCollisionArea
	my_info_panel = $InfoPanel
	my_info_panel.panel_first_time_setup(self)
	my_info_panel.upgrade_attempt.connect(_on_info_panel_upgrade_signal)
	my_button = $FacilityObjectSprite/Button
	my_upgrade_button = $UpgradeButton
	type = facility_type_input
	object_name = GlobalReference.object_info[type][GlobalReference.object_stats.object_name]
	var new_effects = GlobalReference.object_info[type][GlobalReference.object_stats.effects].size()
	for each_num in new_effects:
		var new_effect = Effect.new()
		new_effect.first_time_effect_setup(GlobalReference.object_info[type][GlobalReference.object_stats.effects][each_num], self)
		effects.append(new_effect)
	
	sell_value = GlobalReference.object_info[type][GlobalReference.object_stats.sell_value]
	
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
		
	tags.append_array(GlobalReference.object_info[type][GlobalReference.object_stats.tags])
	sprite_texture = GlobalReference.object_info[type][GlobalReference.object_stats.sprite_texture]
	size = GlobalReference.object_info[type][GlobalReference.object_stats.object_size]
	var object_collision_shape = RectangleShape2D.new()
	object_collision_shape.size = Vector2(128 * size, 128)
	$FacilityObjectSprite/FacilityObjectCollisionArea/CollisionShape2D.position.x += (size - 1) * 64
	$FacilityObjectSprite/FacilityObjectCollisionArea/CollisionShape2D.set_shape(object_collision_shape)
	$FacilityObjectSprite/Button.size.x += 128 * (size - 1)
	set_sprite_texture(sprite_texture)

func install_in_facility_zone():
	has_been_installed = true
	set_color(Color("86f5c8d2"))

func get_my_effects():
	var return_array = []
	for each_effect in effects:
		return_array.append(each_effect)
	return return_array

func _on_info_panel_upgrade_signal(using_science, resource_type, amount_needed):
	facility_upgrade_attempt.emit(self, using_science, resource_type, amount_needed)

func _on_upgrade_button_pressed() -> void:
	upgrade_button_pressed.emit(self)
	toggle_upgrade_button_visibility(false)
