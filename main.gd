# loudercake TODO implement /help and other commands like /quote /join /part /topic and whatever is already a function implemented on the bottom of IrcClient.gd

# loudercake TODO keep improving this gui

extends Control

const IrcClient = preload("res://irc/IrcClient.gd")

# The URL we will connect to
# export var irc_url = "irc.dot.org.es"
export var irc_url = "ircs://irc.dot.org.es:6697"
export var websocket_url = "wss://irc.dot.org.es:7669"
export var channel = "#romanian"
export(bool) var debug = true
export var nick = "godot"

onready var scroll_container = $ScrollContainer
onready var label = $ScrollContainer/Label
onready var text_edit = $TextEdit

var client: IrcClient

func _ready():
	client = IrcClient.new(nick, nick, irc_url, websocket_url, channel)
	client.debug = debug
	client.connect("connected", self, "_connected")
	client.connect("closed", self, "_closed")
	client.connect("error", self, "_error")
	client.connect("event", self, "_on_event")
	add_child(client)

	text_edit.grab_focus()

func _error(err):
	print(err)

func _connected():
	# TODO do something? a green led?
	print("GUI: irc connected")
	label.text += "CONNECTED...\n\n\n"

func _on_event(ev):
	match ev.type:
		client.PRIVMSG:
			label.text += ev.channel + " -> " + ev.nick + ": " + ev.message + "\n"
			scrolldown()
		client.PART:
			label.text += "LEFT " + ev.channel + "\n"
		client.JOIN:
			label.text += "JOINED " + ev.channel + "\n"
		client.ACTION:
			pass
		client.NAMES:
			pass
		client.NICK:
			pass
		client.NICK_IN_USE:
			pass

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
