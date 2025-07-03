class_name card_object extends Node2D

var supertype:int
var type:int
var object_name:String
var tags:Array
var sprite_texture:String
var size:int

var currently_clicked:bool = false:
	set(new_value):
		if new_value == true:
			hover_timer.stop()
		currently_clicked = new_value

var draw_source_ghost:bool = false

var per_shift_effect_uses_left:int = 1:
	set(new_value):
		if supertype == GlobalReference.card_supertypes.facility:
			if new_value > 0:
				set_color(Color("86f5c8d2"))
			else:
				set_color(Color("5f818cd2"))
		per_shift_effect_uses_left = new_value
var per_shift_effect_uses_max:int = 1

var upgrade_level:int = 0 #ships only use this, not progress
var upgrade_progress:int = 0 #progress needed to level up is upgrade_level + 2
var upgrades = [] #array of the upgrad enum values, in no real order

var my_sound_effects:AudioStreamPlayer2D

var my_sprite_object
var my_collision_area
var my_info_panel
var my_button
var my_upgrade_button #only used for ships and facilities
var hover_timer:Timer

var locked:bool = false #indicates if this 'card' can be moved by mouse interaction

var active_tween_to_label:Dictionary

var scene_exit_queued:bool = false

var my_upgrade_icon_container:HBoxContainer

signal object_released(object_entity:card_object)
signal object_clicked(object_entity:card_object)
signal object_hovered(object_entity:card_object)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func card_first_time_setup():
	#these should only be for items that could apply to all 3 card types
	my_upgrade_icon_container = HBoxContainer.new()
	add_child(my_upgrade_icon_container)
	my_upgrade_icon_container.position.y = 88 #128 (everythings height) - 40 for upgrade icon tile
	my_sound_effects = AudioStreamPlayer2D.new()
	add_child(my_sound_effects)
	my_button.gui_input.connect(_on_button_gui_input)
	my_button.mouse_entered.connect(_on_button_mouse_entered)
	my_button.mouse_exited.connect(_on_button_mouse_exited)
	hover_timer = Timer.new()
	add_child(hover_timer)
	hover_timer.timeout.connect(_on_hover_timer_timeout)

func get_size():
	return size

func set_sprite_texture(texture_to_set:String):
	my_sprite_object.texture = load(texture_to_set)
	my_info_panel.set_panel_width(my_sprite_object.texture.get_width())
	
func set_color(new_color:Color):
	my_sprite_object.modulate = new_color

func set_info_panel_visibility(visibility:bool):
	update_my_panel_info()
	if visibility == true:
		my_info_panel.info_panel_visible(true)
		my_info_panel.position.y = (my_info_panel.get_panel_bounds().y - 128) * -1
	else:
		my_info_panel.info_panel_visible(false)
		
func get_info_panel_visibility():
	return my_info_panel.get_info_panel_visibility()

func update_my_panel_info():
	my_info_panel.update_panel_display(self)

func get_my_collision_area():
	return my_collision_area
	
func get_my_sprite_texture():
	return my_sprite_object.texture
	
func get_my_sprite_modulate():
	return my_sprite_object.modulate

func get_my_tags():
	return tags
	
func get_my_upgrades():
	return upgrades

func add_upgrade(upgrade_enum:int):
	upgrades.append(upgrade_enum)
	var new_texture_rect = TextureRect.new()
	new_texture_rect.custom_minimum_size = Vector2(40,40)
	new_texture_rect.texture = load(GlobalReference.upgrade_info[upgrade_enum][2])
	my_upgrade_icon_container.add_child(new_texture_rect)

func toggle_upgrade_button_visibility(visibility:bool):
	if visibility == true:
		my_upgrade_button.visible = true
	else:
		my_upgrade_button.visible = false
		
func add_tags(tags_to_add:Array):
	for each_tag in tags_to_add:
		if self.tags.find(each_tag) == -1:
			#if the tag to be added isn't already in the tag list..
			tags.append(each_tag)
			
func remove_tags(tags_to_remove:Array):
	for each_tag in tags_to_remove:
		tags.erase(each_tag)

func get_my_pop_up_location():
	return Vector2(self.global_position.x - (self.get_size() * 64), self.global_position.y)

#func play_effect_pop_up(delay_ms:int, triggering_effect:Effect, preview:bool):
	#var pop_up_tween = get_tree().create_tween()
	#var pop_up_text_label = Label.new()
	#pop_up_text_label.visible = false
	#pop_up_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#pop_up_text_label.set_theme(load("res://pop_up_text_theme.tres"))
	#add_child(pop_up_text_label)
	#pop_up_tween.finished.connect(_on_pop_up_tween_finish)
	#active_tween_to_label[pop_up_tween] = pop_up_text_label
	##set text position to upper center middle of sprite
	#var text_label_starting_position = Vector2((self.size * 128) / 2, 128 - 100 - (25 * active_tween_to_label.size()) )
	#pop_up_text_label.position = text_label_starting_position
	#var text_to_set:String
	#var color_to_set:Color
	#if triggering_effect.effect_type == GlobalReference.effect_types.adjust_credits:
		#if triggering_effect.x_value_type == GlobalReference.x_value_types.percent_10_science:
			#pass
		#else:
			#text_to_set = str(triggering_effect.resolver_values[0]) + "GCr"
		#color_to_set = Color("#dec523")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.add_tag:
		#text_to_set = str(GlobalReference.tags.keys()[triggering_effect.resolver_values[0]]) + " tag added"
		#color_to_set = Color("#3ce8ba")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.remove_tag:
		#text_to_set = str(GlobalReference.tags.keys()[triggering_effect.resolver_values[0]]) + " tag removed"
		#color_to_set = Color("#e04a90")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.rush:
		#text_to_set = "Ship rushed " + str(abs(triggering_effect.resolver_values[0]))
		#color_to_set = Color("#3ce8ba")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.give_resource:
		#text_to_set = str(GlobalReference.resource_types.keys()[triggering_effect.resolver_values[0][0]]) + " added to storage"
		#color_to_set = Color("#b59b5b")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.buy_resource:
		#text_to_set = "Bought " + str(GlobalReference.resource_types.keys()[triggering_effect.resolver_values[0][0]]) + " for " + str(triggering_effect.resolver_values[1][0])
		#color_to_set = Color("#dec523")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.refine_resource:
		#text_to_set = "Resource refined"
		#color_to_set = Color("#b59b5b")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.adjust_science:
		#text_to_set = str(triggering_effect.resolver_values[0]) + " Science"
		#color_to_set = Color("#3769bf")
	#elif triggering_effect.effect_type == GlobalReference.effect_types.inspection_payout:
		#text_to_set = str(triggering_effect.source.inspection_haul) + "GCr"
		#color_to_set = Color("#dec523")
	##do we need these for delay and inspect?
	##, delay, inspect, }
	#pop_up_text_label.text = text_to_set
	#pop_up_text_label.visible = true
	#pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(text_label_starting_position.x, text_label_starting_position.y - 100), 1)
	#pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", color_to_set, 1)
	#pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(text_label_starting_position.x, text_label_starting_position.y - 200), 1)
	#pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", Color("ffffff00"), 1)
	#if preview == false:
		#pop_up_tween.tween_property(pop_up_text_label, "visible", false, 1)
		#pop_up_tween.parallel().tween_property(pop_up_text_label, "position", Vector2(text_label_starting_position.x, text_label_starting_position.y), 1)
	#pop_up_tween.finished.emit()

#func play_non_effect_pop_up(delay_ms:int, pop_up_text:String, text_color:Color):
	#var pop_up_tween = get_tree().create_tween()
	#var pop_up_text_label = Label.new()
	#pop_up_text_label.visible = false
	#pop_up_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#pop_up_text_label.set_theme(load("res://pop_up_text_theme.tres"))
	#add_child(pop_up_text_label)
	#pop_up_tween.finished.connect(_on_pop_up_tween_finish)
	#active_tween_to_label[pop_up_tween] = pop_up_text_label
	##set text position to upper center middle of sprite
	#var text_label_starting_position = Vector2((self.size * 128) / 2, 128 - 100 - (25 * active_tween_to_label.size()) )
	#pop_up_text_label.position = text_label_starting_position
	#var text_to_set:String = pop_up_text
	#var color_to_set:Color = text_color
	#pop_up_text_label.text = text_to_set
	#pop_up_text_label.visible = true
	#pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(text_label_starting_position.x, text_label_starting_position.y - 100), 1)
	#pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", color_to_set, 1)
	#pop_up_tween.tween_property(pop_up_text_label, "position", Vector2(text_label_starting_position.x, text_label_starting_position.y - 200), 1)
	#pop_up_tween.parallel().tween_property(pop_up_text_label, "modulate", Color("ffffff00"), 1)
	#pop_up_tween.finished.emit()
	
func adjust_upgrade_progress(amount:int):
	#facilities use this
	upgrade_progress += amount
	if upgrade_progress >= upgrade_level + 2:
		add_upgrade_level(1)
		upgrade_progress = 0
	else:
		pass
		#play_non_effect_pop_up(1, "Upgrade Progress: " + str(upgrade_progress) + "/" + str(upgrade_level + 2), Color("66e6f5"))

func add_upgrade_level(number_of_levels_to_add:int):
	#ships and facilities use this
	upgrade_level += number_of_levels_to_add
	#play_non_effect_pop_up(1, "Ready to upgrade", Color("66e6f5"))
	if upgrade_level > 5:
		upgrade_level = 5
	else:
		toggle_upgrade_button_visibility(true)
	
func queue_exit_scene():
	visible = false
	scene_exit_queued = true
	
func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()
	
func _on_button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_button_left_down") && locked == false:
		currently_clicked = true
		my_sound_effects.stream = load("res://sounds/click.wav")
		my_sound_effects.play(0)
		object_clicked.emit(self)
	elif event.is_action_released("mouse_button_left_down"):
		if currently_clicked == true:
			currently_clicked = false
			my_sound_effects.stream = load("res://sounds/unclick.wav")
			my_sound_effects.play(0)
			object_released.emit(self)
			_on_button_mouse_entered()
		else:
			pass

func _on_button_mouse_entered():
	#if this object is not currently clicked then start a timer before showingg the info panel
	if currently_clicked == false:
		hover_timer.start(0.5)
		#after timer has expired check if cursor is still over this button
		#if it is, pop up the info panel
			#check every 1 second or so if mouse is still within this button. if so, keep timer and info panel up
		#otherwise mouse has exited this button and timer and this process should end
	#if object is currently clicked do nothing
	
func _on_button_mouse_exited():
	hover_timer.stop()
	#set_info_panel_visibility(false)
	
func _on_hover_timer_timeout():
	#set_info_panel_visibility(true)
	object_hovered.emit(self)
	hover_timer.stop()

#func _on_pop_up_tween_finish():
	#var tweens_to_remove = []
	#for each_tween in active_tween_to_label.keys():
		#if each_tween.is_running() == false:
			#tweens_to_remove.append(each_tween)
	#for each_tween_to_remove in tweens_to_remove:
		#active_tween_to_label[each_tween_to_remove].set_deferred("disabled", true)	
		#active_tween_to_label[each_tween_to_remove].queue_free()
		#active_tween_to_label.erase(each_tween_to_remove)
	##if scene_exit_queued == true:
		##deconstruct()
