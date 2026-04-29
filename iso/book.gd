extends Node2D

@export var book_pages: Array[BookPage]
var current_index: int = 0
var flipping_forward: bool = true
var hidden_studio: SubViewportContainer = null
var prepare_flip: bool = false
var page_w: float = 640.0
var page_h: float = 840.0
@onready var left_container = $Left_Page
@onready var right_container = $Right_Page
@onready var left_photo = $Left_Page/Left_Photo_Texture
@onready var right_photo = $Right_Page/Right_Photo_Texture
@onready var flipper = $Page_Flipper

var active_left_scene: Node = null
var active_right_scene: Node = null

func _ready():
	flipper.visible = false

	update_static_pages()
	flipper.flip_completed.connect(on_flip_completed)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		attempt_page_turn()
func attempt_page_turn():
		if flipper.visible: return
		var screen_width = get_viewport_rect().size.x
		var global_click_x = get_global_mouse_position().x
		if global_click_x > screen_width/2.0:
			start_flip_forward()
		else:
			start_flip_backward()
	
func update_static_pages():
	#Destroy existing puzzles
	if active_left_scene:
		active_left_scene.queue_free()
		active_left_scene = null
	if active_right_scene:
		active_right_scene.queue_free()
		active_right_scene = null
	#Page Spread
	var left_index = (current_index * 2) - 1
	var right_index = (current_index * 2)
	#left page
	if left_index >= 0 and left_index < book_pages.size():
		load_page_content(book_pages[left_index], left_photo, left_container, true)
	else:
		left_photo.texture = null
	#right page
	if right_index >= 0 and right_index < book_pages.size():
		load_page_content(book_pages[right_index], right_photo,
		right_container, false)
	else:
		right_photo.texture = null
		
		
#load page
func load_page_content(page_data: BookPage, photo_rect: TextureRect,
container: Control, is_left: bool):
	if page_data.page_type == 0:
		photo_rect.texture = page_data.photo_texture
		photo_rect.visible = true
	elif page_data.page_type == 1 and page_data.puzzle_scene != null:
		photo_rect.visible = false
		#Switching to Subviewport for seamless transistions
		var sv_container = SubViewportContainer.new()
		sv_container.name = "Puzzle_Screen"
		sv_container.size = Vector2(page_w, page_h)
		sv_container.mouse_filter = Control.MOUSE_FILTER_STOP
		container.add_child(sv_container)
		
		var sub_viewport = SubViewport.new()
		#SIZE MATTERS!!!!
		sub_viewport.size = Vector2(page_w,page_h)
		sub_viewport.transparent_bg = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sv_container.add_child(sub_viewport)
		
		var new_puzzle = page_data.puzzle_scene.instantiate()
		if "page_data" in new_puzzle:
			new_puzzle.page_data = page_data
		
		if "manager" in new_puzzle:
			new_puzzle.manager = self
		sub_viewport.add_child(new_puzzle)
		
		#Swapped out the signal for a manager
		##if new_puzzle.has_signal("clicked_blank_page"):
			##if is_left:
				##new_puzzle.clicked_blank_page.connect(start_flip_backward)
			##else:
				##new_puzzle.clicked_blank_page.connect(start_flip_forward)
		##sub_viewport.add_child(new_puzzle)
		if is_left:
			active_left_scene = sv_container
		else:
			active_right_scene = sv_container
			
			
func flip_texture(index:int) -> Texture2D:
	if index >= 0 and index < book_pages.size():
		return book_pages[index].photo_texture
	return null

func start_flip_forward():
	if prepare_flip: return
	var right_index = current_index * 2
	if right_index >= book_pages.size(): return
	
	prepare_flip = true
	flipping_forward = true
	# Live Flipper Texture
	if active_right_scene and active_right_scene is SubViewportContainer:
		flipper.texture_front = active_right_scene.get_child(0).get_texture()
	else:
		flipper.texture_front = flip_texture(right_index)
	
	# Clean up any old studio
	if hidden_studio: hidden_studio.queue_free(); hidden_studio = null
	# Build Hidden Studio
	var next_left_index = right_index + 1
	if next_left_index < book_pages.size():
		var page_data = book_pages[next_left_index]
		if page_data.page_type == 1 and page_data.puzzle_scene != null:
			hidden_studio = SubViewportContainer.new()
			hidden_studio.size = Vector2(page_w, page_h)
			hidden_studio.position = Vector2(-9000, -9000)
			hidden_studio.visible = false 
			add_child(hidden_studio) 
			
			var sub_viewport = SubViewport.new()
			sub_viewport.size = Vector2(page_w, page_h)
			sub_viewport.transparent_bg = true
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			hidden_studio.add_child(sub_viewport)
			
			var temp_puzzle = page_data.puzzle_scene.instantiate()
			if "page_data" in temp_puzzle: temp_puzzle.page_data = page_data
			sub_viewport.add_child(temp_puzzle)
			
			flipper.texture_back = sub_viewport.get_texture()
		else:
			flipper.texture_back = page_data.photo_texture
	else:
		flipper.texture_back = null
	
	# Illusion
	var next_right_index = right_index + 2
	
	if active_right_scene:
		var cloaked_scene = active_right_scene
		active_right_scene = null
		cloaked_scene.visible = false
		flipper.flip_completed.connect(cloaked_scene.queue_free, CONNECT_ONE_SHOT)
	
	if next_right_index < book_pages.size():
		load_page_content(book_pages[next_right_index], right_photo, right_container, false)
	else:
		right_photo.texture = null
	
	#Let SubViewport Render
	await get_tree().process_frame
	
	flipper.move = 0.0
	flipper.precise_move = 0.0
	flipper.generate_page_mesh()
	flipper.visible = true
	flipper.dragging = true
	prepare_flip = false
	
#Go Backwards
func start_flip_backward():
	if prepare_flip: return
	if current_index <= 0: return 
	var left_index = (current_index * 2) - 1
	
	prepare_flip = true
	flipping_forward = false
	#Flipper Texture
	if active_left_scene and active_left_scene is SubViewportContainer:
		flipper.texture_back = active_left_scene.get_child(0).get_texture()
	else:
		flipper.texture_back = flip_texture(left_index)
	
	if hidden_studio: hidden_studio.queue_free(); hidden_studio = null
		
	# Build Hidden Studio
	var next_right_index = left_index - 1
	if next_right_index >= 0:
		var page_data = book_pages[next_right_index]
		if page_data.page_type == 1 and page_data.puzzle_scene != null:
			hidden_studio = SubViewportContainer.new()
			hidden_studio.size = Vector2(page_w, page_h)
			
			#shoving it offscreen so it doesnt show but still updates the pages live
			#I've basically created a broadcast of the pages that screenshots onto the flipper logic
			hidden_studio.position = Vector2(-9000,-9000)
			hidden_studio.visible = false
			add_child(hidden_studio)
			
			var sub_viewport = SubViewport.new()
			sub_viewport.size = Vector2(page_w, page_h)
			sub_viewport.transparent_bg = true
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			hidden_studio.add_child(sub_viewport)
			
			var temp_puzzle = page_data.puzzle_scene.instantiate()
			if "page_data" in temp_puzzle: temp_puzzle.page_data = page_data
			sub_viewport.add_child(temp_puzzle)
			
			flipper.texture_front = sub_viewport.get_texture()
		else:
			flipper.texture_front = page_data.photo_texture
	else:
		flipper.texture_front = null
		
	#Illusion
	var next_left_index = left_index - 2
	
	if active_left_scene: 
		var cloaked_scene = active_left_scene
		active_left_scene = null
		cloaked_scene.visible = false
		flipper.flip_completed.connect(cloaked_scene.queue_free, CONNECT_ONE_SHOT)
		
	if next_left_index >= 0:
		load_page_content(book_pages[next_left_index], left_photo, left_container, true)
	else:
		left_photo.texture = null
	
	await get_tree().process_frame
	
	flipper.move = 1.0
	flipper.precise_move = 1.0
	flipper.generate_page_mesh()
	flipper.visible = true
	flipper.dragging = true
	prepare_flip = false
			
func on_flip_completed():
	if flipping_forward and flipper.move >= 1.0:
		current_index += 1
	elif not flipping_forward and flipper.move <= 0.0:
		current_index -= 1
		
	flipper.visible = false
	
	# Destroy the hideen studio once it lands fully
	if hidden_studio:
		hidden_studio.queue_free()
		hidden_studio = null
	#Actual interactive page
	update_static_pages()
		
		

		

	
