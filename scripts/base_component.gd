class_name Component extends Control


signal input_updated

@export var component_name: StringName:
	set(value):
		component_name = value
		
		if not is_node_ready():
			await ready
		
		$LabelMargin/Name.text = value

@export var inputs: int = 2:
	set(value):
		inputs = max(value, 0)
		
		if not is_node_ready():
			await ready
		
		update_input(inputs)

@export var outputs: int = 1:
	set(value):
		outputs = max(value, 0)
		
		if not is_node_ready():
			await ready
		
		update_output(outputs)


@onready var logic_panel: LogicPanel = get_parent() as LogicPanel
@onready var input_conns: VBoxContainer = $InputMargin/InputConnections
@onready var output_conns: VBoxContainer = $OutputMargin/OutputConnections

const CONNECTION_POINT: PackedScene = preload("uid://c4r06ed0eh0q8")
const SAFE_AREA: int = 8

var input: int = 0:
	set(value):
		input = value
		input_updated.emit()

var output: int = 0:
	set(value):
		output = value
		
		for point: ConnectionPoint in output_conns.get_children():
			point.bit = value & 1 << point.get_index()

var target_pos: Vector2 = Vector2.ZERO


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if not logic_panel:
				return
			
			target_pos += event.relative * scale
			position.x = clamp(
				target_pos.x,
				SAFE_AREA,
				logic_panel.size.x - size.x * scale.x - SAFE_AREA
			)
			position.y = clamp(
				target_pos.y,
				SAFE_AREA,
				logic_panel.size.y - size.y * scale.y - SAFE_AREA
			)
			
			for point: ConnectionPoint in input_conns.get_children():
				point.update_lines()
			for point: ConnectionPoint in output_conns.get_children():
				point.update_lines()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			target_pos = position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			update_input(0)
			update_output(0)
			logic_panel.components.erase(self)
			queue_free()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if not gui_input.is_connected(_on_gui_input):
				gui_input.connect(_on_gui_input)
			
			update_input(inputs)
			update_output(outputs)
			input_updated.emit()


func update_input(value: int) -> void:
	var diff: int = value - input_conns.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var point: ConnectionPoint = CONNECTION_POINT.instantiate()
			point.output = false
			if logic_panel:
				point.start_connection.connect(
					func() -> void:
						logic_panel.start_connection(point)
				)
				point.flipped.connect(
					func(bit: int) -> void:
						input = (input & ~(1 << point.get_index())) | bit
				)
			input_conns.add_child(point)
			point.owner = self
			logic_panel.connection_points.append(point)
	elif (diff < 0):
		var points: Array[Node] = input_conns.get_children()
		for i: int in -diff:
			var point: ConnectionPoint = points[-i - 1] as ConnectionPoint
			if not point:
				continue
			
			logic_panel.connection_points.erase(point)
			point.disconnect_points()
			point.queue_free()


func update_output(value: int) -> void:
	var diff: int = value - output_conns.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var point: ConnectionPoint = CONNECTION_POINT.instantiate()
			point.output = true
			if logic_panel:
				point.start_connection.connect(
					func() -> void:
						logic_panel.start_connection(point)
				)
			output_conns.add_child(point)
			point.owner = self
			logic_panel.connection_points.append(point)
	elif (diff < 0):
		var points: Array[Node] = output_conns.get_children()
		for i: int in -diff:
			var point: ConnectionPoint = points[-i - 1] as ConnectionPoint
			if not point:
				continue
			
			logic_panel.connection_points.erase(point)
			point.disconnect_points()
			point.queue_free()


func save_data(data: ComponentData) -> void:
	data.position = position


func load_data(data: ComponentData) -> void:
	if not data:
		return
	
	position = data.position
