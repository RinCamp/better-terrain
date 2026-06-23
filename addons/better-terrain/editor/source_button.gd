@tool
extends Button

var id : int

func _ready():
    toggled.connect(_on_toggled)


func _on_toggled(toggled_on):
    if toggled_on:
        icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
    else:
        icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
