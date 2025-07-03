extends Control

@export var facility_object_scene:PackedScene

var current_card_upgrading

var card_buttons_to_options:Dictionary

signal upgrade_selected(card_upgrading:card_object, upgrade_type:int)
signal planet_selected(planet_type:int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up_planet_cards(number_of_planets_needed:int):
	var planets = GlobalReference.get_random_planets(number_of_planets_needed)
	for each_planet in planets:
		create_card(GlobalReference.planet_info[GlobalReference.planets[each_planet]][0], GlobalReference.planet_info[GlobalReference.planets[each_planet]][1], GlobalReference.planet_info[GlobalReference.planets[each_planet]][2], GlobalReference.planets[each_planet])

func set_up_upgrade_cards(card_upgrading:card_object, number_of_upgrades_max:int):
	current_card_upgrading = card_upgrading
	var possible_upgrades = GlobalReference.get_possible_upgrades(card_upgrading)
	for each_num in number_of_upgrades_max:
		var random_upgrade = possible_upgrades.pick_random()
		var upgrade = GlobalReference.upgrades.keys()[random_upgrade]
		create_card(GlobalReference.upgrade_info[GlobalReference.upgrades[upgrade]][0], GlobalReference.upgrade_info[GlobalReference.upgrades[upgrade]][1], GlobalReference.upgrade_info[GlobalReference.upgrades[upgrade]][2], GlobalReference.upgrades[upgrade])
		possible_upgrades.erase(random_upgrade)

func create_card(card_title:String, card_description:String, card_sprite_string:String, linked_option:int):
	var left_separate = VSeparator.new()
	left_separate.custom_minimum_size = Vector2(30,0)
	left_separate.theme = load("res://InfoPanelTheme.tres")
	$CenterContainer/CardsContainer.add_child(left_separate)
	var card_panel_container = PanelContainer.new()
	$CenterContainer/CardsContainer.add_child(card_panel_container)
	var card_content_container = VBoxContainer.new()
	card_panel_container.add_child(card_content_container)
	var card_title_label = Label.new()
	card_title_label.theme = load("res://medium_text_size.tres")
	card_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_title_label.text = card_title
	card_content_container.add_child(card_title_label)
	var sprite_bkgd = ColorRect.new()
	sprite_bkgd.custom_minimum_size = Vector2(200,200)
	sprite_bkgd.color = Color("272727")
	sprite_bkgd.mouse_filter = Control.MOUSE_FILTER_PASS
	card_content_container.add_child(sprite_bkgd)
	var card_sprite = Sprite2D.new()
	card_sprite.texture = load(card_sprite_string)
	card_content_container.add_child(card_sprite)
	card_sprite.position = sprite_bkgd.position + Vector2(100,150)
	var card_description_label = Label.new()
	card_description_label.theme = load("res://small_text_size.tres")
	card_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_description_label.text = card_description
	card_content_container.add_child(card_description_label)
	var card_button = Button.new()
	card_panel_container.add_child(card_button)
	card_button.self_modulate = Color("00000042")
	card_button.pressed.connect(_on_button_pressed.bind(card_button))
	var right_separate = VSeparator.new()
	right_separate.custom_minimum_size = Vector2(30,0)
	right_separate.theme = load("res://InfoPanelTheme.tres")
	$CenterContainer/CardsContainer.add_child(right_separate)
	card_buttons_to_options[card_button] = linked_option

func toggle_visible(visib:bool):
	if visib == true:
		self.visible = true
	else:
		self.visible = false

func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()

func _on_button_pressed(button:Button):
	if current_card_upgrading != null:
		upgrade_selected.emit(current_card_upgrading, card_buttons_to_options[button])
	else:
		planet_selected.emit(card_buttons_to_options[button])

#func _on_option_button_pressed() -> void:
	#if current_card_upgrading != null:
		#upgrade_selected.emit(current_card_upgrading, 0)
	#else:
		#planet_selected.emit(GlobalReference.planets.explorer_test)
