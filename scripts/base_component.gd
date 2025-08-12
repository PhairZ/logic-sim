class_name Component extends PanelContainer


signal input_updated

@export var component_name: StringName:
	set(value):
		component_name = value
		
		if not is_node_ready():
			await ready
		
		$LabelMargin/Name.text = value

@export var component_color: Color:
	set(value):
		component_color = value
		
		if not is_node_ready():
			await ready
		
		var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		style.bg_color = value
		add_theme_stylebox_override("panel", style)

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
var move_init_pos: Vector2 = Vector2.ZERO

func _on_gui_input(event: InputEvent) -> void:
	if Master.inspecting:
		return
	
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if not logic_panel:
				return
			
			target_pos += event.relative * scale
			global_position.x = clamp(
				Utils.get_snapped_position(target_pos, move_init_pos).x,
				logic_panel.global_position.x + SAFE_AREA,
				logic_panel.global_position.x + logic_panel.size.x - size.x * scale.x - SAFE_AREA
			)
			global_position.y = clamp(
				Utils.get_snapped_position(target_pos, move_init_pos).y,
				logic_panel.global_position.y + SAFE_AREA,
				logic_panel.global_position.y + logic_panel.size.y - size.y * scale.y - SAFE_AREA
			)
			
			for point: ConnectionPoint in input_conns.get_children():
				point.update_line()
			for point: ConnectionPoint in output_conns.get_children():
				point.update_line()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			target_pos = global_position
			move_init_pos = global_position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				var mlb_release: InputEventMouseButton = InputEventMouseButton.new()
				mlb_release.button_index = MOUSE_BUTTON_LEFT
				mlb_release.pressed = false
				Input.parse_input_event(mlb_release)
				
				global_position = move_init_pos
				for point: ConnectionPoint in input_conns.get_children():
					point.update_line()
				for point: ConnectionPoint in output_conns.get_children():
					point.update_line()
				
				mlb_release = mlb_release.duplicate()
				mlb_release.pressed = true
				Input.parse_input_event(mlb_release)
			else :
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
				point.start_connection.connect(logic_panel.start_connection.bind(point))
				point.flipped.connect(
					func(bit: bool) -> void:
						input &= input & ~(1 << point.get_index())
						input |= (int(bit) << point.get_index())
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
				point.start_connection.connect(logic_panel.start_connection.bind(point))
			
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
