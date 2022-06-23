### Work in progress


# Godot irc client

This is a fully features irc client for godot support non encrypted (commonly port tcp 6667) and ssl encrypted (commonly tcp 6697) connections. It also supports websockets (also both ws and wss) which is useful for web exports. If your irc server doesn't support websockets natively or with a module/plugin then check this [other project of mine](https://github.com/matheusfillipe/ws2irc).

**Attention** Currently this is not ensuring the validity of the ssl certificates for the irc over tcp backend.

## What is irc
IRC is the Internet Relay Chat. It is one of the simplest, more awesome and also one of the oldest chatting protocols:

> Internet Relay Chat (IRC) is a text-based chat system for instant messaging. IRC is designed for group communication in discussion forums, called channels, but also allows one-on-one communication... :: 

https://en.wikipedia.org/wiki/Internet_Relay_Chat

Take a look at [this link](https://datatracker.ietf.org/doc/html/rfc1459) to learn more about the protocol and what is supported.

If you are looking for a irc server I recommend [Unrealircd](https://www.unrealircd.org/) which as a websocket module.

## How to use this as chat a plugin

**Work in progress**


## How to use this as a library

Simply copy the [irc/](https://github.com/matheusfillipe/gircc/tree/master/irc) folder into your project and preload the `IrcClient` script and initialize it like:

``` gdscript
const IrcClient = preload("res://irc/IrcClient.gd")
var client

func _ready():
   # You can still pass respectively a websocket url that will be used on html exports and a channel to login automatically
	client = IrcClient.new("nickname", "username", "ircs://irc.myserver.com:6697")
	client.debug = true
	client.connect("connected", self, "_connected")
	client.connect("event", self, "_on_event")
   
func _connected():
   client.join("#channel")
   
   
func _on_event(ev):
   # The event (ev) object can contain the attributes: 'message', 'names', 'nick', 'topic', 'channel'...
   # depending of the type. It is guaranteed to always have the 'type' attribute
	match ev.type:
		client.PRIVMSG:
         # Do something with ev.message and ev.channel
            pass
		client.PART:
         # Do something with ev.channel
            pass
		client.JOIN:
         # Do something with ev.channel
            pass
		client.ACTION:
         # Do something with ev.message and ev.channel
			pass
		client.NAMES:
         # Do something with ev.names and ev.channel
			pass
		client.NICK:
         # Do something with ev.nick
			pass
		client.NICK_IN_USE:
         # Do something with ev.nick
			pass
		client.TOPIC:
         # Do something with ev.topic and ev.channel
			pass
		client.KICK:
         # Do something with ev.nick and ev.channel
			pass
         
      # And there is more....

```


# Resources

- Websocket godot documentation: https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html

- TCP stream godot documentation: https://docs.godotengine.org/en/stable/classes/class_streampeertcp.html

- Nice tutorial for tcp in godot: https://www.bytesnsprites.com/posts/2021/creating-a-tcp-client-in-godot/

- Simple irc client in javascript: https://github.com/matheusfillipe/irc.js/blob/master/irc.js



# TODO

- [x] Separated irc backends that implement send, emit signal on message, basic text decoding
   - [x] websocket backend
   - [x] tcp backend
   - [x] tcp ssl backend
- [ ] Irc protocol parser
   - [x] Basic parser
   - [ ] Actions (emote), other's join, other's part
   - [ ] topic, mode, other users nick change and mode change, user kicked, banned
   - [ ] https://datatracker.ietf.org/doc/html/rfc1459
- [x] irc client that accepts one of the backends 
- [ ] Better UI
- [ ] Maybe turn this into a plugin/add on/lib

