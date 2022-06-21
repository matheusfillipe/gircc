# TODO copy current main.gd to here, remove all the UI non and annoying comments
# TODO leave implemented signals: connected, disconnected, data_received
# TODO create the send method
# It is important that both backends implement the same signals with the same names and send method
# peepee poopoo

extends Node

# The URL we will connect to
export var websocket_url = "wss://irc.dot.org.es:7669"


var nick
var channel = "#romanian"
var sendstring = 'aadsadasd'
# Our WebSocketClient instance
var _client = WebSocketClient.new()

func _ready():
	if OS.has_environment("USERNAME"):
		nick = OS.get_environment("USERNAME")
	else:
		nick = "whatnick"


	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")

	# Initiate connection to the given URL.
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)


func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	set_process(false)

func send(text: String):
	_client.get_peer(1).put_packet((text + "\n").to_utf8())

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	send("nick " + nick)
	send("user " + nick + " * * :" + nick)

	# TODO wait for irc ready instead of this
	yield(get_tree().create_timer(2, false), "timeout")
	send("join " + channel)

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	print("Got data from server: ", data)
	var first = data.split(" ")[0]
	if first == "PING":
		return send(data.replace("PI", "PO"))


func _process(_delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()

#todo make 
