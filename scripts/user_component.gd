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
			
			get_tree().physics_frame.connect(input_updated.emit)
			
			input_updated.connect(
				func() -> void:
					value.input = input
					output = value.output
			)
			
			tree_exited.connect(logic.queue_free)
			
			input = 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if logic:
				inspect_request.emit()
