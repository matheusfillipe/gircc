extends Node

var host_uri: String

signal closed
signal connected
signal data_received(data)
signal on_error(err)

var tcp: StreamPeerTCP = StreamPeerTCP.new()
var tcp_connected: bool = false
var erroed: bool = false
var _status: int = 0
var _stream: StreamPeerTLS = StreamPeerTLS.new()


func _ready() -> void:
	_status = _stream.get_status()


func _process(_delta: float) -> void:
	if erroed:
		return

	tcp.poll()
	if not tcp_connected and tcp.get_status() == _stream.STATUS_CONNECTED:
		tcp_connected = true
		var error = _stream.connect_to_stream(tcp)
		if error != OK:
			on_error.emit("TCP + SSL Error upgrading connection to SSL: " + str(error))
			print("TCP + SSL Error upgrading connection to SSL: " + str(error))
			erroed = true
			return
		print("TCP + SSL Connected")

	_stream.poll()
	var new_status: int = _stream.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			_stream.STATUS_DISCONNECTED:
				closed.emit()
			_stream.STATUS_CONNECTED:
				connected.emit()
			_stream.STATUS_ERROR:
				on_error.emit("TCP + SSL connection on_error")

			_stream.STATUS_HANDSHAKING:
				print("Performing SSL handshake with host.")
			_stream.STATUS_ERROR_HOSTNAME_MISMATCH:
				on_error.emit("Error with socket stream: Hostname mismatch.")

	if _status == _stream.STATUS_CONNECTED:
		_stream.poll()
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			var data: Array = _stream.get_partial_data(available_bytes)
			# Check for read on_error.
			if data[0] != OK:
				on_error.emit("TCP Error getting data from stream: " + str(data[0]))
			else:
				data_received.emit(data[1].get_string_from_utf8())


func connect_to_host(host: String, port: int) -> void:
	print("TCP + SSL Connecting to %s:%d" % [host, port])
	# Reset status so we can tell if it changes to on_error again.
	_status = _stream.STATUS_DISCONNECTED
	var error: int = tcp.connect_to_host(host, port)
	if error != OK:
		on_error.emit("TCP + SSL Error connecting to host: " + str(error))
		print("TCP + SSL Error connecting to host: " + str(error))


func send(data: String) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		on_error.emit("TCP Error: Stream is not currently connected.")
		return false
	var error: int = _stream.put_data((data + "\r\n").to_utf8_buffer())
	if error != OK:
		on_error.emit("TCP Error: " + str(error))
		return false
	return true
