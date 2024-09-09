extends WindowDialog


onready var slider := $VBoxContainer/HBoxContainer/HSlider
onready var icon_size_label := $VBoxContainer/HBoxContainer/Label
onready var extensions_text := $VBoxContainer/HBoxContainer2/LineEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_icon_size_text(size : int)->void:
	icon_size_label.text = "Icon Size : " + str(size)


func show():
	extensions_text.text = UTILS.get_app_resources()["additional_extensions"]
	set_icon_size_text(slider.value)
	.show()


func _on_HSlider_value_changed(value):
	set_icon_size_text(value)


func _on_HSlider_drag_ended(value_changed):
	if not value_changed:
		return
	UTILS.set_app_resource("icon_size", slider.value)
