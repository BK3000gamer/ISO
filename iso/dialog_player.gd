extends CanvasLayer

@export_file("*.json") var scene_text_file: String

var flattened_lexicon: Dictionary = {}
var selected_text: Array = []
var in_progress: bool = false

@onready var text_label = $Background/MarginContainer/"Text Label"
@onready var background = $Background

func _ready() -> void:
	background.visible = false
	flattened_lexicon = decipher_nested_json()
	SignalBus.display_dialog.connect(on_display_dialog)

func decipher_nested_json() -> Dictionary:
	if not FileAccess.file_exists(scene_text_file): return {}
	
	var file = FileAccess.open(scene_text_file, FileAccess.READ)
	var raw_data = JSON.parse_string(file.get_as_text())
	var translated_dict: Dictionary = {}
	
	if raw_data == null: return translated_dict

	for era_key in raw_data.keys():
		var contents = raw_data[era_key]
		
		if typeof(contents) == TYPE_ARRAY:
			for memory in contents:
				if memory.has("dialogue_name") and memory.has("dialogue"):
					translated_dict[memory["dialogue_name"]] = [memory["dialogue"]]
					
		elif typeof(contents) == TYPE_DICTIONARY:
			if contents.has("ending_dialogue"):
				translated_dict["end_game"] = [contents["ending_dialogue"]]

	return translated_dict

func show_text():
	text_label.text = selected_text.pop_front()
	
func next_line():
	if selected_text.size() > 0:
		show_text()
	else:
		finish()

func finish():
	text_label.text = ""
	background.visible = false
	in_progress = false
	get_tree().paused = false

func on_display_dialog(text_key: String):
	# Prevent dialogue if the BookManager is mid-flip
	var book = get_tree().get_first_node_in_group("book_manager")
	if book and book.flipper.visible: return 

	if in_progress:
		next_line()
	else:
		if flattened_lexicon.has(text_key):
			get_tree().paused = true
			in_progress = true
			background.visible = true
			selected_text = flattened_lexicon[text_key].duplicate()
			show_text()

func _input(event):
	if not in_progress: return 
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		get_viewport().set_input_as_handled() 
		
	
		next_line()
