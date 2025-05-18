class_name Master extends Control


@onready var name_edit: LineEdit = $NameEdit
@onready var component_cont: HBoxContainer = $Components/HBoxContainer/ScrollContainer/HBoxContainer
@onready var logic_cont: Control = $Container

const DRAG_COMPONENT: PackedScene = preload("uid://b1plp2e5g4ulg")
const USER_COMPONENT: PackedScene = preload("uid://xjxlk2qmumu0")
const LOGIC_PANEL: PackedScene = preload("uid://b6yx30n0a22xx")
const SAVE_DIR: String = "res://saves/"
const SAVE_FILE: String = SAVE_DIR + "data.tres"

var logic_panel: LogicPanel = null
@export var comp_scenes: Array[PackedScene]
var data: SaveData = SaveData.new()


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	if FileAccess.file_exists(SAVE_FILE):
		var loaded_data: SaveData = load(SAVE_FILE)
		if loaded_data:
			data = loaded_data
			for logic_data: LogicData in loaded_data.logics:
				logic_panel = LOGIC_PANEL.instantiate()
				logic_panel.comp_instantiate_request.connect(on_comp_instantiate_request)
				
				logic_panel.hide()
				logic_panel.name = logic_data.name
				logic_cont.add_child(logic_panel)
				logic_panel.load_data(logic_data)
				
				add_component(logic_data.name, logic_panel)
	
	logic_panel = LOGIC_PANEL.instantiate()
	logic_panel.comp_instantiate_request.connect(on_comp_instantiate_request)
	logic_cont.add_child(logic_panel)


func _on_create_component_pressed() -> void:
	if name_edit.text.is_empty():
		name_edit.grab_focus()
		return
	
	logic_panel.hide()
	logic_panel.name = name_edit.text.to_pascal_case()
	
	add_component(name_edit.text, logic_panel)
	
	var logic_data: LogicData = LogicData.new()
	logic_panel.save_data(logic_data)
	logic_data.name = name_edit.text.to_upper()
	
	data.logics.push_back(logic_data)
	if (ResourceSaver.save(data, SAVE_FILE) != OK):
		printerr("Couldn't save to %s" %SAVE_FILE)
	
	logic_panel = LOGIC_PANEL.instantiate()
	logic_cont.add_child(logic_panel)
	
	name_edit.clear()


func add_component(comp_name: StringName, logic: LogicPanel) -> void:
	var button: ComponentDrag = DRAG_COMPONENT.instantiate()
	button.text = comp_name.to_upper()
	
	var comp: UserComponent = USER_COMPONENT.instantiate()
	comp.component_name = comp_name
	comp.logic = logic
	
	var comp_scene: PackedScene = PackedScene.new()
	comp_scene.pack(comp)
	comp_scenes.push_back(comp_scene)
	button.idx = comp_scenes.size() - 1
	
	button.comp_instantiate_request.connect(on_comp_instantiate_request)
	
	component_cont.add_child(button)


func on_comp_instantiate_request(idx: int)-> void:
	if idx < 0:
		return
	
	var comp: Component = comp_scenes[idx].instantiate()
	logic_panel.add_child(comp, true)
	logic_panel.components.push_back(comp)
	logic_panel.comp_indicies[comp.component_name] = idx
