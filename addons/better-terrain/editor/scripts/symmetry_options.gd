@tool
extends OptionButton

func _gui_input(event: InputEvent) -> void:
    # 检查是否是鼠标滚轮事件
    if event is InputEventMouseButton:
        # 检查是否是滚轮滚动（向上或向下）
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            # 检查Ctrl键是否被按住（Command键在Mac上）
            if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
                # 防止滚动太快，使用单次触发
                if event.is_pressed():
                    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                        selected = max(0, selected - 1)  # 向上滚动，-1，最小为0
                    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                        selected = min(item_count - 1, selected + 1)  # 向下滚动，+1，最大为item_count-1
