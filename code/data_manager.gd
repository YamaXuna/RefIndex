extends Node

signal has_tags(status)

const SQL = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const PATH = "res://data/db.db"

var clear_db_on_start := false
var db : SQL


# Called when the node enters the scene tree for the first time.
func _ready():
	open_db()
	init_db()


func init_db()->void:
	if clear_db_on_start:
		db.drop_table("image")
		db.drop_table("tag")
		db.drop_table("has_tag")
	db.create_table("image", {
		"img_id" : {"data_type" : "int", "primary_key" : true, "auto_increment" : true},
		"path" : {"data_type" : "char(300)", "not_null" : true, "unique" : true},
		"name" : {"data_type" : "char(64)", "not_null" : true, "unique" : false}
	})
	db.create_table("tag",{
		"tag_id" : {"data_type" : "int", "primary_key" : true, "auto_increment" : true},
		"name" : {"data_type" : "char(50)", "not_null" : true, "unique" : true},
	})
	db.create_table("has_tag",{
		"tag_id" : {"data_type" : "int", "not_null" : true},
		"img_id" : {"data_type" : "int", "not_null" : true}
	})
	


func open_db()->void:
	db = SQL.new()
	db.path = PATH
	db.open_db()


### add and delete ###
func save_image(path : String)->void:
	if is_in_db(path):
		return
	var ret = db.insert_row("image", {"path" : path, "name": path.get_file()})
	if not ret:
		print(db.error_message)


func save_tag(name : String)->void:
	if is_tag_in_db(name):
		return
	var ret = db.insert_row("tag", {"name" : name.to_lower()})
	if not ret:
		print(db.error_message)
	print("tag %s saved" % [name])


func is_in_db(path : String)->bool:
	db.query_with_bindings("select count(*) from image where path = ?", [path])
	return db.query_result[0]["count(*)"] > 0


func is_tag_in_db(name : String)->bool:
	db.query_with_bindings("select count(*) from tag where name = ?", [name.to_lower()])
	return db.query_result[0]["count(*)"] > 0


func is_image_tagged(path : String, tag : String)->bool:
	db.query_with_bindings("select count(*) from image " + 
		"join has_tag using(img_id) " +
		"join tag t using(tag_id) " +
		"where path = ? and t.name = ?",
	[path, tag])
	return db.query_result[0]["count(*)"] > 0


func add_image(path : String):
	if is_in_db(path):
		return
	save_image(path)


func add_many(paths : Array)->void:
	var rows := []
	
	for path in paths:
		if not is_in_db(path):
			rows.append({
				"path" : path,
				"name" : path.get_file()
			})
	
	db.insert_rows("image", rows)


func delete_many(paths : Array)->void:
	var sql := "delete from image where path in ("
	var sql2 := "delete from has_tag where img_id in("
	for i in range(len(paths)):
		sql += "?"
		sql2 += "(select img_id from image where path = ?)"
		if i < len(paths) - 1:
			sql += ","
			sql2 += ","
	sql += ")"
	sql2 += ")"
	
	var paths_copy = paths.duplicate()
	db.query_with_bindings(sql2, paths)
	db.query_with_bindings(sql, paths_copy)


func delete_unused_tags()->int:
	db.query("select count(*) from tag where tag_id not in(" +
		"select tag_id from has_tag)")
	var count : int = db.query_result[0]["count(*)"]
	db.query("delete from tag where tag_id not in(" +
		"select tag_id from has_tag)")
	
	emit_signal("has_tags", nb_tags())
	return count


func add_tag_to_image(image_path : String, tag_name : String)->void:
	if nb_tags() == 0:
		emit_signal("has_tags", true)
	if not is_in_db(image_path):
		return
	if not is_tag_in_db(tag_name):
		save_tag(tag_name)
	if is_image_tagged(image_path, tag_name):
		return
	
	db.query_with_bindings("insert into has_tag(img_id, tag_id) values(" +
		"(select img_id from image where path = ?)," +
		"(select tag_id from tag where name = ?)" +
	")", [image_path, tag_name.to_lower()])


func add_tag_to_many(paths : Array, tag_name : String)->void:
	for path in paths:
		add_tag_to_image(path, tag_name)


func remove_tag_from_image(image_path : String, tag_name : String)->void:
	if not is_in_db(image_path):
		return
	if not is_tag_in_db(tag_name):
		return
	if not is_image_tagged(image_path, tag_name):
		return
	db.query_with_bindings("delete from has_tag where img_id = " +
		"(select img_id from image where path = ?) and tag_id = " +
		"(select tag_id from tag where name = ?)", 
		[image_path, tag_name.to_lower()])


### get ###

func get_all()->Array:
	db.query("select path from image order by lower(name)")
	return db.query_result


func get_filtered(filters : Array)->Array:
	if len(filters) == 0:
		return get_all()
	var sql := """select * from image where img_id in(
		select t.img_id from has_tag t """
	
	
	for i in range(1, len(filters)):
		sql += "join has_tag t%d on t.img_id = t%d.img_id \n" %[i, i]
	sql += " where t.tag_id = (select tag_id from tag where name = lower(?))\n"
	
	for i in range(1, len(filters)):
		sql += " and t%s.tag_id = (select tag_id from tag where name = lower(?))\n" % [i]
	sql += ") order by lower(name)"
	
	db.query_with_bindings(sql, filters.duplicate())
	
	return db.query_result


func get_all_tags()->Array:
	db.query("select tag_id, name from tag order by lower(name)")
	return db.query_result


func nb_tags()->int:
	db.query("select count(*) from tag")
	return db.query_result[0]["count(*)"]


func get_image_tags(path : String)->Array:
	db.query_with_bindings("select t.name from image " + 
		"join has_tag using(img_id) " +
		"join tag t using(tag_id) " +
		"where path = ? order by lower(t.name)",
	[path])
	return db.query_result


func get_tags_in_common(paths : Array)->Array:
	var sql := """select name
		from tag
		where tag_id in("""
	
	for i in range(len(paths)):
		sql += """select  tag_id 
			from has_tag  
			where img_id = (select img_id from image where path = ?)"""
		if i < len(paths) - 1:
			sql += " intersect "
	sql += ") order by lower(name)"
	db.query_with_bindings(sql, paths)

	return db.query_result
