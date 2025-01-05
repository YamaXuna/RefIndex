extends WindowDialog


onready var slider := $VBoxContainer/HBoxContainer/HSlider
onready var icon_size_label := $VBoxContainer/HBoxContainer/Label
onready var extensions_text := $VBoxContainer/HBoxContainer2/LineEdit
onready var default_extensions_label := $VBoxContainer/DefaultExtensions
onready var check_extension_box := $VBoxContainer/HBoxContainer3/CheckBox


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_icon_size_text(size : int)->void:
	icon_size_label.text = "Icon Size : " + str(size)


func popup(rect : Rect2 = Rect2(0, 0, 0, 0)):
	default_extensions_label.text = "Supported formats : %s" % [UTILS.get_app_resources()[
		"default_extensions"]]
	extensions_text.text = UTILS.get_app_resources()["additional_extensions"]
	check_extension_box.pressed = UTILS.get_app_resources()["check_extension_for_single_files"]
	set_icon_size_text(slider.value)
	.popup(rect)


func _on_HSlider_value_changed(value):
	set_icon_size_text(value)


func _on_HSlider_drag_ended(value_changed):
	if not value_changed:
		return
	UTILS.set_app_resource("icon_size", slider.value)
