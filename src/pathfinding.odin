package fabrayodin

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

init_pathfinding :: proc(tilemap: Tilemap, allocator := context.allocator, loc := #caller_location) -> Flow_Field {
   //  astar_grid := init_astar_grid({0, 0}, {GRID_COLUMNS, GRID_ROWS}, allocator = allocator, loc = loc)
    flow_field := init_flow_field({0, 0}, {GRID_COLUMNS, GRID_ROWS})

    for layer in tilemap.layers {
        if !layer.is_collision { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }

            row := index / GRID_COLUMNS
            col := index % GRID_COLUMNS

            set_blocked_tile(&flow_field, {col, row})
        }
    }

    calculate_cost(flow_field, 50)
    calculate_flow(flow_field)

    return flow_field
}

// destroy_pathfinding :: proc(astar_grid: ^Astar_Grid, loc := #caller_location) {
//     destroy_astar_grid(astar_grid, loc)
// }

draw_pathfinding :: proc(flow_field: Flow_Field) {
    flow_grid := flow_field.nodes

    // Draw grid
    for col in 1..<GRID_COLUMNS {  
        x := f32(col) * GRID_TILE_SIZE
        rl.DrawLineEx({x, 0}, {x, f32(SCREEN_HEIGHT)}, 1, rl.LIGHTGRAY)
    }
    for row in 1..<GRID_ROWS {
        y := f32(row) * GRID_TILE_SIZE
        rl.DrawLineEx({0, y}, {f32(SCREEN_WIDTH), y}, 1, rl.LIGHTGRAY)
    }


    for node, i in flow_grid {     
        tile : [2]int = { i % GRID_COLUMNS * GRID_TILE_SIZE, i / GRID_COLUMNS * GRID_TILE_SIZE }

        // Draw Wall
        if !node.is_walkable {
            rl.DrawRectangle(i32(tile.x), i32(tile.y), GRID_TILE_SIZE, GRID_TILE_SIZE, rl.BLUE)
            continue
        } 

        // Draw Target
        if node.cost == 0 {
            rl.DrawRectangle(i32(tile.x), i32(tile.y), GRID_TILE_SIZE, GRID_TILE_SIZE, rl.LIME)
            continue
        } 

        // Draw Cost
        text := fmt.ctprintfln("%.1f ", node.cost)
        text_width := rl.MeasureText(text, 20)
        text_x := i32(tile.x) + GRID_TILE_SIZE / 2 - text_width / 2
        text_y := i32(tile.y) + GRID_TILE_SIZE / 2 - 10
        rl.DrawText(text, text_x, text_y, 20, rl.GRAY)
        
        // Draw Arrow
        line_length: f32 = 32;
        start_point : Vector2f = { f32(tile.x), f32(tile.y) } + { 32, 32 }
        end_point := Vector2f {
            start_point.x + node.direction.x * line_length,
            start_point.y + node.direction.y * line_length,
        };
        rl.DrawLineV(start_point, end_point, rl.RED);
    }
}

// draw_pathfinding :: proc(car: Car, astar_grid: Astar_Grid) {
//     for enemy in active_enemies {
//         enemy_tilemap_pos := get_grid_pos_from_world_pos(enemy.pos)
//         player_tilmap_pos := get_grid_pos_from_world_pos(car.rb.position)

//         path, _ := find_astar_path(astar_grid, enemy_tilemap_pos, player_tilmap_pos)

//         for node in path.nodes {
//             tile_x := node.tile.pos.x * GRID_TILE_SIZE
//             tile_y := node.tile.pos.y * GRID_TILE_SIZE

//             rl.DrawRectangle(i32(tile_x), i32(tile_y), GRID_TILE_SIZE, GRID_TILE_SIZE, rl.GREEN)
//         }
//     }
// }
