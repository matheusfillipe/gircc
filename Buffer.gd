extends Control
var channel
var nicks = {}
onready var scroll_container = $ScrollContainer
onready var scroll = $ScrollContainer/VBoxContainer

var is_scrolled_up = false

const IRC_SPECIAL_NICK_PREFIES = ["@", "+", "%", "&", "~"]
const COLORS = [
	"#ff0000",
	"#00ff00",
	"#0000ff",
	"#ffff00",
	"#00ffff",
	"#ff00ff",
	"#ff8000",
	"#ff0080",
	"#8000ff",
	"#0080ff",
	"#ff8000",
	"#ff0080",
]

const ColorEscape = "\u0003"
const BoldEscape = ""
const ItalicEscape = ""
const UnderlineEscape = ""


class Colors:
	const white = "00"
	const black = "01"
	const navy = "02"
	const green = "03"
	const red = "04"
	const maroon = "05"
	const purple = "06"
	const orange = "07"
	const yellow = "08"
	const light_green = "09"
	const teal = "10"
	const cyan = "11"
	const blue = "12"
	const magenta = "13"
	const gray = "14"
	const light_gray = "15"

var color_map = {
	Colors.white: "#ffffff",
	Colors.black: "#000000",
	Colors.navy: "#00007f",
	Colors.green: "#009300",
	Colors.red: "#ff0000",
	Colors.maroon: "#7f0000",
	Colors.purple: "#9c009c",
	Colors.orange: "#fc7f00",
	Colors.yellow: "#ffff00",
	Colors.light_green: "#00fc00",
	Colors.teal: "#009393",
	Colors.cyan: "#00ffff",
	Colors.blue: "#0000fc",
	Colors.magenta: "#ff00ff",
	Colors.gray: "#7f7f7f",
	Colors.light_gray: "#d2d2d2",
	}


func _ready():
	scroll_container.get_v_scrollbar().connect("value_changed", self, "on_scroll")


func add_nicks(nicknames):
	for nickname in nicknames:
		for prefix in IRC_SPECIAL_NICK_PREFIES:
			if nickname.begins_with(prefix):
				nickname = nickname.substr(1, nickname.length())
				break
		nicks[nickname] = COLORS[hash(nickname) % len(COLORS)]

# Determines irc color code from 2 character strings
func _irc_color(color: String) -> String:
	if color in color_map:
		return color_map[color]
	if "0" + color[0] in color_map:
		return color_map["0" + color[0]]
	return "#ffffff"



# HACK bbcode is hacky, change this to use add_text, push_bold, push_color, etc...
func _parse_irc_text(text):
	var parsed = ""
	var italic = false
	var bold = false
	var underline = false
	var current_color = null
	var background_color = null
	var stack = []
	var i = 0
	while i < text.length():
		var c = text[i]

		match c:

			BoldEscape:
				if bold:
					parsed += stack.pop_back()
				else:
					parsed += "[b]"
					stack.append("[/b]")
				bold = !bold

			ItalicEscape:
				if italic:
					parsed += stack.pop_back()
				else:
					parsed += "[i]"
					stack.append("[/i]")
				italic = !italic

			UnderlineEscape:
				if underline:
					parsed += stack.pop_back()
				else:
					parsed += "[u]"
					stack.append("[/u]")
				underline = !underline

			ColorEscape:
				if background_color != null:
					parsed += stack.pop_back()
					background_color = null
				elif current_color != null:
					parsed += stack.pop_back()
					current_color = null
				else:
					if text[i+1] == ",":
						# Just background
						var bgcolor = _irc_color(text.substr(i + 2, 2))
						parsed += "[background=" + bgcolor + "]"
						stack.append("[/background]")
						background_color = bgcolor
						i += 3

					else:
						# Foreground color
						var color = _irc_color(text.substr(i + 1, 2))
						parsed += "[color=" + color + "]"
						current_color = color
						stack.append("[/color]")
						i += 2

						if text[i+1] == ",":
							# Foreground and background
							var bgcolor = _irc_color(text.substr(i + 2, 2))
							parsed += "[background=" + bgcolor + "]"
							stack.append("[/background]")
							background_color = bgcolor
							i += 3

			_:
				parsed += c

		i += 1

	# pop_back all remaining tags
	while stack.size() > 1:
		parsed += stack.pop_back()

	return parsed


func add_message(text, nick = null, color = null):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content_height = true
	label.scroll_active = false
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_EXPAND_FILL
	label.rect_min_size.x = get_parent().get_size().x
	label.selection_enabled = true

	var _text = ""
	var prefix = ""

	# Escape bbcode
	text = text.replace("[", "[\u200b")
	text = text.replace("]", "]\u200b")

	if nick != null:  # choose color from hash
		var _color = COLORS[hash(nick) % len(COLORS)]
		prefix += "[color=%s][b]%s[/b][/color]: " % [_color, nick]
	if color != null:
		_text += "[color=" + color + "]" + text + "[/color]"
	else:
		_text += _parse_irc_text(text)

	if color != null:
		for nick in nicks:
			var regex = RegEx.new()
			regex.compile("\\b" + nick + "\\b")
			_text = regex.sub(_text, "[color=" + nicks[nick] + "]" + nick + "[/color]", true)

	_text = prefix + _text
	label.bbcode_text = _text
	scroll.add_child(label)


func _max_scrollbar_value():
	return scroll_container.get_v_scrollbar().max_value


func scroll_to_bottom():
	if is_scrolled_up:
		return
	yield(get_tree(), "idle_frame")
	scroll_container.scroll_vertical = _max_scrollbar_value()


func clear():
	for child in scroll.get_children():
		child.queue_free()


# TODO when user has scrolled up, dont scrolldown with someone's else message
func on_scroll(_value):  # is_scrolled_up = true
	if scroll_container.scroll_vertical == _max_scrollbar_value():
		is_scrolled_up = false
		print("Scrolling ended")
