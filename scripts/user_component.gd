class_name UserComponent extends Component

signal inspect_request()

@export_storage var logic_idx: int = 0

var logic: LogicPanel:
	set(value):
		logic = value
		
		if not is_node_ready():
			await ready
		
		if value:
			inputs = value.inputs
			outputs = value.outputs
			
			var on_output_update: Callable = func() -> void:
				output = value.output
				print(output)
			
			value.output_updated.connect(on_output_update)
			
			input_updated.connect(
				func() -> void:
					if value.output_updated.is_connected(on_output_update):
						value.output_updated.disconnect(on_output_update)
					
					value.input = input
					output = value.output
					
					if not value.output_updated.is_connected(on_output_update):
						value.output_updated.connect(on_output_update)
			)
			
			tree_exited.connect(logic.queue_free)
			
			input = 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if logic:
				inspect_request.emit()
