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

    // for tile, index in astar_grid.tiles {
    //     row := tile.pos.y
    //     col := tile.pos.x

    //     tile_x := col * TILEMAP_TILE_SIZE
    //     tile_y := row * TILEMAP_TILE_SIZE

    //     // Draw path grid
    //     rl.DrawRectangle(i32(tile_x), i32(tile_y), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.RED)

    //     // Draw path text
    //     text := fmt.tprintf("%v", index)
    //     ctext := strings.clone_to_cstring(text)
    //     text_width := rl.MeasureText(ctext, 18)

    //     text_x := i32(tile_x) + 32 / 2 - text_width / 2
    //     text_y := i32(tile_y) + 32 / 2 - 18 / 2
    //     rl.DrawText(ctext, text_x, text_y, 18, rl.LIGHTGRAY)
    // }

    for enemy in active_enemies {
        enemy_tilemap_pos := get_grid_pos_from_world_pos(enemy.pos)
        player_tilmap_pos := get_grid_pos_from_world_pos(car.rb.position)

        path, _ := find_astar_path(astar_grid, enemy_tilemap_pos, player_tilmap_pos)

        for node in path.nodes {
            tile_x := node.tile.pos.x * TILEMAP_TILE_SIZE
            tile_y := node.tile.pos.y * TILEMAP_TILE_SIZE

            rl.DrawRectangle(i32(tile_x), i32(tile_y), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.GREEN)
        }

        // rl.DrawRectangle(i32(enemy_tilemap_pos.x * TILEMAP_TILE_SIZE), i32(enemy_tilemap_pos.y * TILEMAP_TILE_SIZE), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.BLUE)
        // rl.DrawRectangle(i32(player_tilmap_pos.x * TILEMAP_TILE_SIZE), i32(player_tilmap_pos.y * TILEMAP_TILE_SIZE), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.BLUE)
    }
}
