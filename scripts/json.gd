extends Node
class_name Json

static func load_file(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json_text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(json_text)

static func load_file_crypt(path: String) -> Variant:
	var key: String = str(path.hash())
	var file: FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, key)
	var json_text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(json_text)

static func write_file(path: String, data: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(serialize(data))
	file.close()

static func write_file_crypt(path: String, data: Variant) -> void:
	var key: String = str(path.hash())
	var file: FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, key)
	file.store_string(serialize(data))
	file.close()

static func parse(json_text: String) -> Variant:
	return JSON.parse_string(json_text)

static func serialize(data) -> String:
	return JSON.stringify(data)
