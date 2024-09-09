extends Node

const RES_PATH = "data/data.tres"

onready var app_ressources : Resource = get_app_resources()


func for_each_files(var root_path:String, var on_file:FuncRef):
	"""
	Helper function to iterate files
	"""
	var path:Array=[root_path]
	var dirs:Array=[]
	while(!path.empty()):
		if len(path) > len(dirs):
			var full_path=""
			for p in path:
				full_path+=p+"/"
			var dir:Directory=Directory.new()
			if dir.open(full_path)!=OK:
				print("Error occurred when trying to access "+full_path)
				path.pop_back()
				continue
			var __ = dir.list_dir_begin(true)
			dirs.push_back(dir)
		else:
			var entry:Directory=dirs.back()
			var simple_name=entry.get_next()
			if simple_name=="":
				path.pop_back()
				dirs.pop_back()
			else:
				if entry.current_is_dir():
					path.push_back(simple_name)
				else:
					var fullpath=""
					for p in path:
						fullpath+=p+"/"
					fullpath+=simple_name
					on_file.call_func(fullpath)


func image_items_to_path_list(items : Array)-> Array:
	var paths := []
	for item in items:
		paths.append(item.image_path)
	return paths


func get_app_resources()->Resource:
	var res : Data
	if not ResourceLoader.exists(RES_PATH):
		res = Data.new()
	else:
		res = ResourceLoader.load(RES_PATH)
	
	return res


func set_app_resource(key : String, value)->void:
	app_ressources[key] = value
	
	var _err = ResourceSaver.save(RES_PATH, app_ressources)
