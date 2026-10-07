extends Label

const space: String = "     "

var _raw_text: String = ""
var _scroll: bool = false
var _scroll_time: float = 0.0

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func load_text(new_text: String) -> void:

	if new_text != _raw_text:
		_raw_text = new_text
		text = ""
		size.x = 0.0
		offset_transform_position.x = 0.0

		text = new_text
		await get_tree().process_frame
		_scroll_time = _get_time()
		_scroll = size.x > custom_minimum_size.x
		if _scroll:
			text = text + space + text + space

func _process(delta: float) -> void:
	if _scroll and _get_time() - _scroll_time > 300.0:
		offset_transform_position.x -= delta * 70.0
		offset_transform_position.x = wrapf(offset_transform_position.x, -size.x / 2.0, 0.0)
