extends Node2D
class_name GameChara

var destination :Vector2;
var speed :int = 120;
var anim :AnimatedSprite;
var loc :Node2D;
var loc_can_scale :bool;
var screen :Node2D;
var route: Array;
var current_rp_i: int;
var programmed_act_obj :Node;
var programmed_act_func :String = "";
var player_num :int;
var flipable_anim :bool = true;


func _ready() ->void:
	anim = get_node("Sprite");
	anim.connect("animation_finished",self,"on_anim_finish");
	loc = get_parent().get_parent();
	stop();
	my_ready();

func my_ready() ->void:
	pass;

func register_on_loc() ->void:
	loc_can_scale = loc.can_scale_player();
	scale.x = loc.get_player_scale(global_position);
	scale.y = scale.x;
	speed = loc.get_player_speed();

func change_loc(loc_name :String, entry_num :int, force_alone :bool = false) ->void:
	var new_loc :Node2D = global.chapter.get_node("locs/"+loc_name);
	get_parent().remove_child(self);
	new_loc.get_node("chars").add_child(self);
	if global.player == self :
		loc.hide();
		new_loc.show();
	loc = new_loc;
	global_position = loc.entry_points[entry_num];
	register_on_loc();
	
	if global.chapter.chapter_num == 2 and global.chapter.chars_are_together and not force_alone :
		if global.player == self :
			global.player2.change_loc(loc_name, entry_num);
		elif global.player2 == self and loc.has_player2_position() :
			move(loc.get_player2_position());

func look_on_screen(screen_node :Node2D) ->void:
	screen = screen_node;
	loc.hide();
	screen.show();

func look_off_screen() ->void:
	if not screen :
		return;
	screen.hide();
	loc.show();
	screen = null;

func can_see(from :Vector2, to :Vector2, obstacle :Polygon2D) ->bool:
	var intersections :Array = Geometry.intersect_polyline_with_polygon_2d([from, to], obstacle.get_polygon());
	return intersections.empty();

func find_way(ray :PoolVector2Array) ->Array:
	#ищем преграду, если оная есть
	var all_obstacles :Array = loc.get_obstacles();
	var obstacle :Polygon2D;
	var min_distance :float = -1;
	for i in range(0,all_obstacles.size(),1):
		if Geometry.is_point_in_polygon(ray[1], all_obstacles[i].get_polygon()) :
			return [];
		elif Geometry.is_point_in_polygon(ray[0], all_obstacles[i].get_polygon()) :
			print("ОШИБКА! chara.find_way(): Персонаж внутри преграды!")
			return [];
		
		var intersects_lines :Array = Geometry.intersect_polyline_with_polygon_2d(ray, all_obstacles[i].get_polygon());
		if not intersects_lines.empty() :
			var distance :float = ray[0].distance_to(intersects_lines[0][0]);
			if min_distance < 0 or min_distance > distance :
				min_distance = distance;
				obstacle = all_obstacles[i];
#			global.debug_drawer.add_point(intersects_lines[0][0]);
	if not obstacle :
		return [ray[1]];
	
	#если преграда найдена, вычисляем путь обхода
	var waypoints :PoolVector2Array = obstacle.get_waypoints();
	var start_point_i :int = -1;
	var final_point_i :int = -1;
	for i in range(0,waypoints.size(),1):
		if start_point_i == -1 :
			if can_see(ray[0], waypoints[i], obstacle):
				start_point_i = i;
				if final_point_i != -1 :
					break;
		if final_point_i == -1 :
			if can_see(ray[1], waypoints[i], obstacle):
				final_point_i = i;
				if start_point_i != -1 :
					break;
	
	var all_ways :Array = [];
	#Первый путь (прямой)
	if start_point_i <= final_point_i or obstacle.is_wp_circular() :
		all_ways.append([]);
		var current_point_i :int = start_point_i;
		for _counter in range(0,waypoints.size(),1):
			all_ways[0].append(waypoints[current_point_i]);
			if current_point_i == final_point_i :
				break;
			else :
				current_point_i += 1;
				if current_point_i == waypoints.size() :
					current_point_i = 0;
	
	#Второй путь (обратный)
	if start_point_i > final_point_i or obstacle.is_wp_circular() :
		all_ways.append([]);
		var true_way_num :int = all_ways.size()-1;
		var current_point_i :int = start_point_i;
		for counter in range(0,waypoints.size()+1,1):#здесь на один больше для случая start == final и полного обхода
			all_ways[true_way_num].append(waypoints[current_point_i]);
			if counter != 0 and current_point_i == final_point_i :#с учётом случая start == final
				break;
			else :
				current_point_i -= 1;
				if current_point_i == -1 :
					current_point_i = waypoints.size()-1;
	
	#сокращаем пути
	for way_num in range(0,all_ways.size(),1):
		if all_ways[way_num].size() > 1 :
			#ищим последний видимый со старта пункт
			var first_useable :int = 0;
			for i in range(1,all_ways[way_num].size(),1):
				if can_see(ray[0], all_ways[way_num][i], obstacle):
					first_useable = i;
				else :
					break;
			#ищим первый пункт, с которого виден финиш
			var last_useable :int = all_ways[way_num].size()-1;
			for i in range(first_useable,all_ways[way_num].size(),1):
				if can_see(ray[1], all_ways[way_num][i], obstacle):
					last_useable = i;
					break;
			#записываем результат
			var short_way :Array = [];
			for i in range(first_useable,last_useable+1,1):
				short_way.append(all_ways[way_num][i]);
			all_ways[way_num] = short_way;
	
	#добавляем финишную точку
	for way_num in range(0,all_ways.size(),1):
		all_ways[way_num].append(ray[1]);
	
	#выбираем кратчайший путь
	var shortest_way_num :int;
	if all_ways.size() == 1 :
		#return all_ways[0];
		shortest_way_num = 0;
	else :
		var lengths :Array = [0,0];
		for way_num in range(0,2,1):
			for i in range(1,all_ways[way_num].size(),1):
				lengths[way_num] += all_ways[way_num][i-1].distance_to(all_ways[way_num][i]);
		if lengths[0] < lengths[1] :
			#return all_ways[0];
			shortest_way_num = 0;
		else :
			#return all_ways[1];
			shortest_way_num = 1;
	
	#проверяем, нет ли преград на пути к нашей преграде и от неё
	#и составляем конечный маршрут
	var result_way :Array = [];
	var inserting_way :Array = find_way(PoolVector2Array([ray[0], all_ways[shortest_way_num][0]]));
	#ВНИМАНИЕ! есть опасения, что рекурсия может стать вечной, если зацепит одну из уже обработанных преград. Желательно будет сделать заглушку для этого опасения
	for i in range(0,inserting_way.size()-1,1) :
		result_way.append(inserting_way[i]);

	for i in range(0,all_ways[shortest_way_num].size()-1,1) :
		result_way.append(all_ways[shortest_way_num][i]);
	
	inserting_way = find_way(PoolVector2Array([result_way.back(), ray[1]]));
	for i in range(0,inserting_way.size(),1) :
		result_way.append(inserting_way[i]);

	return result_way;

func start_move(point :Vector2, ignor_obstacles :bool = false) ->void:
	if ignor_obstacles :
		route = [point];
	else :
		route = find_way(PoolVector2Array([global_position, point]));
#		print(route);
	
	if route.size() == 0:
		if programmed_act_obj :
			programmed_act_obj = null;
	else :
		play_anim_on_move();
		set_process(true);
		loc.chara_started_move();
		current_rp_i = -1;
		next_route_point();

func play_anim_on_move() ->void:
	pass;

func move_and_act(point :Vector2, obj :Node, act :String, ignor_obstacles :bool = false) ->void:
	programmed_act_obj = obj;
	programmed_act_func = act;
	start_move(point, ignor_obstacles);

func move(point :Vector2, ignor_obstacles :bool = false) ->void:
	if programmed_act_obj :
		programmed_act_obj = null;
	start_move(point, ignor_obstacles);

func next_route_point() ->void:
	current_rp_i += 1;
	if current_rp_i >= route.size():
		stop();
		if programmed_act_obj :
			var act_obj = programmed_act_obj;
			programmed_act_obj = null;
			act_obj.call(programmed_act_func);
		return;
	
	destination = route[current_rp_i];
	if flipable_anim :
		anim.set_flip_h(global_position.x < destination.x);

func stop() ->void:
	play_anim_on_stop();
	set_process(false);
	loc.chara_finished_move();
	route.clear();

func play_anim_on_stop() ->void:
	pass;

func emergency_stop() ->void:
	if is_processing() : #вообще, надо бы добавить статус "иду", но пока лень
		stop();
		if programmed_act_obj :
			programmed_act_obj = null;

func on_anim_finish() ->void:
	pass;

func play_anim_on_success() ->void:
	pass;

func _process(delta) ->void:
	if abs(global_position.x - destination.x) < 2 and abs(global_position.y - destination.y) < 2 :
		next_route_point();
		return;
	
	var direction :Vector2 = (destination - global_position).normalized();
	var step_speed :int = speed;
	if loc_can_scale :
		var scalezone :Node2D = loc.get_scalezone_in_use(global_position);
		if scalezone :
			scale.x = scalezone.get_player_scale(global_position);
			scale.y = scale.x;
			step_speed = speed + scalezone.get_speed_penalty(direction);
	
	global_position += direction * step_speed * delta;
