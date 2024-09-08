extends WindowDialog


export var img_width := 200

onready var texture_rect := $HBoxContainer/VBoxContainer/TextureRect 
onready var list := $HBoxContainer/VBoxContainer2/ItemList
onready var image_path := $HBoxContainer/VBoxContainer/path
onready var image_name := $HBoxContainer/VBoxContainer/name


var image_item

var current_tags : Array


var is_multi := false
var items : Array


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


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


func set_multi(item_list : Array)->void:
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


func reset()->void:
	if is_multi:
		reset_multi()
	else:
		reset_single()


func reset_single()->void:
	reset_common()
	image_path.text = image_item.image_path
	image_name.text = image_item.image_path.get_file()


func reset_multi()->void:
	reset_common()
	image_name.text = ""
	image_path.text = "%s elements selected" % [len(items)]


func reset_common()->void:
	set_tag_list()


func set_tag_list()->void:
	list.clear()
	var i = 0
	var tags
	if is_multi:
		tags = DATA.get_tags_in_common(UTILS.image_items_to_path_list(items))
	else:
		tags = DATA.get_image_tags(image_item.image_path)
	current_tags = tags
	for tag in tags:
		list.add_item(tag["name"].capitalize())
		list.select(i, false)
		i += 1


func popup(rect : Rect2=Rect2()):
	reset()
	
	.popup(rect)


func _on_cancel_pressed():
	hide()


func remove_tags_from_image(path : String, new_tags : Array)->void:
	for tag in current_tags:
		if not tag["name"] in new_tags:
			DATA.remove_tag_from_image(path, tag["name"])


func _on_validate_pressed():
	var new_tags := []
	for item in list.get_selected_items():
		new_tags.append(list.get_item_text(item).to_lower())
	
	if is_multi:
		for path in UTILS.image_items_to_path_list(items):
			remove_tags_from_image(path, new_tags)
		#TODO add a confirm popup
	else:
		remove_tags_from_image(image_item.image_path, new_tags)

	hide()
