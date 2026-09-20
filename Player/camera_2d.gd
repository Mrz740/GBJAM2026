extends Camera2D

var min_x: float
var min_y: float
var max_x: float
var max_y: float


func _ready() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()
	
	var tile_size: int = GameMap.instance.TILE_SIZE
	var map_size: int = GameMap.instance.map_size
	
	min_x = viewport_rect.size.x * 0.5
	var min_tile_x: float = min_x / tile_size
	var cam_x_range: float = (map_size - min_tile_x * 2) * tile_size
	max_x = min_x + cam_x_range
	
	min_y = viewport_rect.size.y * 0.5
	var min_tile_y: float = min_y / tile_size
	var cam_y_range: float = (map_size - min_tile_y * 2) * tile_size
	max_y = min_y + cam_y_range


func _process(_delta: float) -> void:
	var target_position: Vector2 = Player.instance.global_position
	
	target_position.x = clampf(target_position.x, min_x, max_x)
	target_position.y = clampf(target_position.y, min_y, max_y + 8.0)
	global_position = target_position
