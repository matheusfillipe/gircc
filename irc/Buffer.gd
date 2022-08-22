extends Control
var channel
onready var scroll = $ScrollContainer/VBoxContainer
func add_label(object):
	scroll.add_child(object)
