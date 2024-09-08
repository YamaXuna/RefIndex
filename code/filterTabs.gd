extends TabContainer


const Item = preload("res://scenes/filterItem.tscn")


export var grid_columns := 6

var all_filters := {}

var selected_filters := []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func show()->void:
	fill()
	current_tab = 1
	.show()


func hide()->void:
	for tab in get_children():
		tab.queue_free()
	.hide()


func add_new_tab(name : String):
	var scroll := ScrollContainer.new()
	var grid := GridContainer.new()
	grid.columns = grid_columns
	
	scroll.add_child(grid)
	scroll.name = name
	add_child(scroll)
	return scroll


func fill()->void:
	var node := Control.new()
	node.name = "Close"
	add_child(node)
	var current_letter = ""
	var current_tab
#	print(DATA.get_all_tags())
	for tag in DATA.get_all_tags():
		var item := Item.instance()
		var text : String = tag["name"].capitalize()
		if text[0] != current_letter:
			current_letter = text[0]
			current_tab = add_new_tab(current_letter)
		
		current_tab.get_child(2).add_child(item)
		item.label.text = text

		all_filters[text] = item.box
		if text in selected_filters:
			item.box.pressed = true
		


func get_selected_filters()->Array:
	var tags := []
	
	for tag in all_filters.keys():
		if all_filters[tag].pressed:
			tags.append(tag)
	
	selected_filters = tags.duplicate()
	return tags



func _on_uncheck_pressed():
	for box in all_filters.values():
		box.pressed = false
