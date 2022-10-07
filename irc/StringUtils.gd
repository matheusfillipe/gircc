rc/IrcClient.gd
extends Object
rc/IrcClient.gd

rc/IrcClient.gd

rc/IrcClient.gd
# Join an array from strings starting from the given start_index
rc/IrcClient.gd
static func join_from(args: Array, start_index = 0) -> String:
rc/IrcClient.gd
	var string = ""
rc/IrcClient.gd
	var i = -1
rc/IrcClient.gd

rc/IrcClient.gd
	for word in args:
rc/IrcClient.gd
		i += 1
rc/IrcClient.gd
		if i < start_index:
rc/IrcClient.gd
			continue
rc/IrcClient.gd
		string += word + " "
rc/IrcClient.gd
	return string
