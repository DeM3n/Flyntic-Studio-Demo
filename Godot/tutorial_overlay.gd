extends CanvasLayer
@onready var dark_bg = $DarkBG
@onready var title = $MessagePanel/VBoxContainer/Title
@onready var desc = $MessagePanel/VBoxContainer/Description
@onready var highlight = $Highlight

var current_step = 0
var steps = []

func _ready():
	highlight.visible = false

	steps = [
	{"title":" Welcome to Flyntic Studio",
		 "desc":"Walk through Canvas, Blocks, and Wiring workspaces. Press Next to continue.",
		 "target":null},

		{"title":" Canvas — Assemble Your Drone",
		"desc":"Place and position components here.\n• Middle-drag → Pan  •  Scroll → Zoom\n• WASD → Move camera  •  Q/E → Up/Down  •  Shift → Fast move\n• After assembly, go to Wiring tab before simulating",
		 "target":$"../Content/CenterRight/Center"},

		{"title":" Hierarchy Panel",
		 "desc":"All placed objects listed here. Click any entry to select it in the workspace.",
		 "target":$"../Content/Left/HierarchyPanel"},

		{"title":" Components Panel",
		 "desc":"Browse drone parts — motors, ESC, battery, flight controller. Click to place onto canvas.",
		 "target":$"../Content/Left/CompPanel"},

		{"title":" Blocks — Visual Programming",
		 "desc":"Program drone behaviour without code.\n• Drag blocks from left panel\n• Connect pins to build logic",
		 "target":$"../Content/CenterRight/Center"},

		{"title":" Wiring — Circuit Connections",
		 "desc":"Wire electrical connections between components.\n• Click a port → start wire  •  Click another port → connect\n",
		 "target":$"../Content/CenterRight/Center"},



		{"title":" You're Ready!",
		 "desc":"1. Canvas → build shape\n2. Blocks → program behaviour\n3. Wiring → connect circuit\nPress Help anytime to replay this guide.",
		 "target":null},
	]
	if ProjectState.is_tutorial_seen():
		hide_tutorial()
		return
	show_step()

func hide_tutorial():
	ProjectState.mark_tutorial_seen()
	self.visible = false
	dark_bg.visible = false
	highlight.visible = false
	$MessagePanel.visible = false

func show_tutorial():
	self.visible = true
	dark_bg.visible = true
	highlight.visible = true
	$MessagePanel.visible = true

func show_step():
 
	var step = steps[current_step]
	
	title.text = step.title
	desc.text = step.desc
	await get_tree().process_frame
	$MessagePanel.reset_size()



	var material = dark_bg.material

	if step.target == null:

		highlight.visible = false

		#var material = dark_bg.material

		material.set_shader_parameter(
			"hole_position",
			Vector2(-9999, -9999)
		)

		material.set_shader_parameter(
			"hole_size",
			Vector2.ZERO
		)

		return

	var target = step.target

	highlight.global_position = target.global_position
	highlight.size = target.size

	highlight.visible = true

	#var material = dark_bg.material

	material.set_shader_parameter(
		"hole_position",
		target.global_position
	)

	material.set_shader_parameter(
	"hole_size",
	target.size
	)
	
func _on_next_button_pressed():

	current_step += 1

	if current_step >= steps.size():
		hide_tutorial()
		return

	show_step()


func _on_help_button_pressed() -> void:
	current_step = 0

	show_tutorial()

	show_step() 


func _on_m_8_pressed() -> void:
	current_step = 0

	show_tutorial()

	show_step() 
