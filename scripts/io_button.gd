class_name IOButton extends Button

@export var output: bool = false:
	set(value):
		output = value
		
		if not is_node_ready():
			await ready
		
		line_2d.position.x = 0 if value else -28
		connection_point.position.x = 28 if value else -16
		
		connection_point.output = value
		
		if output:
			toggled.connect(
				func(toggled_on: bool) -> void:
					connection_point.bit = toggled_on
			)
		else :
			connection_point.flipped.connect(func(bit: bool) -> void: button_pressed = bit)

@onready var connection_point: ConnectionPoint = $ConnectionPoint
@onready var line_2d: Line2D = $Line2D
