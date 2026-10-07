extends Node2D

@export var rotate_offset: Vector2 = Vector2(0.0, 0.0)
@export var rotate_limit: Vector2 = Vector2(0.0, 5.0)
@export var touch_angle_limit: Vector2 = Vector2(-180.0, 180.0)
@export var touch_distance_limit: Vector2 = Vector2(0.0, INF)
@export var align_angle: float = 30.0
@export var align_duration: float = 0.5
@export var resistance: float = 1.0

var _touch_index: int = -1

var _rotate_time: float = 0.0
var _rotate_record: float = 0.0
var _rotate_base: float = 0.0
var _rotate_angle: float = 0.0
var _rotate_target: float = 0.0
var _rotate_speed: float = 0.0

var _align_tween: Tween = create_tween()

var dirty: bool = false
var index: int = 0

signal stopped
signal started

func _tween_break() -> void:
	_touch_index = -1

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _ready() -> void:
	touch_angle_limit.x = deg_to_rad(touch_angle_limit.x)
	touch_angle_limit.y = deg_to_rad(touch_angle_limit.y)
	align_angle = deg_to_rad(align_angle)

func _calcuate_angle(event: InputEvent) -> float:
	var local: Vector2 = make_input_local(event).position
	return local.angle() + rotation

func _calcuate_distance(event: InputEvent) -> float:
	var local: Vector2 = make_input_local(event).position
	return sqrt(pow(local.x, 2.0) + pow(local.y, 2.0))

func _compare_angle(a: float, b: float) -> float:
	return wrapf(a - b + PI, 0.0, TAU) - PI

func _fix_angle(a: float) -> float:
	return wrapf(a + PI, 0.0, TAU) - PI

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1:
				var angle: float = _calcuate_angle(event)
				var fix_angle: float = _fix_angle(angle)
				if touch_angle_limit.x < fix_angle and fix_angle < touch_angle_limit.y:
					var distance: float = _calcuate_distance(event)
					if touch_distance_limit.x < distance and distance < touch_distance_limit.y:
						_touch_index = event.index
						_rotate_time = _get_time()
						_rotate_record = rotation
						_rotate_base = angle
						_rotate_angle = angle
						_rotate_target = angle
						_rotate_speed = 0.0
						_align_tween.kill()
						started.emit()
						dirty = true
		else:
			if _touch_index == event.index:
				_touch_index = -1
				var total: float = _rotate_angle - _rotate_base
				if absf(total) < 0.025:
					var tap_angle: float = rotation - _fix_angle(_rotate_angle)
					var tap_index: int = clampi(floori(tap_angle / align_angle + 0.5), rotate_limit.x, rotate_limit.y)
					if tap_index != index:
						_rotate_speed = 0.0
						var angle: float = tap_index * align_angle
						_rotate_record = angle
						_rotate_base = 0.0
						_rotate_angle = 0.0
						_rotate_target = angle
						_align_tween.kill()
						_align_tween = create_tween()
						_align_tween.set_ease(Tween.EASE_OUT)
						_align_tween.set_trans(Tween.TRANS_CUBIC)
						_align_tween.tween_property(self, "rotation", angle, align_duration / 2.0).from(rotation)
						dirty = true
	elif event is InputEventScreenDrag:
		if _touch_index == event.index:
			_rotate_target = _calcuate_angle(event)

func stop() -> void:
	_rotate_speed = 0.0

func reset() -> void:
	_align_tween.kill()
	_touch_index = -1
	_rotate_time = 0.0
	_rotate_record = 0.0
	_rotate_base = 0.0
	_rotate_angle = 0.0
	_rotate_target = 0.0
	_rotate_speed = 0.0
	index = 0

func _process(_delta: float) -> void:

	var delta_time: float = _get_time() - _rotate_time
	index = floori(rotation / align_angle + 0.5)

	var limit: Vector2 = rotate_limit * align_angle
	if _touch_index > -1:
		_align_tween.kill()
		_rotate_speed = _compare_angle(_rotate_target, _rotate_angle)
	elif rotation < limit.x:
		if not _align_tween.is_running():
			_rotate_speed = ( limit.x - rotation ) * delta_time / resistance / 80.0
			_rotate_speed += 0.025
			dirty = true
	elif rotation > limit.y:
		if not _align_tween.is_running():
			_rotate_speed = ( limit.y - rotation ) * delta_time / resistance / 80.0
			_rotate_speed -= 0.025
			dirty = true
	else:
		_rotate_speed *= ( 1.0 - minf(absf(_rotate_speed) * delta_time * resistance / 50.0, 0.1) )
		if abs(_rotate_speed) < 0.0275:
			if not _align_tween.is_running() and dirty:
				_rotate_speed = 0.0
				var angle: float = index * align_angle
				_rotate_record = angle
				_rotate_base = 0.0
				_rotate_angle = 0.0
				_rotate_target = angle
				_align_tween = create_tween()
				_align_tween.set_ease(Tween.EASE_OUT)
				_align_tween.set_trans(Tween.TRANS_CUBIC)
				_align_tween.tween_property(self, "rotation", angle, align_duration).from(rotation)
				dirty = false
				await _align_tween.finished
				stopped.emit()

	_rotate_angle += _rotate_speed * minf(delta_time / resistance / 20.0, 1.0)
	rotation = (_rotate_record + _rotate_angle - _rotate_base)
	_rotate_time = _get_time()
