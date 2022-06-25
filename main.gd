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

func _closed():
	label.text += "Connection closed.\n\n"

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
			label.text += ev.channel + " -> " + ev.nick + ": " + "*" + ev.message + "*\n"
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
			if text.begins_with('/'):
				
				var capscommand = text.split(' ')[0].to_upper().trim_prefix('/')
				var command = text.split(' ')[0]
				var args = get_args(text.split(' ')[0], text)
				var joinedargs = join_args(args)
				print(command)
				match capscommand:
					"CLEAR":
						label.text = ''
					"ME":
						client.me(channel, joinedargs)
					"PART":
						client.part(channel)
					"NICK":
						client.set_nick(args[0])
					"JOIN":
						client.join(args[0])
					"TOPIC":
						client.topic(channel,joinedargs)
					"QUIT":
						client.quit(joinedargs)
				text_edit.text = ""
				return
			client.send(channel, text)
			label.text += channel + " -> " + nick + ": " + text + "\n"
	text_edit.text = ""
	scrolldown()
func get_args(command, string):
	var newstring = string.trim_prefix(command)
	print(newstring)
	var array = []
	for args in newstring.lstrip(newstring.split(' ')[0]+' '):
		array.append(args)
	return array
func join_args(args):
	var string = ''
	for i in args:
		string += i
	return string
func scrolldown():
	var bar: VScrollBar = scroll_container.get_v_scrollbar();
	scroll_container.scroll_vertical = bar.max_value;
