extends Node

const MAX_LOADING_ITEMS = 3



var queued_items := []
var loading_image_items := 0

var loading_items := []


func register_item(item)->void:
	if item in queued_items:
		return
	queued_items.push_back(item)


func remove(item)->void:
#	print(item)
	if not item in queued_items:
		return
	queued_items.erase(item)


func queue(item)->void:
	register_item(item)


func load_item()->void:
	if len(queued_items) == 0:
		return
		
	var current_item = queued_items.pop_front()
	if not is_instance_valid(current_item):
		return
	var __ = current_item.connect("thread_end", self, "_on_loaded")
	loading_image_items += 1
	loading_items.append(current_item)
	current_item.load_image()


func _process(_delta):
	if len(queued_items) == 0:
		return
	
	if loading_image_items < MAX_LOADING_ITEMS:
		load_item()
	
	purge_freed_items()



func purge_freed_items()->void:
	if len(loading_items) > 0:
		for item in loading_items:
			if not is_instance_valid(item):
				loading_items.erase(item)
				loading_image_items -= 1


func purge_all()->void:
	loading_items.clear()
	queued_items.clear()
	loading_image_items = 0


func _on_loaded(item)->void:
	if item == null:
		return
	loading_image_items -= 1
	loading_items.erase(item)
