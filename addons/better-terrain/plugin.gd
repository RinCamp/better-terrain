@tool
extends EditorPlugin

const AUTOLOAD_NAME = "BetterTerrain"
var dock : EditorDock
var dock_scene : Control
var button : Button

func _enter_tree() -> void:
    # Wait for autoloads to register
    await get_tree().process_frame

    if !get_tree().root.get_node_or_null(^"BetterTerrain"):
        # Autoload wasn't present on plugin init, which means plugin won't have loaded correctly
        add_autoload_singleton(AUTOLOAD_NAME, "res://addons/better-terrain/BetterTerrain.gd")
        ProjectSettings.save()

        var confirm = ConfirmationDialog.new()
        confirm.dialog_text = "The editor needs to be restarted for Better Terrain to load correctly. Restart now? Note: Unsaved changes will be lost."
        confirm.confirmed.connect(func():
            OS.set_restart_on_exit(true, ["-e"])
            get_tree().quit()
        )
        get_editor_interface().popup_dialog_centered(confirm)


    dock_scene = load("res://addons/better-terrain/editor/Dock.tscn").instantiate()
    dock_scene.update_overlay.connect(self.update_overlays)
    dock_scene.undo_manager = get_undo_redo()

    dock = EditorDock.new()
    dock.add_child(dock_scene)
    dock.title = "Terrain"
    dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
    dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
    dock.dock_icon = preload("res://addons/better-terrain/icon.svg")
    dock.opened.connect(dock_scene.about_to_be_visible)

    add_dock(dock)

    get_editor_interface().get_editor_main_screen().mouse_exited.connect(dock_scene.canvas_mouse_exit)


func _exit_tree() -> void:
    remove_dock(dock)
    dock.queue_free()


func _handles(object) -> bool:
    return object is TileMapLayer or object is TileSet


func _make_visible(visible) -> void:
    dock.visible = visible


func _edit(object) -> void:
    var new_tileset : TileSet = null

    if object is TileMapLayer:
        dock_scene.tilemap = object
        new_tileset = object.tile_set
    if object is TileSet:
        dock_scene.tilemap = null
        new_tileset = object

    if dock_scene.tileset != new_tileset:
        dock_scene.tiles_about_to_change()
        dock_scene.tileset = new_tileset
        dock_scene.tiles_changed()


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
    if dock_scene.is_visible_in_tree():
        dock_scene.canvas_draw(overlay)


func _forward_canvas_gui_input(event: InputEvent) -> bool:
    if !dock_scene.is_visible_in_tree():
        return false

    return dock_scene.canvas_input(event)
