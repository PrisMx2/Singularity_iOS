extends Control

@export var length: float = 360.0
@export var easing: int = 8

var _state: int = 0
var _state_query: int = 0
var _value_time: float = 0.0
var _value_base: float = 0.0

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _process(_delta: float) -> void:
	var time: float = _get_time()
	if _state == 0:
		var progress: float = clampf( ( time - _value_time ) / length, 0.0, 1.0 )
		progress = Easings.Function[easing].call(progress)
		if progress == 1.0:
			if _state_query == 1:
				_state = 1
				_state_query = 0
				_value_time = time
		custom_maximum_size.x = 53.0 * ( 1.0 - progress )
	elif _state == 1:
		var progress: float = clampf( ( time - _value_time ) / length, 0.0, 1.0 )
		progress = Easings.Function[easing].call(progress)
		if progress == 1.0:
			if _state_query == 2:
				_state = 0
				_state_query = 0
				_value_time = time
		_value_base = 53.0 * progress
		position.x = 1000.0 - _value_base
		custom_maximum_size.x = _value_base

func set_hide() -> void:
	_state_query = 2

func set_hide_override() -> void:
	set_hide()
	_value_time = _get_time() - length

func set_unhide() -> void:
	_state_query = 1

func set_unhide_override() -> void:
	set_unhide()
	_value_time = _get_time() - length
