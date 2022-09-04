extends Control
var channel
onready var scroll = $ScrollContainer/VBoxContainer

const COLORS = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"]
const ColorEscape = "\u0003";
const BoldEscape = "";
const ItalicEscape = "";
const UnderlineEscape = "";


# TODO parse irc colors, special texts
func _parse_irc_text(text):
	var parsed = ""
	var italic = false
	var bold = false
	var underline = false
	for c in text:
		if c == ColorEscape:
			pass
		elif c == BoldEscape:
			if bold:
				parsed += "[/b]"
			else:
				parsed += "[b]"
			bold = !bold
		elif c == ItalicEscape:
			if italic:
				parsed += "[/i]"
			else:
				parsed += "[i]"
			italic = !italic
		elif c == UnderlineEscape:
			if underline:
				parsed += "[/u]"
			else:
				parsed += "[u]"
			underline = !underline
		else:
			parsed += c

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
