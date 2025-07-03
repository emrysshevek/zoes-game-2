extends Control

signal game_over()
signal proceed_out_of_payment_screen(new_player_credit_total:int)

var player_remaining_credits_post_payment:int = 0

var my_sound_effects:AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_sound_effects = AudioStreamPlayer2D.new()
	add_child(my_sound_effects)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up_payment_screen(amount_due:int, player_credits:int):
	$PaymentLabel.text = "Payment Due: " + str(amount_due) + "GCr"
	$YourCreditsLabel.text = "Your Credits: " + str(player_credits) + "GCr"
	if amount_due > player_credits:
		$ResultLabel.text = "Insufficient Credits. Resigning."
		$GameOverButton.visible = true
		my_sound_effects.stream = load("res://sounds/game_over.wav")
		my_sound_effects.play(0)
	else:
		$ResultLabel.text = "Credits remaining: " + str((player_credits - amount_due)) + "GCr"
		my_sound_effects.stream = load("res://sounds/start.wav")
		my_sound_effects.play(0)
		$PayButton.visible = true
		player_remaining_credits_post_payment = player_credits - amount_due


func _on_pay_button_pressed() -> void:
	proceed_out_of_payment_screen.emit(player_remaining_credits_post_payment)
	deconstruct()


func _on_game_over_button_pressed() -> void:
	game_over.emit()

func deconstruct():
	self.set_deferred("disabled", true)	
	self.queue_free()
