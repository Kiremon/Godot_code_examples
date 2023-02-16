extends Node2D

var begin :Position2D;
var end :Position2D;
var scale_growth :float;
export var scale_top :float = 0.5;
export var scale_bottom :float = 1;
export var speed_penalty :int = -100;

func _ready() ->void:
	begin = get_child(0);
	end = get_child(1);
	scale_growth = scale_bottom - scale_top;

func in_use(point :Vector2) ->bool:
	return (point.x > begin.global_position.x 
		and point.x < end.global_position.x 
		and point.y > begin.global_position.y 
		and point.y < end.global_position.y);

func get_player_scale(point :Vector2) ->float:
	if not in_use(point) : 
		return 0.0;
	
	var portion :float = (point.y - begin.global_position.y) / (end.global_position.y - begin.global_position.y);
	return (portion * scale_growth) + scale_top;

func get_speed_penalty(direction :Vector2) ->int:
	#В данный момент мы считаем штраф строго по оси y, а нужно считать по оси перспективы, которая в каждой зоне должна мочь быть уникальной
	return int(abs(direction.y) * speed_penalty);
