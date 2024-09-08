/*select * from image img
		join has_tag using(img_id) 
		join tag t using(tag_id)
join tag t2 using(tag_id)
		where t.name = "a" and t2.name = "aurore";
*/
select * from image where img_id in(
select t.img_id from has_tag t
join has_tag t2 on t.img_id = t2.img_id
join tag ta using(tag_id) 
where --t.tag_id = 13 and t2.tag_id = 35
ta.name = "a" and ta.name = "aurore"
);	


