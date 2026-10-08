extends Node

var _server: TCPServer = null
var _peers: Dictionary = {}
var _regex_header: RegEx
var _regex_int: RegEx

func _ready():
	_server = TCPServer.new()
	var error: Error = _server.listen(9178)
	if error != 0:
		process_mode = Node.PROCESS_MODE_DISABLED

	_regex_header = RegEx.create_from_string(r"<size=\d+>")
	_regex_int = RegEx.create_from_string(r"\d+")

func _physics_process(_delta: float) -> void:
	while _server and _server.is_connection_available():
		var peer: Variant = _server.take_connection()
		if peer:
			_peers[peer] = {
				buffer = PackedByteArray(),
				length = 0
			}

	for peer: StreamPeerTCP in _peers.keys():
		peer.poll()

		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(peer)
			continue

		var available: int = peer.get_available_bytes()
		if available <= 0:
			continue

		var data: PackedByteArray = peer.get_data(available)[1]
		var state: Dictionary = _peers[peer]
		var buffer: PackedByteArray = state.buffer
		state.buffer += data

		while true:
			if state.length == 0:
				var header: RegExMatch = _regex_header.search(state.buffer.get_string_from_utf8())
				if header:
					var header_string: String = header.get_string()
					var length: int = _regex_int.search(header_string).get_string().to_int()
					state.length = length
					var header_length: int = header_string.to_utf8_buffer().size()
					state.buffer = state.buffer.slice(header_length, state.buffer.size())
				else:
					break

			if state.length > 0:
				if state.buffer.size() >= state.length:
					var body_bytes: PackedByteArray = state.buffer.slice(0, state.length)
					state.buffer = state.buffer.slice(state.length, state.buffer.size())

					var complete_string: String = body_bytes.get_string_from_utf8()
					_handle_received_data(complete_string)

					state.length = 0
				else:
					break

func _handle_received_data(data: String):
	print("Server: Received successfully")
	print("Server: Preview:", data.substr(0, 200))
