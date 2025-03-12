package fabrayodin

import rl "vendor:raylib"

get_rect_from_pos_and_size :: proc(p: $T) -> rl.Rectangle {
    return rl.Rectangle{
        x = p.pos.x - p.size.x / 2,
        y = p.pos.y - p.size.y / 2,
        width = p.size.x,
        height = p.size.y,
    }
}
