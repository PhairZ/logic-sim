class_name ConnectionPoint extends Control

signal start_connection
signal flipped(bit: int)

@export var output: bool = false

@export_storage var connected_points: Array[ConnectionPoint]
@export_storage var connection_lines: Dictionary[ConnectionPoint, Line2D]

const CONNECTION_LINE: PackedScene = preload("uid://dm7tu5yw7my1m")

var bit: bool = 0:
	set = set_bit
var updates: int = 0

func _on_gui_input(event: InputEvent) -> void:
	if Master.inspecting:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			start_connection.emit()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			disconnect_points()

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		if not gui_input.is_connected(_on_gui_input):
			gui_input.connect(_on_gui_input)
		if not draw.is_connected(update_line):
			draw.connect(update_line, CONNECT_DEFERRED)

func set_bit(value: bool) -> void:
		if bit == value:
			return
		
		while updates == 1:
			await get_tree().physics_frame
		
		bit = value
		updates += 1
		
		for point: ConnectionPoint in connected_points:
			update_line(point)
		
		flipped.emit(int(value) << get_index())
		
		if connected_points and output:
			for point: ConnectionPoint in connected_points:
				point.set_bit(value)
		
		if updates > 1:
			await get_tree().physics_frame
		updates -= 1

func disconnect_points(points: Array[ConnectionPoint] = connected_points) -> void:
	while not points.is_empty():
		var point: ConnectionPoint = points.pop_front()
		
		if output == point.output:
			printerr("Trying to disconnect points of the same IO type. Ignoring")
			continue
		
		if not output:
			point.disconnect_points([self])
			continue
		
		connected_points.erase(point)
		
		point.connected_points.clear()
		point.set_bit(0)
		
		update_line(point)

func connect_to(point: ConnectionPoint, line_points: PackedVector2Array = []) -> void:
	if not point or point.output == output:
		return
	
	if not output:
		line_points.reverse()
		point.connect_to(self, line_points)
		return
	
	point.disconnect_points()
	
	if point not in connected_points:
		connected_points.push_back(point)
		point.connected_points = [self]
	
	point.bit = bit
	
	update_line(point, line_points)

func update_line(point: ConnectionPoint = null, line_points: PackedVector2Array = []) -> void:
	if not point:
		for connected_point: ConnectionPoint in connected_points:
			update_line(connected_point)
		return
	
	if point not in connected_points:
		if output and point in connection_lines:
			connection_lines[point].queue_free()
			connection_lines.erase(point)
		return
	
	if not output:
		if not line_points.is_empty():
			line_points.reverse()
		
		point.update_line(self, line_points)
		return
	
	if point not in connection_lines:
		var line: Line2D = CONNECTION_LINE.instantiate()
		
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		
		
		line.points[0] = global_position + size / 2 * scale
		
		connection_lines[point] = line
		add_child(line)
	
	if not line_points.is_empty():
		connection_lines[point].points = line_points
	
	connection_lines[point].default_color = Color("#bc1414") if bit else Color("#1d1b24")
	
	connection_lines[point].points[-1] = point.global_position\
		+ point.size / 2 * point.scale
	connection_lines[point].points[0] = global_position\
		+ size / 2 * scale
