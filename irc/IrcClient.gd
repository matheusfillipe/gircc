# TODO implement a basic irc client like from https://github.com/matheusfillipe/irc.js/blob/master/irc.js
# TODO work with both ws://domain:port and just domain:port urls choosing the backend acordingly and fallback to ws always if on html5 export.

extends Node
var WSBackend = preload("res://irc/WSBackend.gd")
var TCPBackend = preload("res://irc/WSBackend.gd")







# TODO this is how this will be meant to be used:
# var client = Client.new()
# client.host = "irc.dot.org.es:6667"
# client.wshost = "ws://irc.dot.org.es:7666"
# client.nick = "testman"  # use same for 3 usernames if not provided
# client.username = "something"
# client.connect("connected", self, "_on_client_connected")
# client.connect("joined", self, "_on_client_joined")
# client.connect("on_message", self, "_on_client_message")
# ...
# client.privmsg(channel, message)


# TODO think about ssl support, might work for websocket but not for tcp backend
