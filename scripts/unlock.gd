extends Node

var unlock_data: Dictionary = {}

func _ready() -> void:
	unlock_data = Json.load_file_crypt("res://chapter/unlock.cslu")

func compare(a: float, op: String, b: float) -> bool:
	if op == "=": return a == b
	elif op == "<": return a < b
	elif op == ">": return a > b
	elif op == "<=": return a <= b
	elif op == ">=": return a >= b
	elif op == "!=": return a != b
	return true

func execute(data: Array, f_depth: int = 0) -> Array:
	var overrides: Dictionary = { display = [] }
	var parallels: Array = [true]
	var result: bool = true
	var depth: int = 0
	var split: bool = false
	var chunk: Array = []
	for index: int in data.size():
		var command: Array = data[index].split("	", false)
		var head: String = command[0]
		if head == ")":
			depth -= 1
			if depth == 0:
				var _result: Array = execute(chunk, depth + f_depth + 1)
				result = _result[0]
				overrides.display.append_array(_result[1].display)
				parallels[-1] = parallels[-1] and result
				chunk = []
		if depth > 0:
			chunk.append(data[index])
		if head == "(":
			depth += 1
		elif depth == 0:
			if head == "or":
				split = true
				parallels.append(true)
			else:
				if head == "save":
					result = false
					if command.size() == 4:
						for save: float in DataManager.match_save(command[1]):
							if compare(save, command[2], command[3].to_float()):
								result = true
								break
					elif command.size() == 5:
						for save: Dictionary in DataManager.match_save(command[1]):
							if compare(save[command[2]], command[3], command[4].to_float()):
								result = true
								break
					parallels[-1] = parallels[-1] and result
				elif head == "display":
					overrides.display.append([ result, command.slice(1), depth + f_depth, split ])
					split = false
				elif head == "override":
					var key: String = command[1]
					if not overrides.has(key):
						overrides[key] = []
					overrides[key].append_array(command.slice(2))
	var final: bool = false
	for res: bool in parallels:
		final = final or res
	return [ final, overrides ]

func test(key: Variant, type: String) -> Array:
	var empty: bool = true
	var final: Array = [ true, {} ]
	if key is String:
		for _key: String in unlock_data:
			if key.match(_key):
				empty = false
				var result: Array = execute(unlock_data[_key].get(type, []))
				final[0] = final[0] and result[0]
				final[1].merge(result[1])
	return [] if empty else final

func test_visibility(key: Variant) -> Array:
	return test(key, "visibility")

func test_accessibility(key: Variant) -> Array:
	return test(key, "accessibility")
