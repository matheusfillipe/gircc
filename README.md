# Godot irc client

Work in progress

# Development

https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html

https://docs.godotengine.org/en/stable/classes/class_streampeertcp.html

https://www.bytesnsprites.com/posts/2021/creating-a-tcp-client-in-godot/

Simple irc client example: https://github.com/matheusfillipe/irc.js/blob/master/irc.js



# TODO

- [x] Separated irc backends that implement send, emit signal on message, basic text decoding
   - [x] websocket backend
   - [x] tcp backend
   - [ ] tcp ssl backend
- [ ] Irc protocol parser
   - [x] Basic parser
   - [ ] Actions (emote), other's join, other's part
   - [ ] topic, mode, other users nick change and mode change, user kicked, banned
   - [ ] https://datatracker.ietf.org/doc/html/rfc1459
- [x] irc client that accepts one of the backends 
- [ ] Better UI
- [ ] Maybe turn this into a plugin/add on/lib

