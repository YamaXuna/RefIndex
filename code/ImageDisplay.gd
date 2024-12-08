extends PanelContainer


const ImageItem = preload("res://scenes/ImageItem.tscn")

export var img_size := 200
export(String) var supported_formats := "png,bmp,dds,exr,hdr,jpg,jpeg,webp,svg"
var additional_formats := ""
export(bool) var check_extension_for_single_files := false

signal menu_opened(item)

onready var supported_extensions : Array 

onready var file_select := $FileDialog
onready var image_grid := $VBoxContainer/ScrollContainer/GridContainer
onready var alert_popup := $AlertPopup
onready var info_text := $VBoxContainer/bottom_bar/info
onready var popup_menu := $PopupMenu


var selected_items := []
var paths_to_add := []

var shrek = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	set_supported_extensions()


func set_supported_extensions()->void:
	var exts := supported_formats.split(",")
	
	exts.append_array(additional_formats.replace(".", "").split(","))
	
	supported_extensions = exts


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_info_text_to(text : String)->void:
	var string := text
	info_text.text = string
	print(string)


func set_info_text_to_added(n : int)->void:
	set_info_text_to(str(n) + " elements added")
	


func set_info_text_to_deleted(n : int)->void:
	set_info_text_to(str(n) + " elements deleted")


func set_info_text_to_dumped(n : int)->void:
	set_info_text_to("dumped "+ str(n) + " elements")


func set_info_text_to_tags_purged(n : int)->void:
	set_info_text_to(str(n) + " tags purged")


func refresh_items(filters : Array = [])->void:
	for item in image_grid.get_children():
		item.queue_free()

	var items : Array
	if len(filters) > 0:
		items = DATA.get_filtered(filters)
	else:
		items = DATA.get_all()
	for item in items:
		add_item(item["path"])
	


func add_item(path : String)->void:
	var new_item := ImageItem.instance()
	new_item.image_path = path
	new_item.img_size = img_size
	image_grid.add_child(new_item)
	new_item.set_image_scale()
	var __ = new_item.connect("left_clicked", self, "_on_item_left_clicked")
	__ = new_item.connect("right_clicked", self, "_on_item_right_clicked")


func on_new_file(path : String, alert :bool = false)->bool:
	if check_extension_for_single_files and not path.get_extension() in supported_extensions:
		return false
	if DATA.is_in_db(path) and alert:
		set_info_text_to("add failed")
		show_alert(path + " is already registered")
		return false
	add_item(path)
	DATA.add_image(path)
	
	return true


func show_alert(text : String)->void:
	alert_popup.dialog_text = text
	alert_popup.popup_centered()
	


func show_menu(items : Array)->void:
	popup_menu.popup()
	popup_menu.set_global_position(get_global_mouse_position())
	emit_signal("menu_opened", items)


func clear_selection()->void:
	for item in selected_items:
		item.deselect()
	selected_items.clear()


func _on_add_pressed():
	file_select.mode = FileDialog.MODE_OPEN_FILES
	file_select.popup()


func _on_add_dir_pressed():
	file_select.mode = FileDialog.MODE_OPEN_DIR
	file_select.popup()


func _on_FileDialog_file_selected(path):
	if on_new_file(path, true):
		set_info_text_to_added(1)


func _on_FileDialog_files_selected(paths):
	var failed := 0
	for path in paths:
		if not on_new_file(path, true):
			failed += 1
	set_info_text_to_added(len(paths) - failed)


func add_file_path_from_dir(path):
	if not path.get_extension() in supported_extensions:
		return
	paths_to_add.append(path)
#	add_item(path)
#	DATA.add_image(path)


func set_icon_size(size : int)->void:
	img_size = size
	for item in image_grid.get_children():
		item.img_size = img_size
		item.set_image_scale()


func _on_FileDialog_dir_selected(path):
	var dir = Directory.new()
	if dir.open(path) != OK:
		show_alert(path + " could not be opened")
		return
		
	var f_ref := funcref(self, "add_file_path_from_dir")
	
	UTILS.for_each_files(path, f_ref)
	set_info_text_to_added(len(paths_to_add))
	
	for path in paths_to_add:
		if not DATA.is_in_db(path):
			add_item(path)
	DATA.add_many(paths_to_add)
	paths_to_add.clear()


func _on_item_left_clicked(item)->void:
	if item.selected :
		item.deselect()
		selected_items.erase(item)
	else:
		item.select()
		selected_items.append(item)


func _on_item_right_clicked(item)->void:
	var items : Array
	if len(selected_items) > 1 and item.selected:
		items = selected_items
	else:
		clear_selection()
		items = [item]

	show_menu(items)



func _on_delete_pressed():
	if len(selected_items) == 0:
		return
	var paths := []
	set_info_text_to_deleted(len(selected_items))
	for item in selected_items:
		paths.append(item.image_path)
		item.queue_free()
	selected_items = []
	DATA.delete_many(paths)


func _on_deselect_pressed():
	clear_selection()


func _on_selectAll_pressed():
	for item in image_grid.get_children():
		item.select()
		selected_items.append(item)


func _on_LineEdit_text_changed(new_text):
	additional_formats = new_text
	set_supported_extensions()
