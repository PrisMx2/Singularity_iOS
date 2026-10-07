extends Node
class_name Easings

static var Function: Array = [

	func(_c: float) -> float: #00 Linear
		return _c,

	func(_c: float) -> float: #01 InSine
		return 1.0 - cos( (_c * PI) / 2.0 ),

	func(_c: float) -> float: #02 OutSine
		return sin( (_c * PI) / 2.0 ),

	func(_c: float) -> float: #03 InOutSine
		return ( cos(_c * PI) - 1.0 ) / -2.0,

	func(_c: float) -> float: #04 InQuad
		return _c ** 2.0,

	func(_c: float) -> float: #05 OutQuad
		return 1.0 - ( 1.0 - _c ) ** 2.0,

	func(_c: float) -> float: #06 InOutQuad
		if _c <= 0.5:
			return _c ** 2.0 * 2.0
		else:
			return 1.0 - ( -2.0 * _c + 2.0 ) ** 2.0 / 2.0,

	func(_c: float) -> float: #07 InCubic
		return _c ** 3.0,

	func(_c: float) -> float: #08 OutCubic
		return 1.0 - ( 1.0 - _c ) ** 3.0,

	func(_c: float) -> float: #09 InOutCubic
		if _c <= 0.5:
			return _c ** 3.0 * 4.0
		else:
			return 1.0 - ( -2.0 * _c + 2.0 ) ** 3.0 / 2.0,

	func(_c: float) -> float: #10 InQuart
		return _c ** 4.0,

	func(_c: float) -> float: #11 OutQuart
		return 1.0 - ( 1.0 - _c ) ** 4.0,

	func(_c: float) -> float: #12 InOutQuart
		if _c <= 0.5:
			return _c ** 4.0 * 8.0
		else:
			return 1.0 - ( -2.0 * _c + 2.0 ) ** 4.0 / 2.0,

	func(_c: float) -> float: #13 InQuint
		return _c ** 5.0,

	func(_c: float) -> float: #14 OutQuint
		return 1.0 - ( 1.0 - _c ) ** 5.0,

	func(_c: float) -> float: #15 InOutQuint
		if _c <= 0.5:
			return _c ** 5.0 * 16.0
		else:
			return 1.0 - ( -2.0 * _c + 2.0 ) ** 5.0 / 2.0,

	func(_c: float) -> float: #16 InExpo
		if _c == 0.0:
			return 0.0
		else:
			return 2.0 ** ( 10.0 * _c - 10.0 ),

	func(_c: float) -> float: #17 OutExpo
		if _c == 1:
			return 1.0
		else:
			return 1.0 - 2.0 ** ( -10.0 * _c ),

	func(_c: float) -> float: #18 InOutExpo
		if _c == 0.0:
			return 0.0
		elif _c == 1.0:
			return 1.0
		elif _c <= 0.5:
			return 2.0 ** ( 20.0 * _c - 10.0 ) / 2.0
		else:
			return ( 2.0 - 2.0 ** ( -20.0 * _c + 10.0 ) ) / 2.0,

	func(_c: float) -> float: #19 InCirc
		return 1.0 - ( 1.0 - _c ** 2.0 ) ** 0.5,

	func(_c: float) -> float: #20 OutCirc
		return ( 1.0 - ( _c - 1.0 ) ** 2.0 ) ** 0.5,

	func(_c: float) -> float: #21 InOutCirc
		if _c <= 0.5:
			return ( 1.0 - ( 1.0 - ( _c * 2.0 ) ** 2.0 ) ** 0.5 ) / 2.0
		else:
			return ( 1.0 + ( 1.0 - ( _c * -2.0 + 2.0 ) ** 2.0 ) ** 0.5 ) / 2.0,

	func(_c: float) -> float: #22 InBack
		return 2.7 * _c ** 3.0 - 1.7 * _c ** 2.0,

	func(_c: float) -> float: #23 OutBack
		return 1.0 + 2.7 * ( _c - 1.0 ) ** 3.0 + 1.7 * ( _c - 1.0 ) ** 2.0,

	func(_c: float) -> float: #24 InOutBack
		if _c <= 0.5:
			return ( 2.0 * _c ) ** 2.0 * ( 7.2 * _c - 2.6 ) / 2.0
		else:
			return ( ( 2.0 * _c - 2.0 ) ** 2.0 * ( 3.6 * ( _c * 2.0 - 2.0 ) + 2.6 ) + 2.0 ) / 2.0,

	func(_c: float) -> float: #25 InElastic
		if _c == 0.0:
			return 0.0
		else:
			return - ( 2.0 ** ( 10.0 * _c - 10.0 ) * sin( ( _c * 10.0 - 10.75 ) * PI * 2.0 / 3.0 ) ),

	func(_c: float) -> float: #26 OutElastic
		if _c == 1.0:
			return 1.0
		else:
			return 2.0 ** ( - 10.0 * _c ) * sin( (_c * 10.0 - 0.75 ) * PI * 2.0 / 3.0 ) + 1.0,

	func(_c: float) -> float: #27 InOutElastic
		if _c == 0.0:
			return 0.0
		elif _c == 1.0:
			return 1.0
		elif _c <= 0.5:
			return - ( 2.0 ** ( 20.0 * _c - 10.0 ) * sin( ( 20.0 * _c - 11.125 ) * PI * 4.0 / 9.0 ) ) / 2.0
		else:
			return ( 2.0 ** ( -20.0 * _c + 10.0 ) * sin( ( 20.0 * _c - 11.125 ) * PI * 4.0 / 9.0 ) ) / 2.0 + 1.0,

	func(_c: float) -> float: #28 InBounce
		_c = 1.0 - _c
		if _c < 0.3636:
			return 1.0 - 7.5625 * _c ** 2.0
		elif _c < 0.7272:
			return 1.0 - 7.5625 * ( _c - 1.5 / 2.75 ) ** 2.0 - 0.75
		elif _c < 0.9091:
			return 1.0 - 7.5625 * ( _c - 2.25 / 2.75 ) ** 2.0 - 0.9375
		else:
			return 1.0 - 7.5625 * ( _c - 2.625 / 2.75 ) ** 2.0 - 0.984375,

	func(_c: float) -> float: #29 OutBounce
		if _c < 0.3636:
			return 7.5625 * _c ** 2.0
		elif _c < 0.7272:
			return 7.5625 * ( _c - 1.5 / 2.75 ) ** 2.0 + 0.75
		elif _c < 0.9091:
			return 7.5625 * ( _c - 2.25 / 2.75 ) ** 2.0 + 0.9375
		else:
			return 7.5625 * ( _c - 2.625 / 2.75 ) ** 2.0 + 0.984375,

	func(_c: float) -> float: #30 Random
		return randf(),

]
