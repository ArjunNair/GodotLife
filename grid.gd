extends Node2D

onready var cell_scn = preload("res://cell.tscn")
onready var run_button = get_node("../Control/RunButton")
onready var rule_text = get_node("../Control/Rule/Value")
onready var generation_text = get_node("../Control/Generation/Value")
onready var rule_dialog = get_node("../Control/RuleDialog")
onready var speed_slider = get_node("../Control/Speed/Slider")
export (Vector2) var grid_size = Vector2(100,100)
export (Vector2) var cell_dim = Vector2(16, 16)
export (bool) var debug = false

export var iteration_speed = 1.0

var grid_dim_x
var grid_dim_y
var grid = []
var grid_state = []
var state_index = 0
var generation = 0
var birth_rule: String
var survive_rule: String
var is_running = false
var curr_time = 0
var step_once = false
var rules
var DEFAULT_RULE = "B3/S23"
var regex = RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	regex.compile("B[1-9]+/S[1-9]+")
	grid_dim_x = int(grid_size.x)
	grid_dim_y = int(grid_size.y)
	grid_state.append([])
	grid_state.append([])
	rules = DEFAULT_RULE
	rule_text.text = rules

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell = cell_scn.instance()
			self.add_child(cell)
			cell.position = Vector2(x * cell_dim.x, y * cell_dim.y)
			cell.set_state(0)
			grid.append(cell)
			grid_state[0].append(0)
			#grid_state[1].append(0)

func true_modulo(a, b):
	return ((a % b) + b) % b;

func get_sum_neighbours(x, y):
	var left = true_modulo((x - 1), grid_dim_x)
	var right = true_modulo((x + 1), grid_dim_x)
	var top = true_modulo((y - 1), grid_dim_y)
	var bottom = true_modulo((y + 1), grid_dim_y)
	var top_y_offset = top * grid_size.x
	var bottom_y_offset = bottom * grid_size.x
	#prints(x, y, ":", left, right, top, bottom)
	#prints(top_y_offset, bottom_y_offset)
	var sum = grid_state[state_index][top_y_offset + left] + \
				grid_state[state_index][top_y_offset + x] + \
				grid_state[state_index][top_y_offset + right] + \
				grid_state[state_index][y * grid_size.x + left] + \
				grid_state[state_index][y * grid_size.x + right] + \
				grid_state[state_index][bottom_y_offset + left] + \
				grid_state[state_index][bottom_y_offset + x] + \
				grid_state[state_index][bottom_y_offset + right]

	return sum
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not step_once:
		if !is_running:
			return

		curr_time += _delta
		if curr_time >= 1/speed_slider.value:
			simulate()
			curr_time = 0
	else:
		simulate()
		step_once = false

func simulate():
	var _num_changes = 0

	if debug:
		print("Old State:")
		for y in range(3):
			print(grid_state[state_index][y * grid_dim_x], grid_state[state_index][y * grid_dim_x + 1], grid_state[state_index][y * grid_dim_x + 2], grid_state[state_index][y * grid_dim_x + 3])

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell_state = grid_state[state_index][y * grid_size.x + x]
			var cell = grid[y * grid_size.x + x]

			var neighbours = str(get_sum_neighbours(x, y))
			#if x < 3 and y <= 0:
			#	prints(y * grid_size.x + x, neighbours)

			if cell_state == 0:
				if neighbours in birth_rule:
					cell.set_state(1)
					grid_state[1 - state_index].append(1)
					_num_changes += 1
				else:
					grid_state[1 - state_index].append(0)
			elif cell_state > 0:
				if neighbours in survive_rule:
					cell.set_state(2)
					grid_state[1 - state_index].append(1)
				else:
					cell.set_state(0)
					_num_changes += 1
					grid_state[1 - state_index].append(0)

	grid_state[state_index].clear()
	state_index = 1 - state_index

	if _num_changes == 0: 
		run_button.set_pressed(false)
		print("No changes. Simulation stopped.")

	generation += 1
	generation_text.text = str(generation)
	if debug:
		print("New State:")
		for y in range(3):
			print(grid_state[state_index][y * grid_dim_x], grid_state[state_index][y * grid_dim_x + 1], grid_state[state_index][y * grid_dim_x + 2], grid_state[state_index][y * grid_dim_x + 3])
	
func _input(event):
	# Mouse in viewport coordinates
	if rule_dialog.visible:
		return
	if event is InputEventMouseButton and event.is_pressed():
		var grid_x = int(event.position.x / cell_dim.x)
		var grid_y = int(event.position.y / cell_dim.y)
		if grid_x > grid_dim_x or grid_y > grid_dim_y:
			return
		#prints("Clicked cell:", floor(grid_x), floor(grid_y),grid_y * grid_size.x + grid_x )
		var state = grid_state[state_index][grid_y * grid_size.x + grid_x]
		grid_state[state_index][grid_y * grid_size.x + grid_x] = 1 - state
		grid[grid_y * grid_size.x + grid_x].toggle_state()

func _on_Button_toggled(button_pressed):
	if not init_rules():
		run_button.set_pressed(false)
		return

	if button_pressed:
		print("Running simulation")
		run_button.text = "Pause"
		is_running = true
	else:
		print("Pausing simulation")
		run_button.text = "Run"
		is_running = false


func _on_StepButton_pressed():
	if init_rules():
		print("Stepping")
		run_button.set_pressed(false)
		step_once = true

func init_rules():
	rules = rule_text.text
	print("Rules: ", rules)
	var result = regex.search(rules)

	if not result:
		print("Invalid rule.")
		rule_dialog.show_modal(true)
		return false

	var _rules = rules.split("/")
	birth_rule = _rules[0]
	survive_rule = _rules[1]
	prints(birth_rule, survive_rule)
	return true

func _on_Clear_pressed():
	if is_running:
		printerr("Can't reset while simulation is running.")
		return
	print("Clear")
	generation = 0
	generation_text.text = str(generation)
	grid_state[0].clear()
	grid_state[1].clear()

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell = grid[y * grid_size.x + x]
			cell.set_state(0)
			grid_state[state_index].append(0)
