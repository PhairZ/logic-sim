class_name ConnectionPoint extends Control


signal start_connection
signal flipped(bit: int)

@export var output: bool = false

@export var connected_to: ConnectionPoint
@export var connection_line: Line2D
var connecting: bool = false
var bit: bool = 0:
	set = _on_bit_set

const CONNECTION_LINE: PackedScene = preload("uid://dm7tu5yw7my1m")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.position.x < 0 or event.position.x > size.x * scale.x\
				or event.position.y < 0 or event.position.y > size.y * scale.y:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				if connecting:
					return
				
				connecting = true
				start_connection.emit()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			connecting = false
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			disconnect_points()


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		if not gui_input.is_connected(_on_gui_input):
			gui_input.connect(_on_gui_input)
		if not draw.is_connected(update_lines):
			draw.connect(update_lines, CONNECT_DEFERRED)


func _on_bit_set(value: bool) -> void:
	bit = value
	
	flipped.emit(int(value) << get_index())
	
	if connected_to and output:
		connected_to.bit = value


func disconnect_points() -> void:
	if not connected_to:
		return
	
	var other: ConnectionPoint = connected_to
	connected_to = null
	update_lines()
	
	other.connected_to = null
	other.update_lines()
	if output:
		other.bit = 0
	else :
		bit = 0


func connect_to(point: ConnectionPoint) -> void:
	if not point or point.output == output:
		return
	
	disconnect_points()
	point.disconnect_points()
	
	connected_to = point
	point.connected_to = self
	
	if output:
		connected_to.bit = bit
	else :
		bit = connected_to.bit
	
	update_lines()


func update_lines() -> void:
	if not connected_to:
		if output and connection_line:
			connection_line.queue_free()
			connection_line = null
		
		return
	
	if not output:
		connected_to.update_lines()
		return
	
	if not connection_line:
		var line: Line2D = CONNECTION_LINE.instantiate()
		line.add_point(size / 2 * scale)
		line.add_point(connected_to.global_position + connected_to.size / 2 * connected_to.scale - global_position)
		
		connection_line = line
		add_child(line)
	
	connection_line.points[-1] = connected_to.global_position\
		+ connected_to.size / 2 * connected_to.scale - global_position
