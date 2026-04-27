extends TextureRect
var dragging: bool = false;
var offset: Vector2 = Vector2.ZERO

func scatter():
	var max_x = 300.0 - size.x
	var max_y = 400.0 - size.y
	position = Vector2(randf_range(0, max_x), randf_range(0,max_y))

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			offset = get_viewport().get_mouse_position() - position
			move_to_front()
			accept_event()
		else:
			dragging = false
			#grab the save state after dragging has stopped
			if get_parent().has_method("save_current_state"):
				get_parent().save_current_state()

	elif event is InputEventMouseMotion and dragging:
		position = get_viewport().get_mouse_position() - offset
		
		var max_x = 300.0 - size.x
		var max_y = 400.0 - size.y
		
		position.x = clamp(position.x, 0, max_x)
		position.y = clamp(position.y, 0, max_y)
		
