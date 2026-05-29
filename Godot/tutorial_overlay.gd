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
		{
			"title": "Welcome to Flyntic Studio",
			"desc": "This tutorial will help you understand the workspace and build your first drone simulation.",
			"target": null
		},

		{
			"title": "Hierarchy Panel",
			"desc": "All drone parts and objects appear here. Select an item to inspect or modify it.",
			"target": $"../Content/Left/HierarchyPanel"
		},

		{
			"title": "Components Panel",
			"desc": "Browse available drone parts such as motors, batteries, and flight controllers.",
			"target": $"../Content/Left/CompPanel"
		},

		{
			"title": "Workspace",
			"desc": "This is where you assemble and preview your drone in real time.",
			"target": $"../Content/CenterRight/Center"
		}
	]

	show_step()

func hide_tutorial():

	dark_bg.visible = false
	highlight.visible = false
	$MessagePanel.visible = false
func show_tutorial():

	dark_bg.visible = true
	highlight.visible = true
	$MessagePanel.visible = true
func show_step():

	var step = steps[current_step]
	
	title.text = step.title
	desc.text = step.desc

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
