class_name LogicPanel extends Control

signal comp_instantiate_request()

@export var inputs: int = 2:
	set(value):
		inputs = value
		
		if not is_node_ready():
			await ready
		
		if value < 0:
			inputs = 0
		
		_update_input(inputs)

@export var outputs: int = 1:
	set(value):
		outputs = value
		
		if not is_node_ready():
			await ready
		
		if value < 0:
			outputs = 0
		
		_update_output(outputs)

@export_storage var logic_name: StringName = &""

@onready var in_cont: VBoxContainer = $Input
@onready var out_cont: VBoxContainer = $Output

const IO_BUTTON: PackedScene = preload("uid://bceo2vmyl5f2s")
const CONNECTION_LINE: PackedScene = preload("uid://dm7tu5yw7my1m")

var comp_indicies: Dictionary[StringName, int] = {}

var connection_points: Array[ConnectionPoint] = []
var components: Array[Component] = []
var connecting_from: ConnectionPoint = null
var connecting_line: Line2D = null
var connecting_to: ConnectionPoint = null

var output: int = 0:
	get():
		output = 0
		for button: IOButton in out_cont.get_children():
			output |= int(button.connection_point.bit) << button.get_index()
		
		return output

var input: int = 0:
	set(value):
		input = value
		for button: IOButton in in_cont.get_children():
			button.button_pressed = value & 1 << button.get_index()

func _ready() -> void:
	_update_input(inputs)
	_update_output(outputs)

func _update_input(value: int) -> void:
	var diff: int = value - in_cont.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var button: IOButton = IO_BUTTON.instantiate()
			button.output = true
			in_cont.add_child(button)
			button.owner = self
			button.connection_point.start_connection.connect(
				start_connection.bind(button.connection_point)
			)
			
			connection_points.append(button.connection_point)
	elif (diff < 0):
		var buttons: Array[Node] = in_cont.get_children()
		for i: int in -diff:
			var button: IOButton = buttons[-i - 1] as IOButton
			if not button:
				continue
			
			connection_points.erase(button.connection_point)
			button.connection_point.disconnect_points()
			button.queue_free()
	
	await in_cont.sort_children
	for button: IOButton in in_cont.get_children():
		button.connection_point.update_line()

func _update_output(value: int) -> void:
	var diff: int = value - out_cont.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var button: IOButton = IO_BUTTON.instantiate()
			button.output = false
			button.button_mask = 0
			out_cont.add_child(button)
			button.owner = self
			button.connection_point.start_connection.connect(
				start_connection.bind(button.connection_point)
			)
			
			connection_points.append(button.connection_point)
	elif (diff < 0):
		var buttons: Array[Node] = out_cont.get_children()
		for i: int in -diff:
			var button: IOButton = buttons[-i - 1] as IOButton
			if not button:
				continue
			
			connection_points.erase(button.connection_point)
			button.connection_point.disconnect_points()
			button.queue_free()
	
	await out_cont.sort_children
	for button: IOButton in out_cont.get_children():
		button.connection_point.update_line()

func _input(event: InputEvent) -> void:
	if Master.inspecting:
		return
	
	if event is InputEventMouseMotion:
		if connecting_from:
			connecting_to = null
			
			var target_point: Vector2 = Utils.get_snapped_position(
				event.position, connecting_line.points[-2]
			)
			
			for point: ConnectionPoint in connection_points:
				if point.output != connecting_from.output and _is_mouse_over_point(point):
					connecting_to = point
					target_point = point.global_position + point.size / 2 * point.scale
					break
			
			connecting_line.points[-1] = target_point
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if connecting_from and connecting_to:
				connecting_from.connect_to(connecting_to, Array(connecting_line.points).map(
					func(pos: Vector2) -> Vector2:
						return pos
				))
				
				if connecting_line:
					connecting_line.queue_free()
				connecting_from = null
				connecting_to = null
				connecting_line = null
				
				if event.is_pressed():
					get_viewport().set_input_as_handled()
			elif event.is_pressed() and connecting_line:
				var target_point: Vector2 = Utils.get_snapped_position(
					event.position, connecting_line.points[-2]
				)
				
				connecting_line.points[-1] = target_point
				connecting_line.add_point(target_point)
				
				get_viewport().set_input_as_handled()
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
				if connecting_line:
					connecting_line.queue_free()
				connecting_from = null
				connecting_line = null

func _is_mouse_over_point(point: ConnectionPoint) -> bool:
	return point.get_global_rect().has_point(get_global_mouse_position())

func _on_in_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not connecting_from:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				inputs += 1
			if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				inputs -= 1

func _on_out_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not connecting_from:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				outputs += 1
			if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				outputs -= 1

func start_connection(point: ConnectionPoint) -> void:
	connecting_from = point
	
	if connecting_line:
		connecting_line.queue_free()
		connecting_line = null
	
	var line: Line2D = CONNECTION_LINE.instantiate()
	line.default_color = Color("#bc1414") if connecting_from.bit else Color("#1d1b24")
	line.add_point(point.global_position + point.size / 2 * point.scale)
	line.add_point(point.global_position + point.size / 2 * point.scale)
	
	connecting_line = line
	add_child(line)

func save_data(data: LogicData) -> void:
	data.inputs = inputs
	data.outputs = outputs
	
	for component: Component in components:
		var component_data: ComponentData = ComponentData.new()
		component.save_data(component_data)
		component_data.scene_idx = comp_indicies[component.component_name]
		data.components.push_back(component_data)
	
	for point: ConnectionPoint in connection_points:
		if not point.output:
			continue
		
		var conn_data: ConnectionData = ConnectionData.new()
		
		if point.owner is Component:
			conn_data.owner = components.find(point.owner)
			conn_data.container = point.get_parent().get_parent().get_index()
			conn_data.point = point.get_index()
		else :
			conn_data.owner = -1
			conn_data.container = point.get_parent().get_parent().get_index()
			conn_data.point = point.get_parent().get_index()
		
		for connected_to: ConnectionPoint in point.connected_points:
			if connected_to.owner is Component:
				conn_data.to_owners.push_back(components.find(connected_to.owner))
				conn_data.to_containers.push_back(
					connected_to.get_parent().get_parent().get_index()
				)
				conn_data.to_points.push_back(connected_to.get_index())
			else :
				conn_data.to_owners.push_back(-1)
				conn_data.to_containers.push_back(
					connected_to.get_parent().get_parent().get_index()
				)
				conn_data.to_points.push_back(connected_to.get_parent().get_index())
			
			conn_data.line_points.push_back(
				point.connection_lines[connected_to].points
			)
		
		data.connections.push_back(conn_data)

func load_data(data: LogicData) -> void:
	if not data:
		return
	
	inputs = data.inputs
	outputs = data.outputs
	logic_name = data.name
	
	for component: ComponentData in data.components:
		comp_instantiate_request.emit(component.scene_idx, self)
		components[-1].load_data(component)
	
	for connection: ConnectionData in data.connections:
		var from: ConnectionPoint
		if connection.owner == -1:
			from = get_child(connection.container).get_child(connection.point).connection_point
		else :
			from = components[connection.owner].get_child(connection.container)\
				.get_child(0).get_child(connection.point)
		
		for i: int in connection.to_points.size():
			var to: ConnectionPoint
			if connection.to_owners[i] == -1:
				to = get_child(connection.to_containers[i])\
					.get_child(connection.to_points[i]).connection_point
			else :
				to = components[connection.to_owners[i]]\
					.get_child(connection.to_containers[i])\
					.get_child(0).get_child(connection.to_points[i])
			
			from.connect_to(to, connection.line_points[i])
