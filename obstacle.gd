extends Polygon2D

var waypoints :PoolVector2Array
export var wp_circular :bool = true;

func get_waypoints() ->PoolVector2Array:
	if not waypoints :
		waypoints = get_child(0).get_points();
	return waypoints;

func is_wp_circular() ->bool:
	return wp_circular;
