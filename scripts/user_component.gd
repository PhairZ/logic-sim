class_name UserComponent extends Component

@export_storage var logic: LogicPanel:
	set(value):
		logic = value
		
		if value:
			inputs = value.inputs
			outputs = value.outputs
			input = 0
			
			input_updated.connect(
				func() -> void:
					value.input = input
					output = value.output
			)
