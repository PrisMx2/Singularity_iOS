extends Node

var _client: StreamPeerTCP
var _data: Array = []

func _ready() -> void:
	_client = StreamPeerTCP.new()
	var error: Error = _client.connect_to_host("127.0.0.1", 9178)
	if error == 0:
		DataManager.append_log("Client: Started successfully")
	else:
		DataManager.append_log("Client: Failed to start:", error)
		process_mode = Node.PROCESS_MODE_DISABLED

func append_data(data: PackedByteArray) -> void:
	_data.append(data)

func _physics_process(_delta: float) -> void:
	_client.poll()
	while _client and _client.get_status() == StreamPeerTCP.STATUS_CONNECTED and _data.size() > 0:
		var data: PackedByteArray = _data.pop_front()
		data = ("<size=" + str(data.size()) + ">").to_utf8_buffer() + data
		var size: int = data.size()
		var error: Error = _client.put_data(data)
		if error == 0:
			DataManager.append_log("Client: Sent", size, "bytes")
		else:
			DataManager.append_log("Client: Failed to send", size, "bytes")
