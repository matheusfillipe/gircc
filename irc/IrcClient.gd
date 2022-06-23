extends Node

const WSBackend = preload("res://irc/WSBackend.gd")
const TCPBackend = preload("res://irc/TCPBackend.gd")
const TCPSBackend = preload("res://irc/TCPSBackend.gd")

enum Proto {
	WS
	WSS
	TCP
	TCPS
}

# Events
enum {
	PRIVMSG
	ACTION
	JOIN
	NAMES
	PART
	NICK
	NICK_IN_USE
}

class Event:
	var names = PoolStringArray()
	var message = ""
	var nick = ""
	var topic = ""
	var channel = ""
	var type: int

	func _init(attrs: Dictionary):
		if not "type" in attrs:
			push_error("Event requires type.")
		for key in attrs:
			set(key, attrs[key])


var host: String
var ws_host: String
var nick: String
var username: String
var autojoin_room: String
var port: int
var proto: int
var connected: bool = false
var debug: bool = false

# Either WSBackend ot TCPBackend
var backend

signal connected
signal error(message)
signal event(_event)
signal closed


var init = false


################################################################################
# Creates a new irc client object.
#
# _nick: Client irc nickname
# _username: Client irc username
#
# _host: Can be a webscoket address or irc address. The protoccol must be specified example with default ports:
# irc://irc.example.com:6667
# ircs://irc.example.com:6697
# ws://irc.example.com:7666
# wss://irc.example.com:7669
#
# Those default ports will be used when ommited.
#
# _ws_host: Optional. Fallback websocket host to use. Useful for html5 compatible exports.
#
# _autojoin_room: Optional. Automatically join this room on connect.
func _init(_nick: String, _username: String, _host: String, _ws_host: String = "", _autojoin_room: String = ""):
	nick = _nick
	username = _username
	host = _host
	ws_host = _ws_host
	autojoin_room = _autojoin_room

	# WS fallback for html
	if OS.get_name() == "HTML5" and len(ws_host) > 0:
		print("Falling back to websocket backend")
		host = ws_host

	# Parse uri, load defaults
	var split_uri = host.split(":")
	match len(split_uri):
		1:
			host = host
			proto = Proto.TCP
			port = 6667
		2:
			host = split_uri[0]
			port = int(split_uri[1])
			proto = Proto.TCP
		3:
			host = split_uri[1].trim_prefix("//").trim_prefix("/")
			port = int(split_uri[2])

			var scheme = split_uri[0]
			match scheme:
				"irc":
					proto = Proto.TCP
				"ircs":
					proto = Proto.TCPS
				"ws":
					proto = Proto.WS
				"wss":
					proto = Proto.WSS
				_ :
					push_error("Unrecognized uri")

		_:
			push_error("Unrecognized uri")


	match OS.get_name():
		"HTML5":
			if not proto in [Proto.WS, Proto.WSS]:
				push_error("TCP is not supported in html5 exports. Use websockets or ws_host as a fallback!")

	# Create backend
	match proto:
		Proto.TCP:
			backend = TCPBackend.new()
			backend.connect_to_host(host, port)

		Proto.TCPS:
			backend = TCPSBackend.new()
			backend.connect_to_host(host, port)

		Proto.WS:
			backend = WSBackend.new()
			backend.host_uri = "ws://" + host + ":" + str(port)

		Proto.WSS:
			backend = WSBackend.new()
			backend.host_uri = "wss://" + host + ":" + str(port)


	# Bind and Connect
	backend.connect("closed", self, "_closed")
	backend.connect("data_received", self, "_data")
	backend.connect("error", self, "_error")
	backend.connect("connected", self, "_connected")
	add_child(backend)

func _closed():
	emit_signal("closed")

func _error(err):
	emit_signal("error", err)

func _connected():
	if connected:
		return
	quote("nick " + nick)
	quote("user " + username + " * * :" + username)
	emit_signal("connected")
	connected = true


func _data(data):
	_connected()
	for msg in data.split("\r\n"):
		if len(msg) == 0:
			continue

		if debug:
			print("<<< ", msg)

		if msg.split(" ")[0] == "PING":
			quote(msg.replace("PI", "PO"))
			continue

		irc_parse(msg)

############################
# Parse irc protocool
func irc_parse(data):
	var irc_code = data.split(" ")[1]
	if not init && irc_code == "376":
		init = true
		if len(autojoin_room) > 0:
			quote("join " + autojoin_room)

	if init:
		var type = data.split(" ")[1]

		match type:
			"PRIVMSG":
				var channel = data.split(" ")[2]
				var from_nick = data.split(":")[1].split("!")[0]
				var message = data.split(":")[-1]
				emit_signal("event", Event.new({"type": PRIVMSG, "channel": channel, "nick": from_nick, "message": message}))

			"JOIN":
				var channel = data.split(":")[2].strip_edges()
				emit_signal("event", Event.new({"type": JOIN, "channel": channel}))

			"NICK":
				var new_nick = data.split(":")[2]
				emit_signal("event", Event.new({"type": NICK, "nick": new_nick}))

			"PART":
				var channel = data.split(" ")[2]
				emit_signal("event", Event.new({"type": PART, "channel": channel}))

			_ :
				match (irc_code):
					"433":
						emit_signal("event", Event.new({"type": NICK_IN_USE}))

					"353":
						var channel = data.split("=")[1].split(" ")[1]
						var names = data.split(":")[-1].split(" ")
						emit_signal("event", Event.new({"type": NAMES, "channel": channel, "names": names}))


	elif (irc_code == "433"):
		nick = nick + "_"
		set_nick(nick)


# Send raw message to irc backend server
func quote(message: String):
	message = message.replace("\n", "")
	if debug:
		print(">>> ", message)
	backend.send(message)

# Sends a private message or a message to a channel
func send(nick_or_channel: String, message: String):
	quote("PRIVMSG %s :%s" % [nick_or_channel, message])

# Changes the nick of the client
# Capture the result with the "nick_changed" signal
func set_nick(new_nick: String):
	quote("nick %s" % [new_nick])

# Joins a channel
# Capture the result with the "joined" signal
func join(channel: String):
	quote("JOIN %s" % [channel])

# Leaves a channel
# Capture the result with the "parted" signal
func part(channel: String):
	quote("PART %s" % [channel])

# Quits the irc server
func quit(message: String):
	quote("QUIT :%s" % [message])

# Changes the mode for a specific channel
# TODO Capture the result with the "mode" signal
func mode(channel: String, mode: String):
	quote("MODE %s %s" % [channel, mode])

# Kicks a user from a channel with a message
# TODO Capture the result with the "kick" signal
func kick(channel: String, _nick: String, message: String):
	quote("KICK %s %s :" % [channel, _nick, message])

# Changes the topic of a channel
# TODO Capture the result with the "topic" signal
func topic(channel: String, topic: String):
	quote("TOPIC %s :%s" % [channel, topic])

# Gets a list of names from the current channel
# Capture the result with the "names" signal
func names(channel: String):
	quote("NAMES %s" % [channel])
