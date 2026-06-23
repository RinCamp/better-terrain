@tool
extends Panel

# 配置参数
@export var zoom_speed: float = 0.3     # 滚轮缩放速度
@export var min_zoom: float = 0.3      # 最小缩放值
@export var max_zoom: float = 10.0     # 最大缩放值

@export var backgroud_canvas: ColorRect
@export var tile_view : Control
@export var button_reset_view : Button

var _is_dragging := false
var _last_drag_screen_pos: Vector2


func _ready():
    tile_view.gui_input.connect(_tile_drag)
    if button_reset_view:
        button_reset_view.pressed.connect(reset_gui_view)

func _tile_drag(event):
    # 将事件转换为当前节点的局部坐标
    var converted_event = event.duplicate()

    # 转换鼠标位置到当前节点的坐标系统
    if converted_event is InputEventMouse:
        # 获取鼠标在 tile_view 中的位置，然后转换到当前节点的坐标系
        var tile_view_pos = tile_view.get_local_mouse_position()
        var global_pos = tile_view.global_position + tile_view_pos * tile_view.scale
        var local_pos = global_pos - global_position

        # 更新事件的位置
        converted_event.position = local_pos

        # 如果是 Motion 事件，还需要转换相对移动
        if converted_event is InputEventMouseMotion:
            # 转换相对移动（考虑 tile_view 的缩放）
            converted_event.relative = event.relative / tile_view.scale

    # 将转换后的事件传递给当前节点的 _gui_input
    _gui_input(converted_event)

func _gui_input(event):
    if event is InputEventKey and event.is_pressed():
        if event.keycode == KEY_F:
            reset_gui_view()

    # 鼠标中键拖动平移
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            grab_focus()
            _is_dragging = event.pressed
            if _is_dragging:
                _last_drag_screen_pos = event.position
                tile_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
            else:
                tile_view.mouse_filter = Control.MOUSE_FILTER_STOP

    # 滚轮缩放（以鼠标位置为中心）
    if event is InputEventMouseButton and event.pressed:
        grab_focus()
        var zoom_direction := 0
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:    # 放大
                zoom_direction = 1
            MOUSE_BUTTON_WHEEL_DOWN:  # 缩小
                zoom_direction = -1

        if zoom_direction != 0:
            var mouse_local_pos_before = (event.position - tile_view.position) / tile_view.scale.x

            # 计算新缩放值
            var new_zoom = clamp(tile_view.scale.x + zoom_speed * zoom_direction , min_zoom, max_zoom)

            # 调整偏移保持鼠标指向的局部坐标不变
            tile_view.position += mouse_local_pos_before * (tile_view.scale.x - new_zoom)
            tile_view.scale = Vector2.ONE * new_zoom

    # 鼠标拖动时的移动
    if _is_dragging and event is InputEventMouseMotion:
        tile_view.position += (event.position - _last_drag_screen_pos)
        _last_drag_screen_pos = event.position


func reset_gui_view():
    var tileset = tile_view.tileset
    var tiles_size = Vector2.ZERO

    if !tileset:
        return

    for s in tileset.get_source_count():
        var source_id = tileset.get_source_id(s)
        var source := tileset.get_source(source_id) as TileSetAtlasSource
        if !source or !source.texture:
            continue
        if source_id in tile_view.disabled_sources:
            continue

        tiles_size.x = max(tiles_size.x, source.texture.get_width())
        tiles_size.y += source.texture.get_height()

    if tiles_size == Vector2.ZERO:
        tiles_size = tile_view.tiles_size

    # 计算目标缩放比例  tile_view.tiles_size
    var content_size = tiles_size * tile_view.scale
    var viewport_ratio = Vector2(size.x / content_size.x, size.y / content_size.y)
    var target_scale = tile_view.scale * min(viewport_ratio.x, viewport_ratio.y)

    # 计算最终显示尺寸 tile_view.tiles_size
    var final_size = tiles_size * target_scale

    # 创建动画
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(tile_view, "scale", target_scale, 0.1)
    tween.parallel().tween_property(tile_view, "position",
        Vector2(
            max(0, (size.x - final_size.x) / 2),
            max(0, (size.y - final_size.y) / 2)
        ),
        0.1)
