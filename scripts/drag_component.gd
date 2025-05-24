class_name ComponentDrag extends Button


signal comp_instantiate_request(idx: int)

@export var idx: int = -1


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if Master.inspecting:
		return
	
	comp_instantiate_request.emit(idx)
