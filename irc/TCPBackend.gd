extends Node

var host_uri: String

signal closed
signal connected
signal data_received(data)
signal error(err)

var _status: int = 0
var _stream: StreamPeerTCP = StreamPeerTCP.new()

func _ready() -> void:
	_status = _stream.get_status()

func _process(_delta: float) -> void:
	var new_status: int = _stream.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			_stream.STATUS_NONE:
				emit_signal("closed")
			_stream.STATUS_CONNECTED:
				emit_signal("connected")
			_stream.STATUS_ERROR:
				emit_signal("error", "TCP connection error")

	if _status == _stream.STATUS_CONNECTED:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			var data: Array = _stream.get_partial_data(available_bytes)
			# Check for read error.
			if data[0] != OK:
				emit_signal("error", "TCP Error getting data from stream: " + str(data[0]))
			else:
				emit_signal("data_received", data[1].get_string_from_utf8())

func connect_to_host(host: String, port: int) -> void:
	print("TCP Connecting to %s:%d" % [host, port])
	# Reset status so we can tell if it changes to error again.
	_status = _stream.STATUS_NONE
	if _stream.connect_to_host(host, port) != OK:
		emit_signal("error", "TCP Error connecting to host.")

func send(data: String) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		emit_signal("error", "TCP Error: Stream is not currently connected.")
		return false
	var error: int = _stream.put_data((data + "\n").to_utf8())
	if error != OK:
		emit_signal("error", "TCP Error: " + str(error))
		return false
	return true
