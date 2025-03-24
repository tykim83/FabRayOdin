package fabrayodin

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

init_pathfinding :: proc(tilemap: Tilemap, allocator := context.allocator, loc := #caller_location) -> Astar_Grid {
    astar_grid := init_astar_grid({0, 0}, {TILEMAP_WIDTH, TILEMAP_HEIGHT}, allocator = allocator, loc = loc)

    for layer in tilemap.layers {
        if !layer.is_collision { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }

            row := index / TILEMAP_WIDTH
            col := index % TILEMAP_WIDTH

            set_blocked_tile(&astar_grid, {i32(col), i32(row)})
        }
    }

    return astar_grid
}

destroy_pathfinding :: proc(astar_grid: ^Astar_Grid, loc := #caller_location) {
    destroy_astar_grid(astar_grid, loc)
}

draw_pathfinding :: proc(car: Car, astar_grid: Astar_Grid) {
    for enemy in active_enemies {
        enemy_tilemap_pos := get_grid_pos_from_world_pos(enemy.pos)
        player_tilmap_pos := get_grid_pos_from_world_pos(car.rb.position)

        path, _ := find_astar_path(astar_grid, enemy_tilemap_pos, player_tilmap_pos)

        for node in path.nodes {
            tile_x := node.tile.pos.x * TILEMAP_TILE_SIZE
            tile_y := node.tile.pos.y * TILEMAP_TILE_SIZE

            rl.DrawRectangle(i32(tile_x), i32(tile_y), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.GREEN)
        }
    }
}
