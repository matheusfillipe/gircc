rc/IrcClient.gd
extends Node
rc/IrcClient.gd

rc/IrcClient.gd
var _client = WebSocketClient.new()
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

rc/IrcClient.gd
func _ready():
rc/IrcClient.gd
	# Connect base signals to get notified of connection open, close, and errors.
rc/IrcClient.gd
	_client.connect("connection_closed", self._closed)
rc/IrcClient.gd
	_client.connect("connection_error", self._closed)
rc/IrcClient.gd
	_client.connect("connection_established", self._connected)
rc/IrcClient.gd
	_client.connect("data_received", self._on_data)
rc/IrcClient.gd

rc/IrcClient.gd
	# Initiate connection to the given URL.
rc/IrcClient.gd
	var err = _client.connect_to_url(host_uri)
rc/IrcClient.gd
	if err != OK:
rc/IrcClient.gd
		emit_signal("error", "WS Unable to connect")
rc/IrcClient.gd
		set_process(false)
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _closed(_was_clean = false):
rc/IrcClient.gd
	emit_signal("closed")
rc/IrcClient.gd
	set_process(false)
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func send(text: String):
rc/IrcClient.gd
	_client.get_peer(1).put_packet((text + "\r\n").to_utf8_buffer())
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _connected(_proto = ""):
rc/IrcClient.gd
	emit_signal("connected")
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _on_data():
rc/IrcClient.gd
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
rc/IrcClient.gd
	emit_signal("data_received", data)
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
func _process(_delta):
rc/IrcClient.gd
	_client.poll()
