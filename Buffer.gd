extends Control
var channel
var nicks = {}
onready var scroll_container = $ScrollContainer
onready var scroll = $ScrollContainer/VBoxContainer

var is_scrolled_up = false

const IRC_SPECIAL_NICK_PREFIES = ["@", "+", "%", "&", "~"]
const COLORS = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"]
const ColorEscape = "\u0003";
const BoldEscape = "";
const ItalicEscape = "";
const UnderlineEscape = "";

func _ready():
	scroll_container.get_v_scrollbar().connect("value_changed", self, "on_scroll")

func add_nicks(nicknames):
	for nickname in nicknames:
		for prefix in IRC_SPECIAL_NICK_PREFIES:
			if nickname.begins_with(prefix):
				nickname = nickname.substr(1, nickname.length())
				break
		nicks[nickname] = COLORS[hash(nickname) % len(COLORS)]


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
	label.selection_enabled = true

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

	for nick in nicks:
		var regex = RegEx.new()
		regex.compile("\\b" + nick + "\\b")
		_text = regex.sub(_text, "[color=" + nicks[nick] + "]" + nick + "[/color]", true)

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
func on_scroll(_value):
	# is_scrolled_up = true
	if scroll_container.scroll_vertical == _max_scrollbar_value():
		is_scrolled_up = false
		print("Scrolling ended")
