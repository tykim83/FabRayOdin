package fabrayodin

get_rect_from_centre_world_pos_and_size :: proc(entity: $T) -> Vector2f {
    return rl.Rectangle{
        x = entity.pos.x - entity.size.x / 2,
        y = entity.pos.y - entity.size.y / 2,
        width = entity.size.x,
        height = entity.size.y,
    }
}

get_grid_pos_from_index :: proc(index: int) -> Vector2i {
    row := index / GRID_COLUMNS
    col := index % GRID_COLUMNS
    return { col, row }
}

get_index_from_grid_pos :: proc(pos: Vector2i) -> i32 {
    return i32(pos.y * GRID_COLUMNS + pos.x)
}

get_grid_pos_from_world_pos :: proc(pos: Vector2f) -> Vector2i32 {
    grid_x := i32(pos.x) / GRID_TILE_SIZE
    grid_y := i32(pos.y) / GRID_TILE_SIZE
    return { grid_x, grid_y }
}

get_world_pos_from_grid_pos :: proc(col, row: int) -> Vector2f {
    return { f32(col * GRID_TILE_SIZE), f32(row * GRID_TILE_SIZE) }
}
