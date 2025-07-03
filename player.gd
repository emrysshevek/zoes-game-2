class_name player_entity extends Node

var credits = 0
var science = 0

var day:int = 1
var shift:int = 1 #1-3
var phase:int = GlobalReference.turn_phases.drafting #turn_phases enum
var next_guild_payment_day = 2

var shifts_until_new_planet:int

var card_upgrades_max = 3
var planet_picks_max = 3

var has_portal_telemetry:bool = false

var current_planet:int = 0 #references planet enum in global reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func adjust_credits(adjust_amount:int):
	credits += adjust_amount

func adjust_science(adjust_amount:int):
	science += adjust_amount

func change_phase(new_phase:int):
	phase = new_phase
	
func random_shifts_till_new_planet():
	var possibility_array = [3,4,4,5,5,5,6,6,6,7,7,8]
	shifts_until_new_planet = possibility_array.pick_random()
	
func set_has_telemetry(has_it:bool):
	if has_it == true:
		has_portal_telemetry = true
	else:
		has_portal_telemetry = false
	
func next_shift():
	shift += 1
	shifts_until_new_planet -= 1
	if shift > 3:
		shift = 1
		day += 1
