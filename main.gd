# loudercake TODO implement /help and other commands like /quote /join /part /topic and whatever is already a function implemented on the bottom of IrcClient.gd

# loudercake TODO keep improving this gui

extends Control

var IrcClient = load("res://irc/IrcClient.gd")

# The URL we will connect to
export var irc_url = "irc.dot.org.es"
export var websocket_url = "wss://irc.dot.org.es:7669"
export var channel = "#romanian"
export(bool) var debug = true
export var nick = "godot"

onready var scroll_container = $ScrollContainer
onready var label = $ScrollContainer/Label
onready var text_edit = $TextEdit

var client

func _ready():
	client = IrcClient.new(nick, nick, irc_url, websocket_url, channel)
	client.debug = debug
	client.connect("closed", self, "_closed")
	client.connect("joined", self, "_joined")
	client.connect("parted", self, "_parted")
	client.connect("connected", self, "_connected")
	client.connect("error", self, "_error")
	client.connect("message", self, "_on_message")
	add_child(client)

	text_edit.grab_focus()

func _error(err):
	print(err)

func _connected():
	# TODO do something? a green led?
	print("GUI: irc connected")
	label.text += "CONNECTED...\n\n\n"

func _joined(_channel):
	label.text += "JOINED " + _channel + "\n"

func _parted(_channel):
	label.text += "LEFT " + _channel + "\n"

func _on_message(_channel, from_nick, message):
	label.text += _channel + " -> " + from_nick + ": " + message + "\n"
	scrolldown()

func _input(ev):
		if ev.is_action_pressed("send"):
			_on_Send_pressed()

func _on_Send_pressed():
	for text in text_edit.text.split("\n"):
		if len(text) > 0:
			client.send(channel, text)
			label.text += channel + " -> " + nick + ": " + text + "\n"
	text_edit.text = ""
	scrolldown()

func scrolldown():
	var bar: VScrollBar = scroll_container.get_v_scrollbar();
	scroll_container.scroll_vertical = bar.max_value;
