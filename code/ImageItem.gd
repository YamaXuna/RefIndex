extends VBoxContainer

class_name image_item

export var img_size := 200
export var name_max_length := 35


signal thread_end(item)

signal left_clicked(item)
signal right_clicked(item)


var default_texture = preload("res://icon.png")

onready var image_display := $image
onready var label := $name
onready var timer := $selection_timer

export(String) var image_path := ""

var selected := false
var is_under_mouse := false

var is_loaded := false
var load_failed := false

var thread := Thread.new()
var texture : Texture


# Called when the node enters the scene tree for the first time.
func _ready():
	set_path_display()


func select()->void:
	selected = true
	image_display.modulate = Color.aquamarine


func deselect()->void:
	selected = false
	image_display.modulate = Color.white


func set_path_display()->void:
	label.text = image_path.get_file().substr(0, name_max_length)
	hint_tooltip = image_path


func load_image()->void:
	if thread.is_active():
		# Already working
		return
	
	var error = thread.start(self, "background_loading", image_path)
	if error != OK:
		push_error("thread could not be started")


func background_loading(path)->Texture:
	var image = Image.new()
	var error = image.load(path)
	

	if error != OK:
		print(image_path + " format cannot be displayed")
		call_deferred("on_load_fail")
		return null
	
	if image.get_size().x > 1000 and image.get_size().y > 1000:
		image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC, 0.001)
	texture = ImageTexture.new()
	texture.create_from_image(image)
	
	call_deferred("on_background_loading_complete")
	
	return texture


func on_load_fail()->void:
	load_failed = true
	var __ = thread.wait_to_finish()
	emit_signal("thread_end")


func on_background_loading_complete()->void:
	# Wait for the thread to complete, get the returned value
	var tex = thread.wait_to_finish()
	emit_signal("thread_end", self)
	if tex == null:
		push_error(image_path + " could not be loaded")
		load_failed = true
		return
	is_loaded = true
	image_display.texture = tex



func set_image_scale()->void:
#	need to fix aspect ratio while keep it in the 200*200 box
	var scale_x : float = img_size / image_display.texture.get_size().x
	var scale_y : float = img_size / image_display.texture.get_size().y
	image_display.rect_min_size.x = image_display.texture.get_size().x * scale_x
	image_display.rect_min_size.y = image_display.texture.get_size().y * scale_y


func queue_free()->void:
	if thread.is_active():
		yield(self, "thread_end")
	.queue_free()


func _on_gui_input(event):
	if event is InputEventMouseButton and timer.time_left == 0:
		if event.button_index == BUTTON_LEFT and event.pressed:
			emit_signal("left_clicked", self)
			timer.start()
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			emit_signal("right_clicked", self)
	


func _on_selection_timer_timeout():
	pass # Replace with function body.


func _on_VisibilityNotifier2D_screen_entered():
	if is_loaded or load_failed:
		return
#	load_image()
	LOADER.queue(self)


func _on_VisibilityNotifier2D_screen_exited():
	LOADER.remove(self)
