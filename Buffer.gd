extends Control
var channel
onready var scroll = $ScrollContainer/VBoxContainer

const COLORS = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"]


# TODO parse irc colors, special texts
func _parse_irc_text(text):
	var parsed = text
	return parsed

func add_message(text, nick=null, color=null):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content_height = true
	label.scroll_active = false
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_EXPAND_FILL
	label.rect_min_size.x = get_parent().get_size().x

	var _text = ""
	if nick != null:
		# choose color from hash
		var _color = COLORS[hash(nick) % len(COLORS)]
		_text += "[color=%s][b]%s[/b][/color]: " % [_color, nick]
	if color != null:
		print("Color is not null")
		_text += "[color=" + color + "]" + text + "[/color]"
	else:
		_text += _parse_irc_text(text)
	label.bbcode_text = _text
	scroll.add_child(label)
