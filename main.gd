extends Control

var IrcClient = preload("res://irc/IrcClient.gd")
var StringUtils = preload("res://irc/StringUtils.gd")

# The URL we will connect to
# export var irc_url = "irc.dot.org.es"
@export var server: String = "irc.dot.org.es"
@export var irc_url: String = "ircs://irc.dot.org.es:6697"
@export var websocket_url: String = "wss://irc.dot.org.es:7669"
@export var channel: String = "#romanian"
@export var debug: bool = true
@export var nick: String = "godot"

@onready var tab_container = $TabContainer
@onready var text_edit = $TextEdit
var client: IrcClient
var buffers: Dictionary
var currentchannel: String

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
	Commands.NAMES: "Usage: /names [channel]",
	Commands.QUOTE: "Usage: /quote <raw_irc_command>",
	Commands.LIST: "List channels in the server. Usage: /list [opt]"
}


func _ready():
	client = IrcClient.new(nick, nick, irc_url, websocket_url, channel)
	client.debug = debug
	var _n
	_n = client.connected.connect(self._connected)
	_n = client.closed.connect(self._closed)
	_n = client.error.connect(self._error)
	_n = client.event.connect(self._on_event)
	add_child(client)

	text_edit.grab_focus()
	create_buffer(server)


func _error(err):
	print(err)


func _closed():
	add_text("Connection closed.")


func _connected():
	print("GUI: irc connected")
	buffers[server].add_message("CONNECTED...", null, "red")


func _on_event(ev):
	match ev.type:
		client.MODE:
			add_text(
				getnick(ev.source) + " has set mode " + ev.mode + " on channel " + ev.channel + "",
				ev.channel
			)
		client.KICK:
			add_text(
				getnick(ev.nick) + " was kicked by " + getnick(ev.source) + ": " + ev.message + "",
				ev.channel
			)
			print(ev.channel)
		client.QUIT:
			add_text(getnick(ev.source) + " has quit.", ev.channel)
		client.PRIVMSG:
			buffers[ev.channel].add_message(ev.message, ev.nick)
		client.PART:
			add_text(getnick(ev.source) + " has parted " + ev.channel + ".", ev.channel)
		client.JOIN:
			if getnick(ev.source) == nick:
				create_buffer(ev.channel)
			else:
				add_text(getnick(ev.source) + " has joined.", ev.channel)
		client.ACTION:
			add_text(ev.channel + " -> " + ev.nick + ": " + "*" + ev.message + "*", ev.channel)
		client.NAMES:
			add_text("Users in channel: " + str(ev.list) + "", ev.channel)
			if ev.channel in buffers:
				buffers[ev.channel].add_nicks(ev.list)
		client.NICK:
			if ev.source == client.nick:
				add_text("You are now known as " + ev.nick + "", ev.channel)
				nick = ev.nick
			else:
				add_text(ev.source.split("!")[0] + " is now known as " + ev.nick + "", ev.channel)
		client.NICK_IN_USE:
			add_text("That nickname is already in use!", ev.channel)
		client.TOPIC:
			var pre = ""
			if ev.nick:
				pre = "Topic set by " + ev.nick
			else:
				pre = "TOPIC"
			add_text(pre + ': "' + ev.message + '"', ev.channel)
		client.ERR_CHANPRIVSNEEDED:
			add_text(" -> Error: " + ev.message + "", ev.channel)
		client.LIST:
			for chan in ev.list:
				add_text(str(chan) + "")
			add_text("")

	buffers[currentchannel].scroll_to_bottom()


func _input(ev):
	if ev.is_action_pressed("send"):
		_on_Send_pressed()


func help(cmd, suffix = ""):
	cmd = cmd.to_upper()
	if not cmd in Commands.keys():
		add_text(suffix + "No help for: /" + cmd + "")
		return
	var help_msg = CMD_HELP[Commands.keys().find(cmd)]
	add_text(suffix + "/" + cmd + ": " + help_msg + "")
	return


# Given a prefix will find if there is any or multiple corresponding commands with that prefix
func find_commands_from_prefix(prefix: String) -> PackedStringArray:
	prefix = prefix.to_upper()
	var can_be = PackedStringArray()
	for cmd in Commands.keys():
		if not cmd.to_upper().begins_with(prefix):
			continue
		can_be.append(cmd)
	return can_be


func _command(text):
	var whitespace_split = text.split(" ")
	var command = whitespace_split[0].trim_prefix(command_prefix)
	var args = PackedStringArray()

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
		add_text(" -> /" + command + " could be multiple commands: " + str(can_be) + "")
		return

	match cmd_id:
		Commands.HELP:
			if arglen > 0:
				help(args[0])

			for cmd in Commands.keys():
				add_text(command_prefix + cmd + "")
			add_text("")
		Commands.KICK:
			if arglen > 1:
				client.kick(currentchannel, args[0], args[1])
			else:
				client.kick(currentchannel, args[0])
		Commands.MODE:
			client.mode(currentchannel, args[1], nick)
		Commands.CLEAR:
			buffers[currentchannel].clear()
		Commands.QUOTE:
			client.quote(StringUtils.join_from(args))
		Commands.ME:
			client.me(currentchannel, StringUtils.join_from(args))
		Commands.PART:
			client.part(currentchannel)
			delete_buffer(currentchannel)
		Commands.TOPIC:
			match arglen:
				0:
					client.quote("TOPIC " + currentchannel)
				_:
					client.topic(currentchannel, StringUtils.join_from(args))
		Commands.NICK:
			client.set_nick(args[0])
		Commands.JOIN:
			client.join(args[0])
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
					client.op(currentchannel, args[0])
				_:
					help(command, "Invalid number of arguments    -   ")
		Commands.LIST:
			client.list(StringUtils.join_from(args))

		_:
			add_text("Unrecognized command: /" + command + "")


func _on_Send_pressed():
	for text in text_edit.text.split(""):
		if len(text) <= 0:
			continue

		# If is command
		if text.begins_with(command_prefix):
			_command(text)
			continue

		# Send message to current channel
		client.send(currentchannel, text)
		buffers[currentchannel].add_message(text, nick)

	text_edit.text = ""
	buffers[currentchannel].scroll_to_bottom()


func getnick(source):
	return source.split("!")[0]


func add_text(text, channelname = ''):
	if channelname[0] == '#':
		buffers[channelname].add_message(text)
	else:
		buffers[server].add_message(text)


func create_buffer(channel):
	var buffer = preload("res://Buffer.tscn").instantiate()
	buffer.channel = channel
	buffers[channel] = buffer
	buffer.set_name(channel)
	tab_container.add_child(buffer)
	tab_container.set_current_tab(len(tab_container.get_children()) - 1)


func delete_buffer(channel):
	tab_container.remove_child(buffers[channel])
	tab_container.set_current_tab(len(tab_container.get_children()) - 1)
	var current_buffer = tab_container.get_current_tab_control()
	if current_buffer:
		currentchannel = current_buffer.channel
	else:
		currentchannel = server
		tab_container.set_current_tab(0)


func _on_TabContainer_tab_changed(tab):
	currentchannel = tab_container.get_tab_control(tab).channel

# Ctrl + W Closes the current tab
func _unhandled_input(event):
	if event is InputEventKey:
		print(event.get_keycode_with_modifiers())
		if event.pressed and event.keycode == KEY_W:
			delete_buffer(currentchannel)
