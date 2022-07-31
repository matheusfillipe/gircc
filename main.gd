# loudercake TODO implement /help and other commands like /quote /join /part /topic and whatever is already a function implemented on the bottom of IrcClient.gd

# loudercake TODO keep improving this gui

extends Control

const IrcClient = preload("res://irc/IrcClient.gd")
const StringUtils = preload("res://irc/StringUtils.gd")

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

enum Commands {
	KICK,
	MODE,
	HELP,
	CLEAR,
	ME,
	PART,
	NICK,
	JOIN,
	TOPIC,
	MSG,
	QUIT,
	OP,
	NAMES,
	QUOTE,
	LIST,
}

const command_prefix = "/"

const CMD_HELP = {
	Commands.KICK: "Usage: /kick <user> [reason]",
	Commands.HELP: "Usage: /help <command>",
	Commands.CLEAR: "Clears the screen",
	Commands.ME: "Sends a message as an action. Usage: /me <message>",
	Commands.PART: "Usage: /part <channel>",
	Commands.NICK: "Usage: /nick <new nickname.",
	Commands.JOIN: "Usage: /join <channel>",
	Commands.TOPIC: "Usage: /topic <topic>",
	Commands.MSG: "Usage: /msg <nick> <message>",
	Commands.QUIT: "Usage: /quit <message>",
	Commands.OP: "Usage: /op <nick>",
	Commands.LIST: "Usage: /names [channel]",
	Commands.QUOTE: "Usage: /quote <raw_irc_command>",
	Commands.LIST: "List channels in the server. Usage: /list [opt]",
}


func _ready():
	client = IrcClient.new(nick, nick, irc_url, websocket_url, channel)
	client.debug = debug
	var _n
	_n = client.connect("connected", self, "_connected")
	_n = client.connect("closed", self, "_closed")
	_n = client.connect("error", self, "_error")
	_n = client.connect("event", self, "_on_event")
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
		client.KICK:
			label.text += getnick(ev.nick) + ' was kicked by ' + getnick(ev.source) + ': ' + ev.message
			print(ev.channel)
		client.QUIT:
			label.text += getnick(ev.source) + " has quit.\n"
		client.PRIVMSG:
			label.text += ev.channel + " -> " + ev.nick + ": " + ev.message + "\n"
		client.PART:
			label.text += getnick(ev.source) + " has parted.\n"
		client.JOIN:
			label.text += getnick(ev.source) + " has joined.\n"
		client.ACTION:
			label.text += ev.channel + " -> " + ev.nick + ": " + "*" + ev.message + "*\n"
		client.NAMES:
			label.text += "Users in channel: " + str(ev.list) + "\n"
		client.NICK:
			if ev.source == client.nick:
				label.text += "You are now known as " + ev.nick + "\n"
				nick = ev.nick
			else:
				label.text += ev.source.split("!")[0] + " is now known as " + ev.nick + "\n"
		client.NICK_IN_USE:
			label.text += "That nickname is already in use!\n"
		client.TOPIC:
			var pre = ""
			if ev.nick:
				pre = "Topic set by " + ev.nick
			else:
				pre = "TOPIC"
			label.text += pre + ': "' + ev.message + '"\n'
		client.ERR_CHANPRIVSNEEDED:
			label.text += " -> Error: " + ev.message + "\n"
		client.LIST:
			for chan in ev.list:
				label.text += str(chan) + "\n"
			label.text += "\n\n"

	scrolldown()


func _input(ev):
	if ev.is_action_pressed("send"):
		_on_Send_pressed()


func help(cmd, suffix = ""):
	cmd = cmd.to_upper()
	if not cmd in Commands.keys():
		label.text += suffix + "No help for: /" + cmd + "\n"
		return
	var help_msg = CMD_HELP[Commands.keys().find(cmd)]
	label.text += suffix + "/" + cmd + ": " + help_msg + "\n"
	return


# Given a prefix will find if there is any or multiple corresponding commands with that prefix
func find_commands_from_prefix(prefix: String) -> PoolStringArray:
	prefix = prefix.to_upper()
	var can_be = PoolStringArray()
	for cmd in Commands.keys():
		if not cmd.to_upper().begins_with(prefix):
			continue
		can_be.append(cmd)
	return can_be


func _command(text):
	var whitespace_split = text.split(" ")
	var command = whitespace_split[0].trim_prefix(command_prefix)
	var args = PoolStringArray()

	if len(whitespace_split) > 1:
		args = text.trim_prefix(command_prefix + command + " ").split(" ")

	var arglen = len(args)
	command = command.to_upper()

	# Accept shortened prefixes for each command
	var can_be = find_commands_from_prefix(command)
	var cmd_id = -1
	if len(can_be) == 1:
		cmd_id = Commands.keys().find(can_be[0])
	elif len(can_be) > 1:
		label.text += " -> /" + command + " could be multiple commands: " + str(can_be) + "\n"
		return

	match cmd_id:
		Commands.HELP:
			if arglen > 0:
				help(args[0])

			for cmd in Commands.keys():
				label.text += command_prefix + cmd + "\n"
			label.text += "\n"
		Commands.KICK:
			if arglen > 1:
				client.kick(channel, args[0], args[1])
			else:
				client.kick(channel, args[0])
		Commands.MODE:
			client.mode(channel,args[1],nick)
		Commands.CLEAR:
			label.text = ""
		Commands.QUOTE:
			client.quote(StringUtils.join_from(args))
		Commands.ME:
			client.me(channel, StringUtils.join_from(args))
		Commands.PART:
			client.part(channel)
		Commands.TOPIC:
			match arglen:
				0:
					client.quote("TOPIC " + channel)
				_:
					client.topic(channel, StringUtils.join_from(args))
		Commands.NICK:
			client.set_nick(args[0])
		Commands.JOIN:
			client.join(args[0])
			channel = args[0]
		Commands.MSG:
			if arglen >= 2:
				client.send(args[0], StringUtils.join_from(args, 1))
			else:
				help(command, "Invalid number of arguments    -   ")
		Commands.QUIT:
			client.quit(StringUtils.join_from(args))
		Commands.OP:
			match arglen:
				1:
					client.op(channel, args[0])
				_:
					help(command, "Invalid number of arguments    -   ")
		Commands.LIST:
			client.list(StringUtils.join_from(args))

		_:
			label.text += "Unrecognized command: /" + command + "\n"


func _on_Send_pressed():
	for text in text_edit.text.split("\n"):
		if len(text) <= 0:
			continue

		# If is command
		if text.begins_with(command_prefix):
			_command(text)
			continue

		# Send message to current channel
		client.send(channel, text)
		label.text += channel + " -> " + nick + ": " + text + "\n"

	text_edit.text = ""
	scrolldown()


func scrolldown():
	var bar: VScrollBar = scroll_container.get_v_scrollbar()
	scroll_container.scroll_vertical = bar.max_value

func getnick(source):
	return source.split('!')[0]
