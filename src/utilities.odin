package fabrayodin

import rl "vendor:raylib"

get_rect_from_pos_and_size :: proc(entity: $T) -> rl.Rectangle {
    return rl.Rectangle{
        x = entity.pos.x - entity.size.x / 2,
        y = entity.pos.y - entity.size.y / 2,
        width = entity.size.x,
        height = entity.size.y,
    }
}
