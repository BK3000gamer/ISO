extends Resource
class_name BookPage

@export_enum("Photo", "Puzzle") var page_type: int = 0

@export_group("If Photo")
@export var photo_texture: Texture2D

@export_group("If Puzzle")
@export var puzzle_scene: PackedScene

#Save state of puzzle on page turns
var saved_puzzle_state: Dictionary = {}
