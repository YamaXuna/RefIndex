extends Control

export var default_image := "res://icon.png"


onready var image_display := $ImageDisplay
onready var images_number := $ImageDisplay/VBoxContainer/HBoxContainer2/number
onready var image_grid := $ImageDisplay/VBoxContainer/ScrollContainer/GridContainer
onready var add_tag_popup := $addTag
onready var edit_tags_popup := $editTags
onready var tabs := $ImageDisplay/VBoxContainer2/VBoxContainer/TabContainer
onready var filter_button := $ImageDisplay/VBoxContainer/HBoxContainer2/HBoxContainer/filterMenu
onready var filter_menu := $ImageDisplay/VBoxContainer2
onready var filter_list := $ImageDisplay/VBoxContainer/HBoxContainer2/HBoxContainer/filters
onready var settings := $SettingsWindow


var current_menu_items : Array
var previous_filters := []

var current_references := []

var previous_filter_tab := 0


# Called when the node enters the scene tree for the first time.
func _ready():
#	UTILS.get_app_resources()
#	UTILS.set_app_resource("additional_extensions", "kra")
	var __ = image_display.connect("menu_opened", self, "_on_menu_opened")
	__ = DATA.connect("has_tags", self, "_on_data_has_tags")
	load_images()
	hide_filter_menu()
	image_display.set_icon_size(UTILS.get_app_resources()["icon_size"])
	
	filter_button.disabled = DATA.nb_tags() == 0


func load_images()->void:
	image_display.refresh_items()



func hide_filter_menu()->void:
	tabs.hide()
	filter_menu.visible = false


func clear_filters()->void:
	for node in filter_list.get_children():
		node.queue_free()


func set_filters()->void:
	var filters : Array = tabs.get_selected_filters()
	if previous_filters == filters:
		return
	
	previous_filters = filters
	image_display.refresh_items(filters)
	
	clear_filters()
	
	if len(filters) == 0:
		return
	
	var label := Label.new()
	label.text = "Filters : "
	filter_list.add_child(label)
	for filter in filters:
		label = Label.new()
		label.text = filter.capitalize()
		filter_list.add_child(label)



func _on_GridContainer_child_entered_tree(_node):
	images_number.text = str(image_grid.get_child_count()) + " elements"


func _on_GridContainer_child_exiting_tree(_node):
	images_number.text = str(image_grid.get_child_count() - 1) + " elements"


func _on_PopupMenu_id_pressed(id):
	match id:
		0:
			if len(current_menu_items) == 1:
				add_tag_popup.set_image(current_menu_items[0])
			else:
				add_tag_popup.set_multi(current_menu_items)
			add_tag_popup.popup()
		1:
			if len(current_menu_items) == 1:
				edit_tags_popup.set_image(current_menu_items[0])
			else:
				edit_tags_popup.set_multi(current_menu_items)
			edit_tags_popup.popup()
		


func _on_menu_opened(items : Array)->void:
	current_menu_items = items


func _on_purge_pressed():
	image_display.set_info_text_to_tags_purged(DATA.delete_unused_tags())



func _on_filterMenu_pressed():
	tabs.show()
	filter_menu.visible = true
	image_display.clear_selection()


func _on_TabContainer_tab_selected(tab):
	if tab == 0:
		hide_filter_menu()
		set_filters()
	if tab == 1:
		tabs.uncheck_all()
		tabs.current_tab = previous_filter_tab
	
	if tab > 1:
		previous_filter_tab = tab


func _on_addRef_pressed():
	for path in UTILS.image_items_to_path_list(image_display.selected_items):
		if not path in current_references:
			current_references.append(path)


func purge_references(dir : Directory)->void:
	print("purging dumped references...")
	if dir.open("references") == OK:
		var err = dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name == ".gdignore":
				err = dir.remove(file_name)
				if err != OK:
					print(file_name + " not purged")
				else:
					print("purged : " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	print("purge complete")


func open_ref_dir()->void:
	match OS.get_name():
		"Windows":
			var out = []
			var __ = OS.execute("data\\open.bat", [], false, out)
	print("OS : ", OS.get_name())


func _on_dump_pressed():
	var dir := Directory.new()
	var path :=  "references"
	if not dir.dir_exists(path):
		if dir.make_dir(path) != OK:
			push_error("couldn't create " + path)
			return
	
#	create .gdignore to prevent the editor from importing it
	if OS.is_debug_build():
		var file := File.new()
		var __ = file.open(path + "/.gdignore", File.WRITE)
		file.close()
	
	purge_references(dir)
	
	var i := 0
	for image in current_references:
		var err = dir.copy(image, path + "/" + image.get_file())
		
		if err != OK:
			print("failed to dump " + image + " to " + path + "/" + image.get_file())
		else:
			i += 1
	
	image_display.set_info_text_to_dumped(i)
	open_ref_dir()


#will purge dumped references if running in the editor
func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if not OS.has_feature("standalone"):
			purge_references(Directory.new())
		get_tree().quit()


func _on_settings_pressed():
	settings.slider.value = image_display.img_size
	settings.show()


func _on_HSlider_value_changed(value):
	image_display.set_icon_size(value)


func _on_LineEdit_text_changed(new_text):
	UTILS.set_app_resource("additional_extensions", new_text)


func _on_data_has_tags(state)->void:
	filter_button.disabled = not state
