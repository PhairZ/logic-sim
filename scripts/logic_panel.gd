class_name LogicPanel extends Control


signal comp_instantiate_request()


@export var inputs: int = 2:
	set(value):
		inputs = value
		
		if not is_node_ready():
			await ready
		
		if value < 0:
			inputs = 0
		
		update_input(inputs)

@export var outputs: int = 1:
	set(value):
		outputs = value
		
		if not is_node_ready():
			await ready
		
		if value < 0:
			outputs = 0
		
		update_output(outputs)

@onready var in_cont: VBoxContainer = $Input
@onready var out_cont: VBoxContainer = $Output

const IO_BUTTON: PackedScene = preload("uid://bceo2vmyl5f2s")
const CONNECTION_LINE: PackedScene = preload("uid://dm7tu5yw7my1m")

var comp_indicies: Dictionary[StringName, int]

var connection_points: Array[ConnectionPoint]
var components: Array[Component]
var connecting_from: ConnectionPoint = null
var connecting_line: Line2D = null
var connecting_to: ConnectionPoint = null


var output: int = 0:
	get():
		for point: ConnectionPoint in out_cont.get_children():
			output = (output & ~(1 << point.get_index())) | int(point.bit) << point.get_index()
		
		return output

var input: int = 0:
	set(value):
		input = value
		for point: ConnectionPoint in in_cont.get_children():
			point.bit = value & 1 << point.get_index()


func _ready() -> void:
	update_input(inputs)
	update_output(outputs)


func update_input(value: int) -> void:
	var diff: int = value - in_cont.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var point: ConnectionPoint = IO_BUTTON.instantiate()
			point.output = true
			point.start_connection.connect(
				func() -> void:
					start_connection(point)
			)
			in_cont.add_child(point)
			point.owner = self
			
			connection_points.append(point)
	elif (diff < 0):
		var points: Array[Node] = in_cont.get_children()
		for i: int in -diff:
			var point: ConnectionPoint = points[-i - 1] as ConnectionPoint
			if not point:
				continue
			
			connection_points.erase(point)
			point.disconnect_points()
			point.queue_free()
	
	await in_cont.sort_children
	for point: ConnectionPoint in in_cont.get_children():
		point.update_lines()


func update_output(value: int) -> void:
	var diff: int = value - out_cont.get_child_count()
	if (diff > 0):
		for i: int in diff:
			var point: ConnectionPoint = IO_BUTTON.instantiate()
			point.output = false
			point.button_mask = 0
			point.start_connection.connect(
				func() -> void:
					start_connection(point)
			)
			out_cont.add_child(point)
			point.owner = self
			
			connection_points.append(point)
	elif (diff < 0):
		var points: Array[Node] = out_cont.get_children()
		for i: int in -diff:
			var point: ConnectionPoint = points[-i - 1] as ConnectionPoint
			if not point:
				continue
			
			connection_points.erase(point)
			point.disconnect_points()
			point.queue_free()
	
	await out_cont.sort_children
	for point: ConnectionPoint in out_cont.get_children():
		point.update_lines()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if connecting_from:
			connecting_to = null
			var target_point: Vector2 = event.position
			
			for point: ConnectionPoint in connection_points:
				if point.output != connecting_from.output and is_mouse_over_point(point):
					connecting_to = point
					target_point = point.global_position + point.size / 2 * point.scale
					break
			
			connecting_line.points[-1] = target_point - global_position
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if connecting_from:
				if connecting_to:
					connecting_from.connect_to(connecting_to)
				
				connecting_from = null
				connecting_line.queue_free()
				connecting_line = null

func _on_in_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			inputs += 1
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			inputs -= 1


func _on_out_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			outputs += 1
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			outputs -= 1


func start_connection(point: ConnectionPoint) -> void:
	connecting_from = point
	
	var line: Line2D = CONNECTION_LINE.instantiate()
	line.add_point(point.global_position + point.size / 2 * point.scale - global_position)
	line.add_point(point.global_position + point.size / 2 * point.scale - global_position)
	
	connecting_line = line
	add_child(line)


func save_data(data: LogicData) -> void:
	data.inputs = inputs
	data.outputs = outputs
	
	for component: Component in components:
		var component_data: ComponentData = ComponentData.new()
		component.save_data(component_data)
		component_data.scene_idx = comp_indicies[component.component_name]
		component_data.name = component.component_name
		data.components.push_back(component_data)
	
	for point: ConnectionPoint in connection_points:
		if not point.connected_to:
			continue
		
		var conn_data: ConnectionData = ConnectionData.new()
		
		if point.owner is Component:
			conn_data.owner = components.find(point.owner)
			conn_data.container = point.get_parent().get_parent().get_index()
		else :
			conn_data.owner = -1
			conn_data.container = point.get_parent().get_index()
		conn_data.point = point.get_index()
		
		if point.connected_to.owner is Component:
			conn_data.to_owner = components.find(point.connected_to.owner)
			conn_data.to_container = point.connected_to.get_parent().get_parent().get_index()
		else :
			conn_data.to_owner = -1
			conn_data.to_container = point.connected_to.get_parent().get_index()
		conn_data.to_point = point.connected_to.get_index()
	
		data.connections.push_back(conn_data)


func load_data(data: LogicData) -> void:
	if not data:
		return
	
	inputs = data.inputs
	outputs = data.outputs
	
	for component: ComponentData in data.components:
		comp_instantiate_request.emit(component.scene_idx)
		components[-1].load_data(component)
	
	for connection: ConnectionData in data.connections:
		var own: int = connection.owner
		var cont: int = connection.container
		var point: int = connection.point
		var to_own: int = connection.to_owner
		var to_cont: int = connection.to_container
		var to_point: int = connection.to_point
		
		var from: ConnectionPoint
		if own == -1:
			from = get_child(cont).get_child(point)
		else :
			from = components[own].get_child(cont).get_child(0).get_child(point)
		
		var to: ConnectionPoint
		if to_own == -1:
			to = get_child(to_cont).get_child(to_point)
		else :
			to = components[to_own].get_child(to_cont).get_child(0).get_child(to_point)
		
		from.connect_to(to)


func is_mouse_over_point(point: ConnectionPoint) -> bool:
	return point.get_global_rect().has_point(get_global_mouse_position())
