extends Node

var host_uri: String

signal closed
signal connected
signal data_received(data)
signal on_error(err)

var _status: int = 0
var _stream: StreamPeerTCP = StreamPeerTCP.new()


func _ready() -> void:
	_status = _stream.get_status()


func _process(_delta: float) -> void:
	_stream.poll()
	var new_status: int = _stream.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			_stream.STATUS_NONE:
				closed.emit()
			_stream.STATUS_CONNECTED:
				connected.emit()
			_stream.STATUS_ERROR:
				on_error.emit("TCP connection on_error")

	if _status == _stream.STATUS_CONNECTED:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			var data: Array = _stream.get_partial_data(available_bytes)
			# Check for read on_error.
			if data[0] != OK:
				on_error.emit("TCP Error getting data from stream: " + str(data[0]))
			else:
				data_received.emit(data[1].get_string_from_utf8())


func connect_to_host(host: String, port: int) -> void:
	print("TCP Connecting to %s:%d" % [host, port])
	# Reset status so we can tell if it changes to on_error again.
	_status = _stream.STATUS_NONE
	var err = _stream.connect_to_host(host, port)
	if err != OK:
		on_error.emit("TCP Error connecting to host: ", err)
		print("TCP Error connecting to host: ", err)
		return
	print("TCP Connected to %s:%d" % [host, port])


func send(data: String) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		on_error.emit("TCP Error: Stream is not currently connected.")
		return false
	var error: int = _stream.put_data((data + "\r\n").to_utf8_buffer())
	if error != OK:
		on_error.emit("TCP Error: " + str(error))
		return false
	return true
