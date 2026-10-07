extends "res://scripts/generic_button.gd"

@export var root: Node2D

@export var last_scene: String = ""
@export var chapter: String = ""
@export var title_color: Color = Color(1.0, 1.0, 1.0, 1.0)

func _pressed() -> void:
	if last_scene.length() > 0:
		var node: Node2D = await SceneManager.insert("chapter_confirm")
		node.last_scene = last_scene
		node.chapter = chapter
		node.title_color = title_color
		node.load_chapter()
	else:
		SceneManager.unknown_function()
