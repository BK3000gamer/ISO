extends MeshInstance2D

var move: float = 0.0
var precise_move: float = 0.0
signal flip_completed # This tells the manager if page is flipped
#mouse dragging
var dragging: bool = false
var origin_right: bool = false
@export var drag_sens: float = 1.15
@export var flip_speed: float = 1.0
@export var segment_n: int = 50
@export var page_width: float = 200.0
@export var page_height: float = 300.0
@export var texture_front: Texture2D
@export var texture_back: Texture2D


func _process(delta):
	#Changed movement of page based on mouse dragging
	if move != precise_move:
		move = move_toward(move, precise_move, delta * flip_speed)
		generate_page_mesh()
		if move == precise_move and (move == 1.0 or move == 0.0):
			emit_signal("flip_completed")
	
func _input(event):
	if not visible: return
	#Mouse movement detection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			origin_right =  move < 0.5
		#goes to otherside if page is over 50% flipped
		if not dragging:
			precise_move = 1.0 if move > 0.5 else 0.0
	if event is InputEventMouseMotion and dragging:
		var screen_width = get_viewport_rect().size.x
		#push towards 1.0 if going left and vice versa
		var drag_amount = -(event.relative.x/screen_width) * drag_sens
		#drag amount stays between 0 and 1
		precise_move = clamp(precise_move + drag_amount,0.0,1.0)

func generate_page_mesh():
	var clamped_middle = clamp(move * 2.0, 0.0, 1.0)
	var clamped_end = clamp((move - 0.5) * 2.0, 0.0, 1.0)

	# pow is the twerp equivalent
	var _to_middle: float = pow(clamped_middle, 4.0)
	var _to_end: float = 1.0 - pow(1.0 - clamped_end, 4.0)

	var _start_dir: float = 0.0
	var _start_bend: float = 0.0

	var _mid_dir: float
	var _mid_bend: float
	
	if origin_right:
		_mid_dir = -20.0
		_mid_bend = -140.0 / segment_n
	else:
		_mid_dir = -160.0
		_mid_bend = 140.0 / segment_n

	var _end_dir: float = -180.0
	var _end_bend: float = 0.0
	
	#at least lerps the same 
	var _page_dir: float = lerp(_start_dir,
	lerp(_mid_dir,_end_dir,_to_end), _to_middle)

	var _page_bend: float = lerp(_start_bend,
	lerp(_mid_bend,_end_bend,_to_end),_to_middle)

	var segment_len = page_width / segment_n
	
	#  draw_primitive_begin()
	var vertices = PackedVector2Array()
	# array to hold uvs
	var uvs = PackedVector2Array()
	
	var colors = PackedColorArray()
	
	var current_pos = Vector2.ZERO 
	#conversion
	var current_angle = deg_to_rad(_page_dir) 
	var bend_rad = deg_to_rad(_page_bend)
	#page swap
	var is_back_side = move > 0.5
	var current_texture = texture_back if is_back_side else texture_front
	self.texture = current_texture
	# for (var i = 0; i< segment_n; i++)
	for i in range(segment_n + 1):
		#calculates how far across the page we are
		var _pagedistance = float(i) / float(segment_n)
		#Reverse UV for backside
		if is_back_side:
			_pagedistance = 1.0 - _pagedistance
		#Lighting
		var lift_shadow = sin(move * PI)
		var crease_shadow = sin(float(i)/float(segment_n) * PI) * lift_shadow
		var brightness = 1.0 - (crease_shadow * 0.5)
		
		var vert_color = Color(brightness, brightness, brightness, 1.0)
		#push_back anchors corners of page
		#Bottom Vertex
		vertices.push_back(current_pos)
		uvs.push_back(Vector2(_pagedistance,1.0))
		colors.push_back(vert_color)
		#Top Vertex
		vertices.push_back(current_pos + Vector2(0, -page_height))
		uvs.push_back(Vector2(_pagedistance,0.0))
		colors.push_back(vert_color)
		#length dir = Vector2(cos(current_angle), sin(current_angle))*segment_len
		current_pos += Vector2(cos(current_angle),
		sin(current_angle)) * segment_len
		#_page_dir += _page_bend
		current_angle += bend_rad

	# draw_primitive_end()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vertices
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = colors
	
	# Triangle mesh page generation
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)
	
	self.mesh = new_mesh
		
		
		
	
	
