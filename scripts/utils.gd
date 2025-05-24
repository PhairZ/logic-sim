class_name Utils extends Node

const GRID_STEP_PX: int = 8

static func get_snapped_position(
	position: Vector2, guide_ref: Vector2 = Vector2.INF
) -> Vector2:
	if Input.is_action_pressed("snap_to_grid"):
		position = round(position  / GRID_STEP_PX) * GRID_STEP_PX
	
	if Input.is_action_pressed("guide"):
		var delta_x: float = abs(guide_ref.x - position.x)
		var delta_y: float = abs(guide_ref.y - position.y)
		if delta_x > delta_y:
			position.y = guide_ref.y
		else :
			position.x = guide_ref.x
	
	return position
