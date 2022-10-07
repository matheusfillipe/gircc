rc/IrcClient.gd
extends Node
rc/IrcClient.gd

rc/IrcClient.gd
var host_uri: String
rc/IrcClient.gd

rc/IrcClient.gd
signal closed
rc/IrcClient.gd
signal connected
rc/IrcClient.gd
signal data_received(data)
rc/IrcClient.gd
signal error(err)
rc/IrcClient.gd

rc/IrcClient.gd
var _status: int = 0
rc/IrcClient.gd
var _stream: StreamPeerTCP = StreamPeerTCP.new()
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _ready() -> void:
rc/IrcClient.gd
	_status = _stream.get_status()
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _process(_delta: float) -> void:
rc/IrcClient.gd
	var new_status: int = _stream.get_status()
rc/IrcClient.gd
	if new_status != _status:
rc/IrcClient.gd
		_status = new_status
rc/IrcClient.gd
		match _status:
rc/IrcClient.gd
			_stream.STATUS_NONE:
rc/IrcClient.gd
				emit_signal("closed")
rc/IrcClient.gd
			_stream.STATUS_CONNECTED:
rc/IrcClient.gd
				emit_signal("connected")
rc/IrcClient.gd
			_stream.STATUS_ERROR:
rc/IrcClient.gd
				emit_signal("error", "TCP connection error")
rc/IrcClient.gd

rc/IrcClient.gd
	if _status == _stream.STATUS_CONNECTED:
rc/IrcClient.gd
		var available_bytes: int = _stream.get_available_bytes()
rc/IrcClient.gd
		if available_bytes > 0:
rc/IrcClient.gd
			var data: Array = _stream.get_partial_data(available_bytes)
rc/IrcClient.gd
			# Check for read error.
rc/IrcClient.gd
			if data[0] != OK:
rc/IrcClient.gd
				emit_signal("error", "TCP Error getting data from stream: " + str(data[0]))
rc/IrcClient.gd
			else:
rc/IrcClient.gd
				emit_signal("data_received", data[1].get_string_from_utf8())
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func connect_to_host(host: String, port: int) -> void:
rc/IrcClient.gd
	print("TCP Connecting to %s:%d" % [host, port])
rc/IrcClient.gd
	# Reset status so we can tell if it changes to error again.
rc/IrcClient.gd
	_status = _stream.STATUS_NONE
rc/IrcClient.gd
	if _stream.connect_to_host(host, port) != OK:
rc/IrcClient.gd
		emit_signal("error", "TCP Error connecting to host.")
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func send(data: String) -> bool:
rc/IrcClient.gd
	if _status != _stream.STATUS_CONNECTED:
rc/IrcClient.gd
		emit_signal("error", "TCP Error: Stream is not currently connected.")
rc/IrcClient.gd
		return false
rc/IrcClient.gd
	var error: int = _stream.put_data((data + "\r\n").to_utf8_buffer())
rc/IrcClient.gd
	if error != OK:
rc/IrcClient.gd
		emit_signal("error", "TCP Error: " + str(error))
rc/IrcClient.gd
		return false
rc/IrcClient.gd
	return true
