class_name Master extends Control

@export var comp_scenes: Array[PackedScene]

@onready var name_edit: LineEdit = $NameEdit
@onready var component_cont: HBoxContainer = $Components/HBoxContainer/ScrollContainer/HBoxContainer
@onready var logic_cont: Control = $Container

const DRAG_COMPONENT: PackedScene = preload("uid://b1plp2e5g4ulg")
const USER_COMPONENT: PackedScene = preload("uid://xjxlk2qmumu0")
const LOGIC_PANEL: PackedScene = preload("uid://b6yx30n0a22xx")
const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = SAVE_DIR + "data.res"
const GRID_COLOR: Color = Color(0.187, 0.187, 0.187)

var logic_panel: LogicPanel = null
var inspected_logic: Array[LogicPanel] = []
var draft_name: String = ""
var data: SaveData = SaveData.new()
static var snapping: bool = false
static var inspecting: bool = false

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	if FileAccess.file_exists(SAVE_FILE):
		_load_data()
	
	logic_panel = LOGIC_PANEL.instantiate()
	logic_panel.comp_instantiate_request.connect(_on_comp_instantiate_request)
	logic_cont.add_child(logic_panel)

func _on_create_component_pressed() -> void:
	if name_edit.text.is_empty():
		name_edit.grab_focus()
		return
	
	_add_component(name_edit.text)
	
	_save_data()
	
	logic_panel.queue_free()
	logic_panel = LOGIC_PANEL.instantiate()
	logic_cont.add_child(logic_panel)
	
	name_edit.clear()

func _add_component(comp_name: StringName) -> void:
	var button: ComponentDrag = DRAG_COMPONENT.instantiate()
	button.text = comp_name.to_upper()
	
	var comp: UserComponent = USER_COMPONENT.instantiate()
	comp.component_name = comp_name
	comp.component_color = Color.from_hsv(
		fmod(hash(comp_name.to_upper())/1000.0, 1.0),
		1.0, .72
	)
	comp.logic_idx = comp_scenes.size()
	
	var comp_scene: PackedScene = PackedScene.new()
	comp_scene.pack(comp)
	comp_scenes.push_back(comp_scene)
	button.idx = comp_scenes.size() - 1
	
	button.comp_instantiate_request.connect(_on_comp_instantiate_request)
	
	component_cont.add_child(button)

func _on_comp_instantiate_request(idx: int, panel: LogicPanel = null) -> void:
	if idx < 0:
		return
	
	if not panel:
		panel = logic_panel
	
	var comp: Component = comp_scenes[idx].instantiate()
	panel.add_child(comp, true)
	panel.components.push_back(comp)
	panel.comp_indicies[comp.component_name] = idx
	
	if comp is UserComponent:
		comp.logic = _load_logic(comp.logic_idx)
		comp.inspect_request.connect(_inspect_logic.bind(comp.logic))

func _inspect_logic(logic: LogicPanel) -> void:
	if not inspected_logic.is_empty():
		inspected_logic.back().hide()
	logic_panel.hide()
	logic.show()
	
	inspected_logic.push_back(logic)
	name_edit.editable = false
	if not inspecting:
		draft_name = name_edit.text
	name_edit.text = " Inspecting %s gate... " %logic.logic_name
	
	inspecting = true

func _save_data() -> void:
	var logic_data: LogicData = LogicData.new()
	logic_panel.save_data(logic_data)
	logic_data.name = name_edit.text.to_upper()
	
	data.logics.push_back(logic_data)
	if (ResourceSaver.save(data, SAVE_FILE) != OK):
		printerr("Couldn't save to %s" %SAVE_FILE)

func _load_data() -> void:
	var loaded_data: SaveData = load(SAVE_FILE)
	if not loaded_data:
		return
	
	data = loaded_data
	for logic_data: LogicData in loaded_data.logics:
		_add_component(logic_data.name)

func _load_logic(idx: int) -> LogicPanel:
	var logic_data: LogicData = data.logics[idx-1]
	var panel: LogicPanel = LOGIC_PANEL.instantiate()
	panel.comp_instantiate_request.connect(_on_comp_instantiate_request)
	
	panel.hide()
	panel.name = logic_data.name
	logic_cont.add_child(panel)
	panel.load_data(logic_data)
	
	return panel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inspect_out") and not event.is_echo():
		if inspecting:
			inspected_logic.back().hide()
			inspected_logic.pop_back()
			if inspected_logic.is_empty():
				logic_panel.show()
				name_edit.editable = true
				name_edit.text = draft_name
				
				inspecting = false
			else :
				inspected_logic.back().show()
				name_edit.text = " Inspecting %s gate... " %inspected_logic.back().logic_name
	
	if event.is_action_pressed("exit_inspection"):
		if inspecting:
			inspected_logic.back().hide()
			inspected_logic.clear()
			logic_panel.show()
			name_edit.editable = true
			name_edit.text = draft_name
			
			inspecting = false
	
	if inspecting:
		return
	
	if event.is_action("snap_to_grid"):
		snapping = event.is_pressed()
		queue_redraw()

func _draw() -> void:
	if snapping:
		for x: int in range(0, logic_cont.size.x / Utils.GRID_STEP_PX / 2):
			draw_line(
				Vector2(
					x * Utils.GRID_STEP_PX * 2 + logic_cont.global_position.x,
					logic_cont.global_position.y
				),
				Vector2(
					x * Utils.GRID_STEP_PX * 2 + logic_cont.global_position.x,
					logic_cont.global_position.y + logic_cont.size.y
				),
				GRID_COLOR
			)
		
		for y: int in range(0, logic_cont.size.y / Utils.GRID_STEP_PX / 2):
			draw_line(
				Vector2(
					logic_cont.global_position.x,
					y * Utils.GRID_STEP_PX * 2 + logic_cont.global_position.y
				),
				Vector2(
					logic_cont.global_position.x + logic_cont.size.x,
					y * Utils.GRID_STEP_PX * 2 + logic_cont.global_position.y
				),
				GRID_COLOR
			)
	
	
