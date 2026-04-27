extends Control
var page_data: Resource = null
var manager: Node = null
func _ready():
	if page_data !=null and not page_data.saved_puzzle_state.is_empty():
		for child in get_children():
			if child is TextureRect and child.name != "Page":
				if page_data.saved_puzzle_state.has(child.name):
					child.position = page_data.saved_puzzle_state[child.name]
	else:
		for child in get_children():
			if child is TextureRect and child.name != "Page":
				if child.has_method("scatter"):
					child.scatter()
		save_current_state()

func save_current_state():
	if page_data == null: return
	var new_state: Dictionary = {}
	for child in get_children():
		if child is TextureRect and child.name!= "Page":
			new_state[child.name] = child.position
	
	page_data.saved_puzzle_state = new_state

#Catching missed clicks
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index \
	== MOUSE_BUTTON_LEFT and event.pressed:
		if manager and manager.has_method("attempt_page_turn"):
			manager.attempt_page_turn()
