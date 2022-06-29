extends Node

var _client = WebSocketClient.new()
var host_uri: String

signal closed
signal connected
signal data_received(data)
signal error(err)


func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")

	# Initiate connection to the given URL.
	var err = _client.connect_to_url(host_uri)
	if err != OK:
		emit_signal("error", "WS Unable to connect")
		set_process(false)


func _closed(_was_clean = false):
	emit_signal("closed")
	set_process(false)


func send(text: String):
	_client.get_peer(1).put_packet((text + "\r\n").to_utf8())


func _connected(_proto = ""):
	emit_signal("connected")


func _on_data():
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	emit_signal("data_received", data)


func _process(_delta):
	_client.poll()
