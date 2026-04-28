extends TextureRect

@export var dialogue_key: String = ""

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		
		if dialogue_key == "": return 
		
		accept_event() 
		SignalBus.display_dialog.emit(dialogue_key)
