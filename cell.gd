extends Sprite

const DEAD = 0
const BORN = 1
const SURVIVED = 2

var state: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_state(new_state):
	state = new_state
	match state:
		DEAD: 
			self.self_modulate = Color.white
		BORN:
			self.self_modulate = Color.blue
		SURVIVED:
			self.self_modulate = Color.black

func toggle_state():
	if state == DEAD:
		set_state(SURVIVED)
	else:
		set_state(DEAD)