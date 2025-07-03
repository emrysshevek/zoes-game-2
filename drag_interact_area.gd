extends Area2D

var sell_value:int = 0

var linked_effect:Effect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func link_to_effect(effect_to_link_to:Effect):
	linked_effect = effect_to_link_to

func set_bounds(bounds:Vector2):
	var collision_shape = RectangleShape2D.new()
	collision_shape.size = bounds
	$InteractAreaCollision.set_shape(collision_shape)
	$InteractAreaCollision.position += Vector2(64,0)
	$InteractAreaBG.size = bounds
	$InteractAreaText.size = bounds

func set_text(new_text:String):
	$InteractAreaText.text = new_text

func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()
