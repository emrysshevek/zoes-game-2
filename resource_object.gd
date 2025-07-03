extends card_object

var sell_value:int 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currently_clicked == true && locked == false:
		self.global_position = get_global_mouse_position() - Vector2(my_sprite_object.position.x, my_sprite_object.position.y)

func first_time_setup(resource_type_input:int):
	supertype = GlobalReference.card_supertypes.resource
	my_sprite_object = $ResourceObjectSprite
	my_collision_area = $ResourceObjectSprite/ResourceObjectArea
	my_info_panel = $ObjectInfoPanel
	my_info_panel.panel_first_time_setup(self)
	my_button = $ResourceObjectSprite/Button
	type = resource_type_input
	object_name = GlobalReference.resource_info[type][GlobalReference.resource_stats.resource_name]
	sell_value = GlobalReference.resource_info[type][GlobalReference.resource_stats.sell_value]
	size = 1
	card_first_time_setup()
	sprite_texture = GlobalReference.resource_info[type][GlobalReference.resource_stats.sprite_texture]
	var object_collision_shape = RectangleShape2D.new()
	object_collision_shape.size = Vector2(128 * size, 128)
	$ResourceObjectSprite/ResourceObjectArea/ResourceObjectCollisionShape.position.x += (size - 1) * 64
	$ResourceObjectSprite/ResourceObjectArea/ResourceObjectCollisionShape.set_shape(object_collision_shape)
	$ResourceObjectSprite/Button.size.x += 128 * (size - 1)
	set_sprite_texture(sprite_texture)
