extends WindowDialog

export var img_width = 200


onready var texture_rect := $HBoxContainer/VBoxContainer/TextureRect
onready var image_path := $HBoxContainer/VBoxContainer/path
onready var image_name := $HBoxContainer/VBoxContainer/name
onready var image_tags :=$HBoxContainer/VBoxContainer/tagList

onready var new_tag_line_edit := $HBoxContainer/VBoxContainer2/HBoxContainer/LineEdit
onready var list := $HBoxContainer/VBoxContainer2/OptionButton



var image_item

var is_multi := false
var items : Array


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_image(item)->void:
	is_multi = false
	image_item = item
	var image = Image.new()
	var error = image.load(item.image_path)

	if error != OK:
		print(item.image_path + " format cannot be displayed")
		return
	
#	if image.get_size().x > 1000 and image.get_size().y > 1000:
#		image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC, 0.2)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	texture_rect.texture = texture
	set_image_scale()
	

func set_multi(item_list)->void:
	is_multi = true
	items = item_list
	texture_rect.texture = preload("res://icon.png")


func set_image_scale()->void:
#	need to fix aspect ratio while keep it in the 200*200 box
	var scale : float
	if texture_rect.texture.get_size().x > texture_rect.texture.get_size().y:
		scale = img_width / texture_rect.texture.get_size().x
	else:
		scale = img_width / texture_rect.texture.get_size().y
	texture_rect.rect_min_size = texture_rect.texture.get_size() * scale


func popup(rect : Rect2=Rect2()):
	reset()
	
	.popup(rect)


func set_tags_list(tag_list : Array, string : String)->void:
	for node in image_tags.get_children():
		node.queue_free()
	var label := Label.new()
	label.text = string
	image_tags.add_child(label)
	for tag in tag_list:
		label = Label.new()
		label.text = tag["name"].capitalize()
		image_tags.add_child(label)


func reset()->void:
	if is_multi:
		reset_multi()
	else:
		reset_single()


func reset_common()->void:
	new_tag_line_edit.text = ""
	
	
	set_combo_box()
	

func set_combo_box(begins : String ="")->void:
	list.clear()
	for tag in DATA.get_all_tags():
		if tag["name"].to_lower().begins_with(begins.to_lower()):
			list.add_item(tag["name"].capitalize(), tag["tag_id"])


func reset_multi()->void:
	reset_common()
	image_path.text = "%s elements selected" % [len(items)]
	image_name.text = ""
	
	set_tags_list(DATA.get_tags_in_common(UTILS.image_items_to_path_list(items)), "Tags in common : ")
	


func reset_single()->void:
	reset_common()
	
	image_path.text = image_item.image_path
	image_name.text = image_item.image_path.get_file()
	
	set_tags_list(DATA.get_image_tags(image_item.image_path), "Tags : ")



func validate_single(from_list : bool = false)->void:
	if not new_tag_line_edit.text.empty() and not from_list:
		DATA.add_tag_to_image(image_item.image_path, new_tag_line_edit.text.to_lower())
	else:
		DATA.add_tag_to_image(image_item.image_path, list.get_item_text(list.selected).to_lower())
	reset()


func validate_multi(from_list : bool = false)->void:
	if not new_tag_line_edit.text.empty() and not from_list:
		DATA.add_tag_to_many(UTILS.image_items_to_path_list(items), new_tag_line_edit.text.to_lower())
	else:
		DATA.add_tag_to_many(UTILS.image_items_to_path_list(items), list.get_item_text(list.selected).to_lower())
	reset()


func validate(from_list : bool = false)->void:
	if from_list and list.selected == -1:
		return
	
	if is_multi:
		validate_multi(from_list)
	else:
		validate_single(from_list)


func _on_validate_pressed():
	validate(true)


func _on_close_pressed():
	hide()


func _on_LineEdit_text_changed(new_text):
	set_combo_box(new_text)


func _on_OptionButton_item_selected(_index):
	new_tag_line_edit.text = ""
	
#	set_combo_box()


func _on_addNew_pressed():
	validate()
