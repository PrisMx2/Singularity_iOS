extends Label

@export var length_decrease: float = 420.0
@export var length_increase: float = 550.0
@export var easing: int = 5

var _stage: int = 0
var _stage_query: int = 0
var _value_time: float = 0.0
var _value_base: String = ""
var _value_base_length: int = 0
var _value_target: String = ""
var _value_target_length: int = 0

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _random_char(_char: String) -> String:
	if _char.to_lower() in "1234567890qwertyuiopasdfghjklzxcvbnm":
		return "#%&+=?!"[randi_range(0, 6)]
	else:
		return _char

func _calcuate_string() -> String:
	var time: float = _get_time()
	seed(floor(time / 65.0))
	var cut: String
	if _stage == 0:
		var progress: float = clampf( ( time - _value_time ) / length_decrease, 0.0, 1.0 )
		if progress == 1.0:
			cut = ""
			if _stage_query == 1:
				_stage = 1
				_stage_query = 0
				_value_time = time
		else:
			progress = Easings.Function[easing].call(progress)
			var text_length: int = roundi(_value_base_length * ( 1.0 - progress ))
			cut = _value_base
			for i: int in cut.length():
				if randf() < progress:
					cut[i] = _random_char(cut[i])
			if text_length > 0:
				cut = cut.substr(0, text_length - 1) + "_"
			else:
				cut = cut.substr(0, text_length)
	elif _stage == 1:
		var progress: float = clampf( ( time - _value_time ) / length_increase, 0.0, 1.0 )
		progress = Easings.Function[easing].call(progress)
		var text_length: int = roundi(_value_target_length * progress)
		cut = _value_target
		for i: int in cut.length():
			if randf() < 1.0 - progress and not cut[i] in " \n":
				cut[i] = _random_char(cut[i])
		if progress < 1.0 and text_length > 0:
			cut = cut.substr(0, text_length - 1) + "_"
		else:
			cut = cut.substr(0, text_length)

	return cut

func set_decrease() -> void:
	_value_base = _calcuate_string()
	_value_base_length = _value_base.length()
	_value_time = _get_time()
	_stage = 0
	_stage_query = 0

func set_decrease_override() -> void:
	set_decrease()
	_value_time = _get_time() - length_decrease

func set_increase(value: String) -> void:
	value = tr(value)
	_value_target = value
	_value_target_length = value.length()
	_stage_query = 1

func set_increase_override(value: String) -> void:
	value = tr(value)
	_value_target = value
	_value_target_length = value.length()
	_value_time = _get_time() - length_increase
	_stage = 1
	_stage_query = 0

func _process(_delta: float) -> void:
	text = _calcuate_string()
