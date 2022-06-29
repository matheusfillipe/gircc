extends Object


# Join an array from strings starting from the given start_index
static func join_from(args: Array, start_index = 0) -> String:
	var string = ""
	var i = -1

	for word in args:
		i += 1
		if i < start_index:
			continue
		string += word + " "
	return string
