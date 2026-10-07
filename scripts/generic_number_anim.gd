extends Label

@export var length: float = 500.0
@export var easing: int = 5

var _value_time: float = 0.0
var _value_base: float = 0.0
var _value_target: float = 0.0
var _value_target_rec: float = 0.0

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _calcuate_int() -> int:
	var time: float = _get_time()
	var progress: float = clampf( ( time - _value_time ) / length, 0.0, 1.0 )
	progress = Easings.Function[easing].call(progress)
	var cut: int = roundi(_value_base + ( _value_target - _value_base ) * progress)

	if _value_target != _value_target_rec:
		_value_base = cut
		_value_target = _value_target_rec
		_value_time = time
		cut = _calcuate_int()

	return cut

func _calcuate_float(step: float = 0.01) -> float:
	var time: float = _get_time()
	var progress: float = clampf( ( time - _value_time ) / length, 0.0, 1.0 )
	progress = Easings.Function[easing].call(progress)
	var cut: float = snappedf(_value_base + ( _value_target - _value_base ) * progress, step)

	if _value_target != _value_target_rec:
		_value_base = cut
		_value_target = _value_target_rec
		_value_time = time
		cut = _calcuate_float(step)

	return cut

func set_value(value: float) -> void:
	_value_target_rec = value

func set_value_override(value: float) -> void:
	set_value(value)
	_value_time = _get_time() - length
