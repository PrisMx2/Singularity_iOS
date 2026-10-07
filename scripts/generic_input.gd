extends LineEdit

@export var label: Label

@export var filter: String = ""

func _tween_before() -> void:
	text = ""

func _ready() -> void:
	text_changed.connect(func(_text: String):
		if filter.length() > 0:
			var left: String = _text.substr(0, caret_column)
			var right: String = _text.substr(caret_column, -1)
			var new_left: String = ""
			var new_right: String = ""
			for i: int in left.length():
				new_left += left[i] if left[i].to_lower() in filter else ""
			for i: int in right.length():
				new_right += right[i] if right[i].to_lower() in filter else ""
			_text = new_left + new_right
			if text == _text:
				SoundManager.play("input")
			else:
				SoundManager.play("input_fail")
			text = _text
			caret_column = new_left.length()
		else:
			SoundManager.play("input")
		if label != null:
			var length: int = _text.length()
			label.text = ("(" if length > 9 else "(0") + str(length) + "/" + str(max_length) + ")"
	)

func _input(event: InputEvent) -> void:
	if can_process() and is_visible_in_tree():
		if event is InputEventScreenTouch:
			if event.pressed and not event.canceled:
				if get_global_rect().has_point(event.position):
					call_deferred("edit")
					accept_event()
	
