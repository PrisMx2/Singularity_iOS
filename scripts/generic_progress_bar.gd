extends ColorRect

@export var init: float = 0.0
@export var duration: float = 800.0
@export var easing: int = 11

var _base: float = 0.0
var _target: float = 0.0
var _time: float = 0.0

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _ready() -> void:
	set_value_override(init)

func _update() -> float:
	var progress: float = ( _get_time() - _time ) / duration
	progress = clampf(progress, 0.0, 1.0)
	var value: float = _base + Easings.Function[easing].call(progress) * ( _target - _base )
	scale.x = value
	return value

func set_value_break(value: float) -> void:
	_base = _update()
	_target = value
	_time = _get_time()

func set_value_finish(value: float) -> void:
	_base = _target
	_target = value
	_time = _get_time()

func set_value_override(value: float) -> void:
	_target = value
	_time = _get_time() - duration
