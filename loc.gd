extends Node2D

export var player_scale :float = 0.7;
export var player_speed :int = 120;
var obstacles :Array;# = []
var entry_points :Dictionary;
var scalezones :Array;
var moving_chars_count :int = 0;
var chars_node :Node2D;
var player2_position_node :Node2D;

func _ready() ->void:
	connect("hide",self,"on_hide");
	if has_node("walkzone") :
		var walkzone :Node2D = get_node("walkzone");
		if walkzone.has_node("scalezones"):
			scalezones = walkzone.get_node("scalezones").get_children();
		if walkzone.has_node("obstacles"):
			obstacles = walkzone.get_node("obstacles").get_children();
	if has_node("player2_pos") :
		player2_position_node = get_node("player2_pos");
	chars_node = get_node("chars");
	set_process(false);

func on_hide() ->void:
	global.hint.my_hide();

func get_obstacles() ->Array:
	return obstacles;

func reg_entry_point(index :int, point :Vector2) ->void:
	if entry_points.has(index) :
		print("ОШИБКА! loc.reg_entry_point Попытка вторичной регистрации")
	entry_points[index] = point;

func get_player_scale(point :Vector2) ->float:
	var scalezone :Node2D = get_scalezone_in_use(point);
	if scalezone :
		return scalezone.get_player_scale(point);
	else :
		return player_scale;

func get_scalezone_in_use(point :Vector2) ->Node2D:
	if not can_scale_player() :
		return null;
	
	for i in range(0, scalezones.size(), 1) :
		if scalezones[i].in_use(point):
			return scalezones[i];
	return null;

func can_scale_player() ->bool:
	if scalezones :
		return true;
	else :
		return false;

func get_player_speed() ->int:
	return player_speed;

func has_player2_position() ->bool:
	if player2_position_node :
		return true;
	else :
		return false;

func get_player2_position() ->Vector2:
	return player2_position_node.global_position;

func chara_started_move() ->void:
	moving_chars_count += 1;
	set_process(true);

func chara_finished_move() ->void:
	moving_chars_count -= 1;
	if moving_chars_count <= 0 :
		set_process(false);

func _process(_delta) ->void:
	var chars_count = chars_node.get_child_count();
	if chars_count < 2 :
		set_process(false);
		return;
	for i in range(0, chars_count-1, 1) :
		if chars_node.get_child(i).global_position.y > chars_node.get_child(i+1).global_position.y:
			chars_node.move_child(chars_node.get_child(i+1),i);

